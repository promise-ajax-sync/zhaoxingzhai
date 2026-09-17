param(
  [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'

function Invoke-FoundationCheck {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [Parameter(Mandatory = $true)]
    [scriptblock]$Command
  )

  Write-Host "`n==> $Name"
  & $Command
  if ($LASTEXITCODE -ne 0) {
    throw "$Name failed with exit code $LASTEXITCODE"
  }
}

Invoke-FoundationCheck 'Flutter environment' { flutter --version }
Invoke-FoundationCheck 'Static analysis' { flutter analyze }
Invoke-FoundationCheck 'Unit and widget tests' { flutter test }

if (-not $SkipBuild) {
  Invoke-FoundationCheck 'Web release build' { flutter build web --release }
  Invoke-FoundationCheck 'Android debug build' { flutter build apk --debug }
}

Write-Host "`nFoundation verification passed."
