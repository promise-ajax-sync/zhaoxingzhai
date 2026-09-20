import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const projectRoot = path.resolve(import.meta.dirname, '..', '..');
const defaultMingyuRoot = path.resolve(projectRoot, '..', '..', 'githubsm', 'mingyu');
const mingyuRoot = path.resolve(process.argv[2] || defaultMingyuRoot);
const sourcePath = path.join(
  mingyuRoot,
  'packages',
  'core',
  'src',
  'divination',
  'tarot.ts',
);
const packagePath = path.join(mingyuRoot, 'package.json');
const outputPath = path.join(projectRoot, 'test_vectors', 'tarot', 'v1.json');

if (!fs.existsSync(sourcePath)) {
  throw new Error(`找不到 mingyu 塔罗入口：${sourcePath}`);
}

const { drawSpreadCards } = await import(pathToFileURL(sourcePath).href);
const mingyuPackage = JSON.parse(fs.readFileSync(packagePath, 'utf8'));

const inputs = [
  { caseId: 'single-fixed', spreadType: 'single', seed: '塔罗-golden-单牌' },
  { caseId: 'three-fixed', spreadType: 'three', seed: '塔罗-golden-三牌' },
  { caseId: 'celtic-fixed', spreadType: 'celtic', seed: '塔罗-golden-凯尔特' },
];

const cases = inputs.map((input) => {
  const result = drawSpreadCards(input.spreadType, { seed: input.seed });
  return {
    ...input,
    expected: result.cards.map((item) => ({
      cardId: item.card.number,
      name: item.card.name,
      position: item.position,
      orientation: item.isReversed ? '逆位' : '正位',
    })),
  };
});

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(
  outputPath,
  `${JSON.stringify({
    source: 'mingyu/packages/core/src/divination/tarot.ts#drawSpreadCards',
    sourceVersion: mingyuPackage.version,
    algorithmVersion: 1,
    randomAlgorithmId: 'fnv1a32-mulberry32',
    randomAlgorithmVersion: 2,
    cases,
  }, null, 2)}\n`,
  'utf8',
);

console.log(`已写入 ${cases.length} 组 mingyu 塔罗向量：${outputPath}`);
