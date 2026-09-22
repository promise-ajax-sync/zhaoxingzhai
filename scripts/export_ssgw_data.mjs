import fs from 'node:fs';
import { register } from 'node:module';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const projectRoot = path.resolve(import.meta.dirname, '..');
const defaultMingyuRoot = path.resolve(projectRoot, '..', '..', 'githubsm', 'mingyu');
const mingyuRoot = path.resolve(process.argv[2] || defaultMingyuRoot);
const entryPath = path.join(
  mingyuRoot,
  'packages',
  'core',
  'src',
  'divination',
  'ssgw-data',
  'index.ts',
);
const packagePath = path.join(mingyuRoot, 'package.json');
const outputPath = path.join(projectRoot, 'assets', 'data', 'ssgw.json');

if (!fs.existsSync(entryPath)) {
  throw new Error(`找不到三山国王灵签数据源：${entryPath}`);
}
register('./reference/ts_extension_loader.mjs', import.meta.url);
const { SSGW_SIGNS } = await import(pathToFileURL(entryPath).href);
if (!Array.isArray(SSGW_SIGNS) || SSGW_SIGNS.length !== 92) {
  throw new Error(`三山国王灵签数量异常：${SSGW_SIGNS?.length}`);
}

const mingyuPackage = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(
  outputPath,
  `${JSON.stringify({
    _meta: {
      source: 'mingyu/packages/core/src/divination/ssgw-data/index.ts#SSGW_SIGNS',
      sourceData: 'ssgw-data/signs-full.ts + enrichSsgwSign',
      sourceVersion: mingyuPackage.version,
    },
    signs: SSGW_SIGNS,
  }, null, 2)}\n`,
  'utf8',
);

console.log(`已导出 ${SSGW_SIGNS.length} 支三山国王灵签：${outputPath}`);
