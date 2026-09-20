$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot

Push-Location $projectRoot
try {
    flutter run -d chrome `
        --web-hostname=127.0.0.1 `
        --web-port=5173 `
        --dart-define=AI_BACKEND_URL=http://127.0.0.1:8000
}
finally {
    Pop-Location
}
