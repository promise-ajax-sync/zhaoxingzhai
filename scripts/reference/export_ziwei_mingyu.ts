import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const projectRoot = path.resolve(import.meta.dirname, '..', '..');
const mingyuRoot = path.resolve(process.argv[2] || path.resolve(projectRoot, '..', '..', 'githubsm', 'mingyu'));
const runtimePath = path.join(mingyuRoot, 'packages', 'core', 'src', 'ziwei', 'runtime.ts');
const { buildZiweiChartInput, calculateZiweiChart } = await import(pathToFileURL(runtimePath).href);

const cases = [
  { id: 'solar-male-noon', name: '公历男性午时', gender: 'male', dateType: 'solar', year: 1990, month: 5, day: 17, timeIndex: 7, isLeapMonth: false },
  { id: 'solar-female-zi', name: '公历女性子时', gender: 'female', dateType: 'solar', year: 2000, month: 1, day: 1, timeIndex: 0, isLeapMonth: false },
  { id: 'lunar-new-year', name: '农历正月初一', gender: 'female', dateType: 'lunar', year: 2024, month: 1, day: 1, timeIndex: 5, isLeapMonth: false },
  { id: 'true-solar', name: '真太阳时案例', gender: 'male', dateType: 'solar', year: 1988, month: 8, day: 8, timeIndex: 0, isLeapMonth: false, useTrueSolarTime: true, birthHour: 12, birthMinute: 0, birthLongitude: 105, timeZoneId: 'Asia/Shanghai' },
] as const;

const vectors = [];
for (const item of cases) {
  const input = buildZiweiChartInput(item);
  const runtime = await calculateZiweiChart(input, { scopes: ['origin'], skipAnalysis: true });
  const payload = runtime.payloadByScope.origin;
  vectors.push({
    id: item.id,
    input: item,
    normalizedInput: input,
    expected: {
      basicInfo: payload.basic_info,
      palaces: payload.palaces,
      activeScope: payload.active_scope,
      calculationConfig: payload.calculation_config,
    },
  });
}

const output = path.join(projectRoot, 'test_vectors', 'ziwei', 'iztro-v1.json');
fs.mkdirSync(path.dirname(output), { recursive: true });
fs.writeFileSync(output, `${JSON.stringify({
  _meta: {
    source: 'mingyu 0.4.0 / iztro 2.5.8',
    sourcePath: 'packages/core/src/ziwei/runtime.ts',
    license: 'AGPL-3.0-only',
    generatedAt: new Date().toISOString(),
  },
  vectors,
}, null, 2)}\n`, 'utf8');
console.log(`已导出 ${vectors.length} 组紫微斗数标准向量：${output}`);
