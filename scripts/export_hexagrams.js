// 兼容旧命令；完整数据导出逻辑位于 ESM 脚本中。
void import('./export_hexagrams.mjs').catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
