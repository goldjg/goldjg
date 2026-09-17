#!/usr/bin/env python3

"""
MVP auth-flow shape collector.

Purpose:
    Capture enough metadata from an mvp.microsoft.com login to compare
    MSA vs Entra/work-school authentication flows WITHOUT producing a HAR
    or collecting tokens, cookies, passwords, auth codes, or response bodies.

Requirements:
    pip install playwright

Uses an existing Edge installation where possible.

Run:
    python mvp-auth-trace.py

A browser window will open. Log into https://mvp.microsoft.com normally.
Once the MVP site has completely loaded, return to the terminal and press Enter.

Output:
    mvp-auth-flow.json
"""

from playwright.sync_api import sync_playwright
from urllib.parse import urlparse, parse_qsl
import json
import re
import time


OUTPUT = "mvp-auth-flow.json"

INTERESTING_HOSTS = {
    "mvp.microsoft.com",
    "mavenapi-prod.microsoft.com",
    "login.microsoftonline.com",
}

# Values useful for comparing auth flows that are safe to retain.
SAFE_QUERY_VALUES = {
    "client_id",
    "response_type",
    "response_mode",
    "scope",
    "grant_type",
    "prompt",
    "code_challenge_method",
}

# Useful to know these parameters existed, but never retain their values.
REDACT_QUERY_VALUES = {
    "code",
    "state",
    "nonce",
    "code_challenge",
    "code_verifier",
    "client_secret",
    "client_assertion",
    "refresh_token",
    "access_token",
    "id_token",
    "login_hint",
    "domain_hint",
    "claims",
    "session_state",
}


GUID_RE = re.compile(
    r"\b[0-9a-fA-F]{8}-"
    r"[0-9a-fA-F]{4}-"
    r"[0-9a-fA-F]{4}-"
    r"[0-9a-fA-F]{4}-"
    r"[0-9a-fA-F]{12}\b"
)

EMAIL_RE = re.compile(
    r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"
)


def sanitize_path(path):
    # Keep known application/client IDs because they're exactly what we
    # want to compare. Redact other GUID-shaped personal/resource IDs.
    known_ids = {
        "6dabb447-da84-4b4c-b68f-99f5215b2ca7",
        "e83f495c-dfa2-48e2-b1d9-3680b16e74e4",
    }

    path = EMAIL_RE.sub("<EMAIL>", path)

    def replace_guid(match):
        value = match.group(0).lower()
        if value in known_ids:
            return value
        return "<GUID>"

    return GUID_RE.sub(replace_guid, path)


def safe_redirect_uri(value):
    try:
        p = urlparse(value)
        return f"{p.scheme}://{p.netloc}{p.path}"
    except Exception:
        return "<redacted>"


def sanitize_url(url):
    parsed = urlparse(url)

    result = {
        "scheme": parsed.scheme,
        "host": parsed.hostname,
        "path": sanitize_path(parsed.path),
    }

    params = {}

    for key, value in parse_qsl(parsed.query, keep_blank_values=True):
        k = key.lower()

        if k in SAFE_QUERY_VALUES:
            params[key] = value

        elif k == "redirect_uri":
            params[key] = safe_redirect_uri(value)

        elif k in REDACT_QUERY_VALUES:
            params[key] = "<present-redacted>"

        else:
            # Parameter names themselves can be useful when comparing flows.
            params[key] = "<redacted>"

    if params:
        result["query"] = params

    return result


def sanitize_post_data(request):
    raw = request.post_data

    if not raw:
        return None

    content_type = request.headers.get("content-type", "")

    # OAuth token requests are normally URL encoded.
    if "application/x-www-form-urlencoded" in content_type:
        result = {}

        for key, value in parse_qsl(raw, keep_blank_values=True):
            k = key.lower()

            if k in {"client_id", "grant_type", "scope"}:
                result[key] = value

            elif k == "redirect_uri":
                result[key] = safe_redirect_uri(value)

            else:
                # Important: record the field NAME only.
                result[key] = "<present-redacted>"

        return result

    # Do not inspect arbitrary POST bodies.
    return {
        "_body": "<not-collected>",
        "_content_type": content_type,
    }


def interesting(url):
    try:
        host = urlparse(url).hostname or ""

        if host in INTERESTING_HOSTS:
            return True

        # Keep related Microsoft auth hosts visible without collecting
        # everything the page loads.
        if host.endswith(".microsoftonline.com"):
            return True

        return False

    except Exception:
        return False


events = []


def record_request(request):
    if not interesting(request.url):
        return

    event = {
        "time": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "type": "request",
        "method": request.method,
        "url": sanitize_url(request.url),
        "resource_type": request.resource_type,
    }

    post_shape = sanitize_post_data(request)

    if post_shape:
        event["post_fields"] = post_shape

    # Deliberately DO NOT collect request.headers.
    events.append(event)


def record_response(response):
    if not interesting(response.url):
        return

    events.append({
        "time": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "type": "response",
        "status": response.status,
        "url": sanitize_url(response.url),

        # Deliberately DO NOT read response bodies or headers.
    })


with sync_playwright() as p:
    try:
        browser = p.chromium.launch(
            channel="msedge",
            headless=False,
        )
    except Exception:
        print("Could not launch Edge; trying installed Chrome...")
        browser = p.chromium.launch(
            channel="chrome",
            headless=False,
        )

    context = browser.new_context()

    page = context.new_page()

    page.on("request", record_request)
    page.on("response", record_response)

    print()
    print("Opening Microsoft MVP site...")
    print()
    print("Log in normally using your MVP-associated Microsoft account.")
    print("Wait until the MVP site has completely loaded.")
    print()
    print("This script does NOT collect:")
    print("  - passwords")
    print("  - cookies")
    print("  - Authorization headers")
    print("  - access/id/refresh tokens")
    print("  - auth codes")
    print("  - response bodies")
    print("  - email addresses")
    print()

    page.goto(
        "https://mvp.microsoft.com/",
        wait_until="domcontentloaded",
    )

    input(
        "\nWhen login is complete and the MVP portal has loaded, "
        "press Enter here..."
    )

    browser.close()


# De-duplicate obvious request/response noise while preserving order.
cleaned = []
seen = set()

for event in events:
    fingerprint = json.dumps(event, sort_keys=True)

    if fingerprint not in seen:
        seen.add(fingerprint)
        cleaned.append(event)


with open(OUTPUT, "w", encoding="utf-8") as f:
    json.dump(
        {
            "description": "Sanitized Microsoft MVP authentication flow",
            "events": cleaned,
        },
        f,
        indent=2,
    )


print()
print(f"Sanitized trace written to: {OUTPUT}")
print()
print("Please inspect it yourself before sharing it.")
print("It should contain protocol metadata only, not credentials or tokens.")