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

if (!fs.existsSync(tarotSourcePath)) {
  throw new Error(`找不到 mingyu 塔罗数据源：${tarotSourcePath}`);
}

const mingyuPackage = readJson(mingyuPackagePath);
const tarot = loadTarotData(tarotSourcePath);
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
console.log(`- tarot.json：${tarot.cards.length} 张牌，${Object.keys(tarot.spreads).length} 种牌阵`);
console.log('- ganzhi.json：10 天干，12 地支');
