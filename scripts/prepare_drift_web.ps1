$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$workerSource = Join-Path $projectRoot 'tool\drift_worker.dart'
$workerOutput = Join-Path $projectRoot 'web\drift_worker.js'

dart compile js $workerSource -O4 -o $workerOutput
if ($LASTEXITCODE -ne 0) {
  throw "Drift worker build failed with exit code $LASTEXITCODE"
}

$sqliteWasm = Join-Path $projectRoot 'web\sqlite3.wasm'
if (-not (Test-Path $sqliteWasm)) {
  throw 'web\sqlite3.wasm is missing. Download the sqlite3.wasm asset matching the sqlite3 Dart package release.'
}

Write-Host 'drift-web-ready: web\drift_worker.js, web\sqlite3.wasm'
