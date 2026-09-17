#!/usr/bin/env python3

"""
Microsoft MVP auth + JS archaeology collector.

Captures:
  - Sanitised auth/API request metadata
  - JavaScript chunks loaded by mvp.microsoft.com
  - Interesting strings/config from those chunks

Does NOT collect:
  - passwords
  - cookies
  - Authorization headers
  - access/id/refresh tokens
  - auth codes
  - credential POST bodies
  - API response bodies

Output:
  mvp-trace/
    network.json
    findings.json
    chunks/
      <downloaded JS files>

Usage:
    py -m pip install playwright
    py -m playwright install chromium
    py mvp-spelunk.py
"""

from playwright.sync_api import sync_playwright
from urllib.parse import urlparse, parse_qsl
from pathlib import Path
import hashlib
import json
import re
import time


OUTDIR = Path("mvp-trace")
CHUNKDIR = OUTDIR / "chunks"

OUTDIR.mkdir(exist_ok=True)
CHUNKDIR.mkdir(exist_ok=True)


# ---------------------------------------------------------------------------
# Things we already know and want to find again.
# ---------------------------------------------------------------------------

KNOWN_IDS = {
    "maven_resource": "6dabb447-da84-4b4c-b68f-99f5215b2ca7",
    "mvp_web_client": "e83f495c-dfa2-48e2-b1d9-3680b16e74e4",
}

SEARCH_TERMS = [
    # Known resource/client
    "6dabb447-da84-4b4c-b68f-99f5215b2ca7",
    "e83f495c-dfa2-48e2-b1d9-3680b16e74e4",

    # Maven
    "mavenapi",
    "mavenapi-prod.microsoft.com",
    "User.All",
    "UserStatus",

    # MSAL/auth behaviour
    "PublicClientApplication",
    "ConfidentialClientApplication",
    "acquireTokenSilent",
    "acquireTokenPopup",
    "acquireTokenRedirect",
    "loginPopup",
    "loginRedirect",
    "ssoSilent",
    "handleRedirectPromise",
    "getAllAccounts",
    "getActiveAccount",
    "setActiveAccount",

    # Config-ish
    "clientId",
    "authority",
    "redirectUri",
    "postLogoutRedirectUri",
    "knownAuthorities",
    "scopes",
    "extraScopesToConsent",
    "prompt",
    "domainHint",
    "loginHint",

    # Microsoft auth endpoints
    "login.microsoftonline.com",
    "oauth2/v2.0/authorize",
    "oauth2/v2.0/token",
]


INTERESTING_NETWORK_HOSTS = {
    "mvp.microsoft.com",
    "mavenapi-prod.microsoft.com",
    "login.microsoftonline.com",
}


SAFE_QUERY_VALUES = {
    "client_id",
    "response_type",
    "response_mode",
    "scope",
    "grant_type",
    "prompt",
    "code_challenge_method",
}

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


EMAIL_RE = re.compile(
    r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b"
)

GUID_RE = re.compile(
    r"\b[0-9a-fA-F]{8}-"
    r"[0-9a-fA-F]{4}-"
    r"[0-9a-fA-F]{4}-"
    r"[0-9a-fA-F]{4}-"
    r"[0-9a-fA-F]{12}\b"
)

URL_RE = re.compile(
    r'https?://[A-Za-z0-9._~:/?#\[\]@!$&\'()*+,;=%-]+'
)

SCOPE_RE = re.compile(
    r'(?:api://[0-9a-fA-F-]{36}/[A-Za-z0-9._/-]+)'
)


network_events = []
chunk_records = []
findings = []


# ---------------------------------------------------------------------------
# Sanitisation helpers
# ---------------------------------------------------------------------------

def sanitize_path(path):
    path = EMAIL_RE.sub("<EMAIL>", path)

    known = {v.lower() for v in KNOWN_IDS.values()}

    def replace_guid(match):
        value = match.group(0)

        if value.lower() in known:
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
            params[key] = "<redacted>"

    if params:
        result["query"] = params

    return result


def interesting_network_url(url):
    try:
        host = (urlparse(url).hostname or "").lower()

        if host in INTERESTING_NETWORK_HOSTS:
            return True

        if host.endswith(".microsoftonline.com"):
            return True

        if host.endswith(".msauth.net"):
            return True

        if host.endswith(".msftauth.net"):
            return True

        return False

    except Exception:
        return False


def is_mvp_javascript(response):
    try:
        parsed = urlparse(response.url)
        host = (parsed.hostname or "").lower()

        if host != "mvp.microsoft.com":
            return False

        content_type = response.headers.get("content-type", "").lower()

        path = parsed.path.lower()

        return (
            "javascript" in content_type
            or path.endswith(".js")
            or ".js?" in response.url.lower()
        )

    except Exception:
        return False


# ---------------------------------------------------------------------------
# Network collection
# ---------------------------------------------------------------------------

def record_request(request):
    if not interesting_network_url(request.url):
        return

    network_events.append({
        "time": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "type": "request",
        "method": request.method,
        "resource_type": request.resource_type,
        "url": sanitize_url(request.url),
    })


def record_response(response):
    if interesting_network_url(response.url):
        network_events.append({
            "time": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "type": "response",
            "status": response.status,
            "url": sanitize_url(response.url),
        })

    if is_mvp_javascript(response):
        capture_javascript(response)


# ---------------------------------------------------------------------------
# JavaScript collection
# ---------------------------------------------------------------------------

