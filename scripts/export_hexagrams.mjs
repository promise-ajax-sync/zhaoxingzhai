import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const projectRoot = path.resolve(import.meta.dirname, '..');
const defaultMingyuRoot = path.resolve(projectRoot, '..', '..', 'githubsm', 'mingyu');
const mingyuRoot = path.resolve(process.argv[2] || defaultMingyuRoot);
const sourcePath = path.join(
  mingyuRoot,
  'packages',
  'core',
  'src',
  'divination',
  'hexagram-data.ts',
);
const packagePath = path.join(mingyuRoot, 'package.json');
const outputPath = path.join(projectRoot, 'assets', 'data', 'hexagrams.json');

const { hexagramsData } = await import(pathToFileURL(sourcePath).href);
if (!Array.isArray(hexagramsData) || hexagramsData.length !== 64) {
  throw new Error(`六十四卦数量异常：${hexagramsData?.length}`);
}

const ids = new Set();
const binaries = new Set();
for (const hexagram of hexagramsData) {
  if (ids.has(hexagram.id)) throw new Error(`重复卦序：${hexagram.id}`);
  if (!/^[01]{6}$/.test(hexagram.binarySymbol)) {
    throw new Error(`${hexagram.name} 的二进制卦象无效：${hexagram.binarySymbol}`);
  }
  if (binaries.has(hexagram.binarySymbol)) {
    throw new Error(`重复二进制卦象：${hexagram.binarySymbol}`);
  }
  if (!Array.isArray(hexagram.yaoCi) || hexagram.yaoCi.length !== 6) {
    throw new Error(`${hexagram.name} 的爻辞数量异常：${hexagram.yaoCi?.length}`);
  }
  ids.add(hexagram.id);
  binaries.add(hexagram.binarySymbol);
}

const mingyuPackage = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
const hexagrams = hexagramsData.map(({ binarySymbol, yaoCi, yongCi, ...rest }) => ({
  ...rest,
  binary: binarySymbol,
  yaoCi,
  ...(yongCi ? { yongCi } : {}),
}));

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(
  outputPath,
  `${JSON.stringify({
    _meta: {
      source: 'mingyu/packages/core/src/divination/hexagram-data.ts#hexagramsData',
    sourceVersion: mingyuPackage.version,
      binaryOrder: 'upper trigram then lower trigram; each trigram is bottom-to-top',
      yaoCiOrder: 'bottom-to-top (初爻到上爻)',
    },
    hexagrams,
  }, null, 2)}\n`,
  'utf8',
);

console.log(`已导出 ${hexagrams.length} 个完整卦象：${outputPath}`);
