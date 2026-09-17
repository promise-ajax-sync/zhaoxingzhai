/**
 * 从本地 mingyu 源码同步 Flutter 使用的静态数据。
 *
 * 默认源目录：E:/newProject/githubsm/mingyu
 * 也可以通过第一个命令行参数指定其他 mingyu 仓库目录。
 */

const fs = require('fs');
const path = require('path');
const vm = require('vm');

const projectRoot = path.resolve(__dirname, '..');
const defaultMingyuRoot = path.resolve(projectRoot, '..', '..', 'githubsm', 'mingyu');
const mingyuRoot = path.resolve(process.argv[2] || defaultMingyuRoot);
const tarotSourcePath = path.join(
  mingyuRoot,
  'packages',
  'core',
  'src',
  'divination',
  'tarot-data.ts',
);
const tarotAlgorithmPath = path.join(
  mingyuRoot,
  'packages',
  'core',
  'src',
  'divination',
  'tarot.ts',
);
const mingyuPackagePath = path.join(mingyuRoot, 'package.json');
const outputDir = path.join(projectRoot, 'assets', 'data');

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function loadTarotData(filePath) {
  const source = fs.readFileSync(filePath, 'utf8')
    .replace('export const tarotCards =', 'globalThis.tarotCards =')
    .replace('export const tarotSpreads =', 'globalThis.tarotSpreads =');
  const sandbox = {};
  vm.runInNewContext(source, sandbox, { filename: filePath });

  if (!Array.isArray(sandbox.tarotCards) || !sandbox.tarotSpreads) {
    throw new Error(`无法从 ${filePath} 解析塔罗数据`);
  }
  return {
    cards: JSON.parse(JSON.stringify(sandbox.tarotCards)),
    spreads: JSON.parse(JSON.stringify(sandbox.tarotSpreads)),
  };
}

function loadTarotKeywords(filePath) {
  const source = fs.readFileSync(filePath, 'utf8');
  const block = source.match(
    /const keywordsMap: Record<string, string> = \{([\s\S]*?)\n\s*\};/,
  );
  if (!block) {
    throw new Error(`无法从 ${filePath} 定位塔罗关键词表`);
  }

  const keywords = {};
  const entryPattern = /^\s*([^:/]+):\s*'([^']*)',\s*$/gm;
  for (const match of block[1].matchAll(entryPattern)) {
    keywords[match[1].trim()] = match[2].split(',');
  }
  if (Object.keys(keywords).length !== 78) {
    throw new Error(
      `塔罗关键词数量异常：期望 78，实际 ${Object.keys(keywords).length}`,
    );
  }
  return keywords;
}

if (!fs.existsSync(tarotSourcePath)) {
  throw new Error(`找不到 mingyu 塔罗数据源：${tarotSourcePath}`);
}
if (!fs.existsSync(tarotAlgorithmPath)) {
  throw new Error(`找不到 mingyu 塔罗算法源：${tarotAlgorithmPath}`);
}

const mingyuPackage = readJson(mingyuPackagePath);
const tarot = loadTarotData(tarotSourcePath);
const tarotKeywords = loadTarotKeywords(tarotAlgorithmPath);
tarot.cards = tarot.cards.map((card) => {
  const keywords = tarotKeywords[card.name];
  if (!keywords) {
    throw new Error(`塔罗牌缺少关键词：${card.name}`);
  }
  return { ...card, keywords };
});
const ganzhi = {
  tiangan: ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'],
  dizhi: ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'],
};

fs.mkdirSync(outputDir, { recursive: true });
fs.writeFileSync(
  path.join(outputDir, 'tarot.json'),
  `${JSON.stringify({
    _meta: {
      source: 'mingyu/packages/core/src/divination/tarot-data.ts',
      keywordsSource: 'mingyu/packages/core/src/divination/tarot.ts#getCardKeywords',
      mingyuVersion: mingyuPackage.version,
    },
    ...tarot,
  }, null, 2)}\n`,
  'utf8',
);
fs.writeFileSync(
  path.join(outputDir, 'ganzhi.json'),
  `${JSON.stringify({
    _meta: {
      source: 'mingyu canonical heavenly stems and earthly branches',
      mingyuVersion: mingyuPackage.version,
    },
    ...ganzhi,
  }, null, 2)}\n`,
  'utf8',
);

console.log(`已从 mingyu ${mingyuPackage.version} 同步数据：`);
console.log(`- tarot.json：${tarot.cards.length} 张牌（含关键词），${Object.keys(tarot.spreads).length} 种牌阵`);
console.log('- ganzhi.json：10 天干，12 地支');