def safe_filename(url, body):
    parsed = urlparse(url)

    basename = Path(parsed.path).name or "chunk.js"

    if not basename.endswith(".js"):
        basename += ".js"

    digest = hashlib.sha256(body.encode("utf-8", errors="ignore")).hexdigest()[:12]

    basename = re.sub(r"[^A-Za-z0-9._-]", "_", basename)

    return f"{digest}-{basename}"


def capture_javascript(response):
    try:
        body = response.text()

    except Exception as exc:
        chunk_records.append({
            "url": response.url,
            "status": response.status,
            "error": str(exc),
        })
        return

    if not body.strip():
        return

    filename = safe_filename(response.url, body)
    path = CHUNKDIR / filename

    if not path.exists():
        path.write_text(body, encoding="utf-8", errors="ignore")

    record = {
        "url": response.url,
        "file": str(path),
        "bytes": len(body.encode("utf-8", errors="ignore")),
        "sha256": hashlib.sha256(
            body.encode("utf-8", errors="ignore")
        ).hexdigest(),
    }

    chunk_records.append(record)

    parse_javascript(filename, response.url, body)


# ---------------------------------------------------------------------------
# JS archaeology
# ---------------------------------------------------------------------------

def surrounding_text(text, index, radius=250):
    start = max(0, index - radius)
    end = min(len(text), index + radius)

    snippet = text[start:end]

    # Avoid accidentally preserving email-ish data.
    snippet = EMAIL_RE.sub("<EMAIL>", snippet)

    return snippet


def add_finding(kind, value, filename, url, snippet=None):
    item = {
        "type": kind,
        "value": value,
        "file": filename,
        "source_url": url,
    }

    if snippet:
        item["context"] = snippet

    findings.append(item)


def parse_javascript(filename, url, text):

    # Search known keywords/config items.
    for term in SEARCH_TERMS:
        start = 0

        while True:
            idx = text.find(term, start)

            if idx < 0:
                break

            add_finding(
                "term",
                term,
                filename,
                url,
                surrounding_text(text, idx)
            )

            start = idx + len(term)

    # Extract UUIDs.
    for match in GUID_RE.finditer(text):
        value = match.group(0)

        add_finding(
            "guid",
            value,
            filename,
            url,
            surrounding_text(text, match.start())
        )

    # Extract explicit API scopes.
    for match in SCOPE_RE.finditer(text):
        value = match.group(0)

        add_finding(
            "scope",
            value,
            filename,
            url,
            surrounding_text(text, match.start())
        )

    # Extract interesting URLs.
    for match in URL_RE.finditer(text):
        value = match.group(0)

        if any(x in value.lower() for x in [
            "microsoft",
            "maven",
            "oauth",
            "login",
        ]):
            add_finding(
                "url",
                value,
                filename,
                url,
                surrounding_text(text, match.start())
            )


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

print()
print("Microsoft MVP auth + JS spelunker")
print("----------------------------------")
print()
print("This collector stores:")
print("  * sanitised auth/API request metadata")
print("  * JavaScript loaded from mvp.microsoft.com")
print("  * parsed auth/config findings from those chunks")
print()
print("It does NOT store cookies, auth headers, tokens, passwords,")
print("credential POST bodies, auth codes, or API response bodies.")
print()


with sync_playwright() as p:

    print("Launching Playwright Chromium...", flush=True)

    browser = p.chromium.launch(
        headless=False,
    )

    context = browser.new_context()

    # Context-level listeners catch popups/new tabs too.
    context.on("request", record_request)
    context.on("response", record_response)

    page = context.new_page()

    print("Opening https://mvp.microsoft.com ...", flush=True)

    page.goto(
        "https://mvp.microsoft.com/",
        wait_until="domcontentloaded",
        timeout=60000,
    )

    print()
    print("Now perform the MVP-specific login flow.")
    print()
    print("Do NOT just use the generic Microsoft site sign-in unless")
    print("you specifically want to compare that flow as well.")
    print()
    print("Once the MVP portal is fully loaded, return here.")
    print()

    input("Press Enter when finished capturing... ")

    browser.close()


# ---------------------------------------------------------------------------
# De-dupe output
# ---------------------------------------------------------------------------

def dedupe(items):
    result = []
    seen = set()

    for item in items:
        key = json.dumps(item, sort_keys=True)

        if key in seen:
            continue

        seen.add(key)
        result.append(item)

    return result


network_events = dedupe(network_events)
findings = dedupe(findings)


# ---------------------------------------------------------------------------
# Write results
# ---------------------------------------------------------------------------

(OUTDIR / "network.json").write_text(
    json.dumps(
        {
            "description": "Sanitised Microsoft MVP authentication/network trace",
            "events": network_events,
        },
        indent=2,
    ),
    encoding="utf-8",
)


(OUTDIR / "chunks.json").write_text(
    json.dumps(
        {
            "description": "JavaScript chunks captured from mvp.microsoft.com",
            "chunks": chunk_records,
        },
        indent=2,
    ),
    encoding="utf-8",
)


(OUTDIR / "findings.json").write_text(
    json.dumps(
        {
            "description": "Interesting auth/API strings found in MVP JavaScript",
            "known_ids": KNOWN_IDS,
            "findings": findings,
        },
        indent=2,
    ),
    encoding="utf-8",
)


print()
print("Capture complete.")
print()
print(f"Network trace : {OUTDIR / 'network.json'}")
print(f"Chunk index   : {OUTDIR / 'chunks.json'}")
print(f"Parsed results: {OUTDIR / 'findings.json'}")
print(f"Raw JS chunks : {CHUNKDIR}")
print()
print(f"Found {len(chunk_records)} JavaScript responses")
print(f"Found {len(findings)} interesting JS artefacts")
print()
print("Inspect findings.json first — that should contain the useful archaeology.")