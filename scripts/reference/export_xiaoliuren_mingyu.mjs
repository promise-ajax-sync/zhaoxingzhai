import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

function readArgs(argv) {
  const result = {};
  for (let index = 0; index < argv.length; index += 2) {
    const key = argv[index];
    const value = argv[index + 1];
    if (!key?.startsWith('--') || value === undefined) {
      throw new Error(`参数格式错误：${key ?? ''}`);
    }
    result[key.slice(2)] = value;
  }
  return result;
}

function normalize(result) {
  return {
    lunarMonth: result.lunarMonth,
    lunarDay: result.lunarDay,
    isLeapMonth: result.isLeapMonth,
    hourLabel: result.hourLabel,
    hourNumber: result.calculation.hourNumber,
    monthPalace: result.sequence.month.name,
    dayPalace: result.sequence.day.name,
    hourPalace: result.sequence.hour.name,
    monthPalaceIndex: result.calculation.monthPalaceIndex,
    dayPalaceIndex: result.calculation.dayPalaceIndex,
    hourPalaceIndex: result.calculation.hourPalaceIndex,
    dayBoundary: result.calculation.dayBoundary,
    leapMonthRule: result.calculation.leapMonthRule,
  };
}

const args = readArgs(process.argv.slice(2));
for (const required of ['module', 'vectors', 'output', 'reference']) {
  if (!args[required]) throw new Error(`缺少 --${required}`);
}

const modulePath = resolve(args.module);
const fixturePath = resolve(args.vectors);
const outputPath = resolve(args.output);
const module = await import(pathToFileURL(modulePath).href);
if (typeof module.generateXiaoliuren !== 'function') {
  throw new Error(`${modulePath} 未导出 generateXiaoliuren`);
}

const fixture = JSON.parse(await readFile(fixturePath, 'utf8'));
const results = fixture.vectors.map((vector) => ({
  id: vector.id,
  result: normalize(module.generateXiaoliuren({
    customDate: new Date(vector.input.dateTime),
    rule: vector.input.rule,
  })),
}));

await mkdir(dirname(outputPath), { recursive: true });
await writeFile(outputPath, `${JSON.stringify({
  schemaVersion: 1,
  algorithmId: fixture.algorithmId,
  reference: args.reference,
  generatedAt: new Date().toISOString(),
  results,
}, null, 2)}\n`);
console.log(`已导出 ${results.length} 条 ${args.reference} 小六壬向量：${outputPath}`);
