function Get-IsdfDeviceCert {
  param(
    [string[]] $IssuerContains = @("CN=OuttaTune","CN=CirriusTech")  # put your CA/issuer name fragments here
  )

  $now   = Get-Date
  $paths = @("Cert:\LocalMachine\My","Cert:\CurrentUser\My")

  foreach ($p in $paths) {
    $candidates =
      Get-ChildItem $p |
      Where-Object {
        $_.HasPrivateKey -and
        $_.NotBefore -le $now -and $_.NotAfter -ge $now
      } |
      Where-Object {
        # Require Client Authentication EKU (1.3.6.1.5.5.7.3.2)
        ($_.Extensions | Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension] } |
          ForEach-Object { $_.EnhancedKeyUsages } | ForEach-Object { $_.Value }) -contains "1.3.6.1.5.5.7.3.2"
      } |
      Where-Object {
        # Issuer contains any of the allowed fragments
        $iss = $_.Issuer
        $IssuerContains | Where-Object { $iss.IndexOf($_,[StringComparison]::OrdinalIgnoreCase) -ge 0 } | Select-Object -First 1
      } |
      Sort-Object NotBefore -Descending

    if ($candidates) { return $candidates[0] }
  }

  throw "No suitable device certificate found in LocalMachine\My or CurrentUser\My."
}

# Use it:
$cert = Get-IsdfDeviceCert
$uri  = "https://isdf-apim-01.azure-api.net/isdf/When_a_HTTP_request_is_received/paths/invoke"
$body = @{
  device = @{
    aadDeviceId = "d66f6a69-e764-4c42-a4b8-7f538123c517"
    hostname    = $env:COMPUTERNAME
    aadTenantId = "d980314b-cb2f-44e3-9ce7-06d7361ab382"
  }
  isdf = @{
    channel         = "ISDF:W365"
    ea2             = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("placeholder"))
    signalHash      = "a173d0f312118ca337c46ec75f16e8c7b221eacb12fbdf0b132840af2b2fc624"
    originTupleHash = "8cbc9714b66a200501bb6c162639ea68b1e203b7ed8a5cbcdc2f1ca36e06db2a"
    baselineVer     = 1
    timestampUtc    = (Get-Date).ToUniversalTime().ToString("o")
  }
} | ConvertTo-Json -Depth 5

Invoke-RestMethod -Method POST -Uri $uri -Certificate $cert -Body $body -ContentType 'application/json' -TimeoutSec 30
