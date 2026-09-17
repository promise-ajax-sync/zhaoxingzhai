import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const projectRoot = path.resolve(import.meta.dirname, '..', '..');
const mingyuRoot = path.resolve(
  process.argv[2] || path.resolve(projectRoot, '..', '..', 'githubsm', 'mingyu'),
);
const dataPath = path.join(
  mingyuRoot,
  'packages',
  'core',
  'src',
  'divination',
  'ssgw-data',
  'index.ts',
);
const randomPath = path.join(
  mingyuRoot,
  'packages',
  'core',
  'src',
  'shared',
  'random.ts',
);
const packagePath = path.join(mingyuRoot, 'package.json');
const outputPath = path.join(projectRoot, 'test_vectors', 'ssgw', 'v1.json');
const { SSGW_SIGNS } = await import(pathToFileURL(dataPath).href);
const { createRandomContext, randomInt } = await import(pathToFileURL(randomPath).href);
const mingyuPackage = JSON.parse(fs.readFileSync(packagePath, 'utf8'));

const seeds = ['灵签-golden-甲', '灵签-golden-乙', '灵签-golden-丙'];
const cases = seeds.map((seed, index) => {
  const context = createRandomContext({ seed });
  const selectedIndex = randomInt(SSGW_SIGNS.length, context.random);
  const result = SSGW_SIGNS[selectedIndex];
  return {
    caseId: `seed-${index + 1}`,
    seed,
    expected: {
      number: result.id,
      title: result.title,
      poem: result.qianwen,
    },
  };
});

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(
  outputPath,
  `${JSON.stringify({
    source: 'mingyu ssgw-data + shared/random (equivalent to drawRandomSign selection)',
    mingyuVersion: mingyuPackage.version,
    algorithmVersion: 1,
    randomAlgorithmId: 'fnv1a32-mulberry32',
    randomAlgorithmVersion: 2,
    cases,
  }, null, 2)}\n`,
  'utf8',
);
console.log(`已写入 ${cases.length} 组三山国王灵签向量：${outputPath}`);
