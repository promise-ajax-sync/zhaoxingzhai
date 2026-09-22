import fs from 'node:fs';
import path from 'node:path';

const projectRoot = path.resolve(import.meta.dirname, '..');
const inputPath = path.join(projectRoot, 'assets', 'data', 'ssgw.json');
const source = JSON.parse(fs.readFileSync(inputPath, 'utf8'));

if (!source._meta || typeof source._meta.source !== 'string') {
  throw new Error('ssgw.json 缺少可追溯的 _meta.source');
}
if (!Array.isArray(source.signs) || source.signs.length !== 92) {
  throw new Error(`灵签数量异常：期望 92，实际 ${source.signs?.length}`);
}

const requiredDetails = [
  '吉凶',
  '解签总论',
  '核心寓意',
  '行动建议',
  '风险提醒',
];
const numbers = new Set();
for (const [index, sign] of source.signs.entries()) {
  if (!Number.isInteger(sign.id) || sign.id !== index + 1) {
    throw new Error(`签号不连续：第 ${index + 1} 项为 ${sign.id}`);
  }
  if (numbers.has(sign.id)) {
    throw new Error(`签号重复：${sign.id}`);
  }
  numbers.add(sign.id);
  for (const field of ['title', 'qianwen', 'story']) {
    if (typeof sign[field] !== 'string' || sign[field].trim() === '') {
      throw new Error(`第 ${sign.id} 签缺少非空字段：${field}`);
    }
  }
  if (!sign.details || typeof sign.details !== 'object') {
    throw new Error(`第 ${sign.id} 签缺少 details`);
  }
  for (const key of requiredDetails) {
    if (typeof sign.details[key] !== 'string' || sign.details[key].trim() === '') {
      throw new Error(`第 ${sign.id} 签缺少非空解签字段：${key}`);
    }
  }
}

console.log(
  `三山国王灵签数据校验通过：${source.signs.length} 签，来源 ${source._meta.source}`,
);
