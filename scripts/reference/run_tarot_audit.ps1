param(
  [string]$MingyuRoot = 'E:\newProject\githubsm\mingyu'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$loader = Join-Path $PSScriptRoot 'ts_extension_loader.mjs'
$exporter = Join-Path $PSScriptRoot 'export_tarot_mingyu.mjs'

Push-Location $projectRoot
try {
  node `
    --experimental-strip-types `
    --experimental-transform-types `
    --experimental-loader $loader `
    $exporter `
    $MingyuRoot
  if ($LASTEXITCODE -ne 0) {
    throw "mingyu 塔罗向量导出失败，退出码 $LASTEXITCODE"
  }

  flutter test test/core/engine/tarot_vector_test.dart
  if ($LASTEXITCODE -ne 0) {
    throw "Flutter 塔罗向量对比失败，退出码 $LASTEXITCODE"
  }
} finally {
  Pop-Location
}
