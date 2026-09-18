import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const projectRoot = path.resolve(import.meta.dirname, '..', '..');
const mingyuRoot = path.resolve(projectRoot, '..', '..', 'githubsm', 'mingyu');
const entryPath = path.join(
  mingyuRoot,
  'packages',
  'core',
  'src',
  'divination',
  'algorithms',
  'meihua',
  'index.ts',
);
const outputPath = path.join(projectRoot, 'test_vectors', 'meihua', 'v1.json');
const { generateMeihua } = await import(pathToFileURL(entryPath).href);
const date = new Date('2025-01-01T08:00:00+08:00');

const cases = [
  { caseId: 'number-123', settings: { method: 'number', number: 123 } },
  { caseId: 'number-1', settings: { method: 'number', number: 1 } },
  { caseId: 'random-fixed', settings: { method: 'random', seed: '梅花-golden-甲' } },
];

const vectors = cases.map(({ caseId, settings }) => {
  const result = generateMeihua(date, settings);
  return {
    caseId,
    date: date.toISOString(),
    input: settings,
    expected: {
      upperTrigramIndex: result.calculation.upperTrigramIndex,
      lowerTrigramIndex: result.calculation.lowerTrigramIndex,
      movingYaoIndex: result.calculation.movingYaoIndex,
      original: result.originalName,
      inter: result.interName,
      changed: result.changedName,
      tiGua: result.tiGua,
      yongGua: result.yongGua,
      tiYongRaw: result.analysis.tiYongRaw,
      movingYaoCi: result.mainHexagram.movingYaoCi,
      randomSamples: result.meta?.random?.samples ?? [],
    },
  };
});

fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(
  outputPath,
  `${JSON.stringify({
    _meta: {
      source: 'mingyu 0.4.0 generateMeihua',
      algorithmVersion: 1,
      scope: ['number', 'random'],
    },
    vectors,
  }, null, 2)}\n`,
  'utf8',
);
console.log(`已导出 ${vectors.length} 组梅花易数向量：${outputPath}`);
