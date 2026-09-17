param(
  [string]$MingyuRepository = "../../../../githubsm/mingyu"
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$mingyuRoot = (Resolve-Path (Join-Path $PSScriptRoot $MingyuRepository)).Path
$workRoot = Join-Path $env:TEMP 'zhaoxingzhai-xiaoliuren-reference'
$v023Root = Join-Path $workRoot 'mingyu-core-0.2.3'
$v040Root = Join-Path $workRoot 'mingyu-core-0.4.0'
$vectors = Join-Path $projectRoot 'test_vectors/xiaoliuren/v1.json'
$resultsRoot = Join-Path $projectRoot 'build/reference/xiaoliuren'
$auditOutput = Join-Path $projectRoot 'docs/algorithm-audits/xiaoliuren-v1.md'

New-Item -ItemType Directory -Force -Path $workRoot, $resultsRoot | Out-Null

function Ensure-ReferenceWorktree([string]$Path, [string]$Ref) {
  if (-not (Test-Path $Path)) {
    git -C $mingyuRoot worktree add --detach $Path $Ref
    if ($LASTEXITCODE -ne 0) { throw "创建参考 worktree 失败：$Ref" }
  }
  elseif (-not (Test-Path (Join-Path $Path '.git'))) {
    throw "临时参考目录已存在但不是 Git worktree：$Path"
  }
  # 只安装核心算法包，避免为 Web、MCP、Android 等无关工作区下载依赖。
  pnpm -C $Path --filter mingyu-core... install --frozen-lockfile
  if ($LASTEXITCODE -ne 0) { throw "安装参考版本依赖失败：$Ref" }
  pnpm -C $Path --filter mingyu-core build
  if ($LASTEXITCODE -ne 0) { throw "构建 mingyu-core 失败：$Ref" }
}

Ensure-ReferenceWorktree $v023Root 'mingyu-core-v0.2.3'
Ensure-ReferenceWorktree $v040Root 'v0.4.0'

node (Join-Path $projectRoot 'scripts/reference/export_xiaoliuren_mingyu.mjs') `
  --module (Join-Path $v023Root 'packages/core/dist/divination/algorithms/xiaoliuren.js') `
  --vectors $vectors `
  --output (Join-Path $resultsRoot 'mingyu-core-0.2.3.json') `
  --reference 'mingyu-core-0.2.3'
if ($LASTEXITCODE -ne 0) { throw '导出 mingyu-core 0.2.3 结果失败' }

node (Join-Path $projectRoot 'scripts/reference/export_xiaoliuren_mingyu.mjs') `
  --module (Join-Path $v040Root 'packages/core/dist/divination/algorithms/xiaoliuren.js') `
  --vectors $vectors `
  --output (Join-Path $resultsRoot 'mingyu-core-0.4.0.json') `
  --reference 'mingyu-core-0.4.0'
if ($LASTEXITCODE -ne 0) { throw '导出 mingyu-core 0.4.0 结果失败' }

dart run (Join-Path $projectRoot 'tool/export_xiaoliuren_vectors.dart') `
  --vectors $vectors `
  --output (Join-Path $resultsRoot 'zhaoxingzhai-dart.json')
if ($LASTEXITCODE -ne 0) { throw '导出 Dart 结果失败' }

node (Join-Path $projectRoot 'scripts/reference/compare_xiaoliuren_vectors.mjs') `
  --vectors $vectors `
  --v023 (Join-Path $resultsRoot 'mingyu-core-0.2.3.json') `
  --v040 (Join-Path $resultsRoot 'mingyu-core-0.4.0.json') `
  --dart (Join-Path $resultsRoot 'zhaoxingzhai-dart.json') `
  --output $auditOutput
if ($LASTEXITCODE -ne 0) { throw '小六壬三方比较发现回归或执行失败' }

Write-Output "小六壬对照完成：$auditOutput"
