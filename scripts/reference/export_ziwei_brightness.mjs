import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const upstreamRepository = resolve(
  process.argv[2] ?? resolve(projectRoot, '..', '..', 'githubsm', 'horosa-skill'),
);
const sourceRelative = 'horosa-skill/horosa-core-js/src/vendor/ziwei/data/tables/ziweistarlight_quanshu_full.json';
const sourcePath = resolve(upstreamRepository, sourceRelative);
const outputPath = resolve(projectRoot, 'assets/data/ziwei/brightness.json');
const byStar = JSON.parse(readFileSync(sourcePath, 'utf8'));
const branches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
const allowedLevels = new Set(['庙', '旺', '得', '利', '平', '不', '陷']);

for (const [star, rows] of Object.entries(byStar)) {
  const keys = Object.keys(rows);
  if (keys.length !== branches.length || branches.some((branch) => !(branch in rows))) {
    throw new Error(`${star} 必须覆盖十二地支`);
  }
  for (const branch of branches) {
    const value = rows[branch];
    if (value !== null && !allowedLevels.has(value)) {
      throw new Error(`${star}/${branch} 亮度值无效：${value}`);
    }
  }
}

let upstreamCommit = 'unknown';
try {
  const gitDir = resolve(upstreamRepository, '.git');
  const head = readFileSync(resolve(gitDir, 'HEAD'), 'utf8').trim();
  if (head.startsWith('ref: ')) {
    const refPath = resolve(gitDir, head.slice(5));
    if (existsSync(refPath)) upstreamCommit = readFileSync(refPath, 'utf8').trim();
  } else {
    upstreamCommit = head;
  }
} catch {}

const output = {
  schemaVersion: 1,
  dataVersion: 1,
  profileId: 'quanshu-seven-tier-v1',
  levels: ['庙', '旺', '得', '利', '平', '不', '陷'],
  branchOrder: branches,
  coverage: {
    starCount: Object.keys(byStar).length,
    policy: '只标注源表明确收录的星曜；未收录星曜保持空值，不使用其他流派表补齐。',
  },
  source: {
    repository: 'horosa-skill',
    commit: upstreamCommit,
    file: sourceRelative,
    license: 'AGPL-3.0',
    transformation: '仅转换为本项目 JSON 协议，不导入上游解释文案或运行时代码。',
  },
  interpretationBoundary: '亮度是指定传本下的分类标签，不等同现实吉凶、强弱分数或事件概率。',
  byStar,
};

writeFileSync(outputPath, `${JSON.stringify(output, null, 2)}\n`, 'utf8');
console.log(`Wrote ${outputPath}`);
