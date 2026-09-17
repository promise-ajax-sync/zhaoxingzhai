import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';

function readArgs(argv) {
  const result = {};
  for (let index = 0; index < argv.length; index += 2) {
    const key = argv[index];
    const value = argv[index + 1];
    if (!key?.startsWith('--') || value === undefined) throw new Error(`参数格式错误：${key ?? ''}`);
    result[key.slice(2)] = value;
  }
  return result;
}

const args = readArgs(process.argv.slice(2));
for (const required of ['vectors', 'v023', 'v040', 'dart', 'output']) {
  if (!args[required]) throw new Error(`缺少 --${required}`);
}

const load = async (path) => JSON.parse(await readFile(resolve(path), 'utf8'));
const [fixture, v023, v040, dart] = await Promise.all([
  load(args.vectors), load(args.v023), load(args.v040), load(args.dart),
]);
const byId = (document) => new Map(document.results.map((entry) => [entry.id, entry.result]));
const sources = [
  ['mingyu-core-0.2.3', byId(v023)],
  ['mingyu-core-0.4.0', byId(v040)],
  ['zhaoxingzhai-dart', byId(dart)],
];
const rows = [];
let regressions = 0;

for (const vector of fixture.vectors) {
  const results = sources.map(([, map]) => map.get(vector.id));
  if (results.some((result) => !result)) throw new Error(`向量 ${vector.id} 在某个参考结果中缺失`);
  const fields = new Set([...Object.keys(vector.expected), ...results.flatMap(Object.keys)]);
  for (const field of fields) {
    const values = results.map((result) => result[field]);
    const expected = vector.expected[field];
    const referencesAgree = Object.is(values[0], values[1]);
    const dartMatchesCurrent = Object.is(values[1], values[2]);
    const expectedMatches = expected === undefined || Object.is(expected, values[2]);
    const status = dartMatchesCurrent && expectedMatches
      ? (referencesAgree ? 'MATCH' : 'VERSION_DIFFERENCE')
      : 'REGRESSION';
    if (status === 'REGRESSION') regressions += 1;
    if (status !== 'MATCH' || Object.prototype.hasOwnProperty.call(vector.expected, field)) {
      rows.push({ id: vector.id, field, expected, values, status });
    }
  }
}

const cell = (value) => value === undefined ? '' : String(value).replaceAll('|', '\\|');
const lines = [
  '# 小六壬三方算法对照', '',
  `- 向量版本：${fixture.algorithmVersion}`,
  `- 向量数量：${fixture.vectors.length}`,
  `- 回归字段数：${regressions}`,
  `- 生成时间：${new Date().toISOString()}`, '',
  '| 用例 | 字段 | 预期 | mingyu 0.2.3 | mingyu 0.4.0 | Flutter | 状态 |',
  '|---|---|---|---|---|---|---|',
  ...rows.map((row) => `| ${row.id} | ${row.field} | ${cell(row.expected)} | ${cell(row.values[0])} | ${cell(row.values[1])} | ${cell(row.values[2])} | ${row.status} |`),
  '',
  regressions === 0 ? '结论：未发现 Flutter 相对当前 mingyu 0.4.0 的未解释偏差。' : '结论：存在回归，不能更新算法基准。',
  '',
];

const outputPath = resolve(args.output);
await mkdir(dirname(outputPath), { recursive: true });
await writeFile(outputPath, `${lines.join('\n')}\n`);
console.log(`已生成差异报告：${outputPath}`);
if (regressions > 0) process.exitCode = 1;
