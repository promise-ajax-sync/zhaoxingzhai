/**
 * 导出八卦和六十四卦数据
 */

const fs = require('fs');
const path = require('path');

// 八卦数据
const trigrams = [
  { index: 1, name: '乾', symbol: '☰', nature: '天', element: '金', lines: [1, 1, 1], binary: '111' },
  { index: 2, name: '兑', symbol: '☱', nature: '泽', element: '金', lines: [1, 1, 0], binary: '110' },
  { index: 3, name: '离', symbol: '☲', nature: '火', element: '火', lines: [1, 0, 1], binary: '101' },
  { index: 4, name: '震', symbol: '☳', nature: '雷', element: '木', lines: [1, 0, 0], binary: '100' },
  { index: 5, name: '巽', symbol: '☴', nature: '风', element: '木', lines: [0, 1, 1], binary: '011' },
  { index: 6, name: '坎', symbol: '☵', nature: '水', element: '水', lines: [0, 1, 0], binary: '010' },
  { index: 7, name: '艮', symbol: '☶', nature: '山', element: '土', lines: [0, 0, 1], binary: '001' },
  { index: 8, name: '坤', symbol: '☷', nature: '地', element: '土', lines: [0, 0, 0], binary: '000' },
];

// 六十四卦数据（精简版，包含基本信息）
const hexagrams = [
  // 乾宫
  { id: 1, name: '乾为天', symbol: '☰☰', binary: '111111', upper: '乾', lower: '乾', palace: '乾', description: '元亨利贞' },
  { id: 44, name: '天风姤', symbol: '☰☴', binary: '111011', upper: '乾', lower: '巽', palace: '乾', description: '女壮，勿用取女' },
  { id: 33, name: '天山遁', symbol: '☰☶', binary: '111001', upper: '乾', lower: '艮', palace: '乾', description: '小利贞' },
  { id: 12, name: '天地否', symbol: '☰☷', binary: '111000', upper: '乾', lower: '坤', palace: '乾', description: '否之匪人，不利君子贞' },
  { id: 20, name: '风地观', symbol: '☴☷', binary: '011000', upper: '巽', lower: '坤', palace: '乾', description: '盥而不荐，有孚颙若' },
  { id: 23, name: '山地剥', symbol: '☶☷', binary: '001000', upper: '艮', lower: '坤', palace: '乾', description: '不利有攸往' },
  { id: 35, name: '火地晋', symbol: '☲☷', binary: '101000', upper: '离', lower: '坤', palace: '乾', description: '康侯用锡马蕃庶' },
  { id: 14, name: '火天大有', symbol: '☲☰', binary: '101111', upper: '离', lower: '乾', palace: '乾', description: '元亨' },
  
  // 坎宫
  { id: 29, name: '坎为水', symbol: '☵☵', binary: '010010', upper: '坎', lower: '坎', palace: '坎', description: '有孚，维心亨' },
  { id: 60, name: '水泽节', symbol: '☵☱', binary: '010110', upper: '坎', lower: '兑', palace: '坎', description: '亨，苦节不可贞' },
  { id: 3, name: '水雷屯', symbol: '☵☳', binary: '010100', upper: '坎', lower: '震', palace: '坎', description: '元亨利贞' },
  { id: 63, name: '水火既济', symbol: '☵☲', binary: '010101', upper: '坎', lower: '离', palace: '坎', description: '亨小，利贞' },
  { id: 49, name: '泽火革', symbol: '☱☲', binary: '110101', upper: '兑', lower: '离', palace: '坎', description: '己日乃孚，元亨利贞' },
  { id: 55, name: '雷火丰', symbol: '☳☲', binary: '100101', upper: '震', lower: '离', palace: '坎', description: '亨，王假之' },
  { id: 36, name: '地火明夷', symbol: '☷☲', binary: '000101', upper: '坤', lower: '离', palace: '坎', description: '利艰贞' },
  { id: 7, name: '地水师', symbol: '☷☵', binary: '000010', upper: '坤', lower: '坎', palace: '坎', description: '贞，丈人吉，无咎' },
  
  // 艮宫
  { id: 52, name: '艮为山', symbol: '☶☶', binary: '001001', upper: '艮', lower: '艮', palace: '艮', description: '艮其背，不获其身' },
  { id: 22, name: '山火贲', symbol: '☶☲', binary: '001101', upper: '艮', lower: '离', palace: '艮', description: '亨，小利有攸往' },
  { id: 26, name: '山天大畜', symbol: '☶☰', binary: '001111', upper: '艮', lower: '乾', palace: '艮', description: '利贞，不家食吉' },
  { id: 41, name: '山泽损', symbol: '☶☱', binary: '001110', upper: '艮', lower: '兑', palace: '艮', description: '有孚，元吉，无咎' },
  { id: 38, name: '火泽睽', symbol: '☲☱', binary: '101110', upper: '离', lower: '兑', palace: '艮', description: '小事吉' },
  { id: 10, name: '天泽履', symbol: '☰☱', binary: '111110', upper: '乾', lower: '兑', palace: '艮', description: '履虎尾，不咥人，亨' },
  { id: 61, name: '风泽中孚', symbol: '☴☱', binary: '011110', upper: '巽', lower: '兑', palace: '艮', description: '豚鱼吉，利涉大川' },
  { id: 53, name: '风山渐', symbol: '☴☶', binary: '011001', upper: '巽', lower: '艮', palace: '艮', description: '女归吉，利贞' },
  
  // 震宫
  { id: 51, name: '震为雷', symbol: '☳☳', binary: '100100', upper: '震', lower: '震', palace: '震', description: '亨，震来虩虩' },
  { id: 16, name: '雷地豫', symbol: '☳☷', binary: '100000', upper: '震', lower: '坤', palace: '震', description: '利建侯行师' },
  { id: 40, name: '雷水解', symbol: '☳☵', binary: '100010', upper: '震', lower: '坎', palace: '震', description: '利西南，无所往' },
  { id: 32, name: '雷风恒', symbol: '☳☴', binary: '100011', upper: '震', lower: '巽', palace: '震', description: '亨，无咎，利贞' },
  { id: 46, name: '地风升', symbol: '☷☴', binary: '000011', upper: '坤', lower: '巽', palace: '震', description: '元亨，用见大人' },
  { id: 48, name: '水风井', symbol: '☵☴', binary: '010011', upper: '坎', lower: '巽', palace: '震', description: '改邑不改井' },
  { id: 28, name: '泽风大过', symbol: '☱☴', binary: '110011', upper: '兑', lower: '巽', palace: '震', description: '栋桡，利有攸往' },
  { id: 17, name: '泽雷随', symbol: '☱☳', binary: '110100', upper: '兑', lower: '震', palace: '震', description: '元亨利贞，无咎' },

  // 巽宫
  { id: 57, name: '巽为风', symbol: '☴☴', binary: '011011', upper: '巽', lower: '巽', palace: '巽', description: '小亨，利有攸往' },
  { id: 9, name: '风天小畜', symbol: '☴☰', binary: '011111', upper: '巽', lower: '乾', palace: '巽', description: '亨，密云不雨' },
  { id: 37, name: '风火家人', symbol: '☴☲', binary: '011101', upper: '巽', lower: '离', palace: '巽', description: '利女贞' },
  { id: 42, name: '风雷益', symbol: '☴☳', binary: '011100', upper: '巽', lower: '震', palace: '巽', description: '利有攸往，利涉大川' },
  { id: 25, name: '天雷无妄', symbol: '☰☳', binary: '111100', upper: '乾', lower: '震', palace: '巽', description: '元亨利贞' },
  { id: 21, name: '火雷噬嗑', symbol: '☲☳', binary: '101100', upper: '离', lower: '震', palace: '巽', description: '亨，利用狱' },
  { id: 27, name: '山雷颐', symbol: '☶☳', binary: '001100', upper: '艮', lower: '震', palace: '巽', description: '贞吉，观颐' },
  { id: 18, name: '山风蛊', symbol: '☶☴', binary: '001011', upper: '艮', lower: '巽', palace: '巽', description: '元亨，利涉大川' },

  // 离宫
  { id: 30, name: '离为火', symbol: '☲☲', binary: '101101', upper: '离', lower: '离', palace: '离', description: '利贞，亨' },
  { id: 56, name: '火山旅', symbol: '☲☶', binary: '101001', upper: '离', lower: '艮', palace: '离', description: '小亨，旅贞吉' },
  { id: 50, name: '火风鼎', symbol: '☲☴', binary: '101011', upper: '离', lower: '巽', palace: '离', description: '元吉，亨' },
  { id: 64, name: '火水未济', symbol: '☲☵', binary: '101010', upper: '离', lower: '坎', palace: '离', description: '亨，小狐汔济' },
  { id: 4, name: '山水蒙', symbol: '☶☵', binary: '001010', upper: '艮', lower: '坎', palace: '离', description: '亨，匪我求童蒙' },
  { id: 59, name: '风水涣', symbol: '☴☵', binary: '011010', upper: '巽', lower: '坎', palace: '离', description: '亨，王假有庙' },
  { id: 6, name: '天水讼', symbol: '☰☵', binary: '111010', upper: '乾', lower: '坎', palace: '离', description: '有孚，窒惕' },
  { id: 13, name: '天火同人', symbol: '☰☲', binary: '111101', upper: '乾', lower: '离', palace: '离', description: '同人于野，亨' },

  // 坤宫
  { id: 2, name: '坤为地', symbol: '☷☷', binary: '000000', upper: '坤', lower: '坤', palace: '坤', description: '元亨，利牝马之贞' },
  { id: 24, name: '地雷复', symbol: '☷☳', binary: '000100', upper: '坤', lower: '震', palace: '坤', description: '亨，出入无疾' },
  { id: 19, name: '地泽临', symbol: '☷☱', binary: '000110', upper: '坤', lower: '兑', palace: '坤', description: '元亨利贞' },
  { id: 11, name: '地天泰', symbol: '☷☰', binary: '000111', upper: '坤', lower: '乾', palace: '坤', description: '小往大来，吉亨' },
  { id: 34, name: '雷天大壮', symbol: '☳☰', binary: '100111', upper: '震', lower: '乾', palace: '坤', description: '利贞' },
  { id: 43, name: '泽天夬', symbol: '☱☰', binary: '110111', upper: '兑', lower: '乾', palace: '坤', description: '扬于王庭' },
  { id: 5, name: '水天需', symbol: '☵☰', binary: '010111', upper: '坎', lower: '乾', palace: '坤', description: '有孚，光亨' },
  { id: 8, name: '水地比', symbol: '☵☷', binary: '010000', upper: '坎', lower: '坤', palace: '坤', description: '吉，原筮元永贞' },

  // 兑宫
  { id: 58, name: '兑为泽', symbol: '☱☱', binary: '110110', upper: '兑', lower: '兑', palace: '兑', description: '亨，利贞' },
  { id: 47, name: '泽水困', symbol: '☱☵', binary: '110010', upper: '兑', lower: '坎', palace: '兑', description: '亨，贞大人吉' },
  { id: 45, name: '泽地萃', symbol: '☱☷', binary: '110000', upper: '兑', lower: '坤', palace: '兑', description: '亨，王假有庙' },
  { id: 31, name: '泽山咸', symbol: '☱☶', binary: '110001', upper: '兑', lower: '艮', palace: '兑', description: '亨，利贞，取女吉' },
  { id: 39, name: '水山蹇', symbol: '☵☶', binary: '010001', upper: '坎', lower: '艮', palace: '兑', description: '利西南，不利东北' },
  { id: 15, name: '地山谦', symbol: '☷☶', binary: '000001', upper: '坤', lower: '艮', palace: '兑', description: '亨，君子有终' },
  { id: 62, name: '雷山小过', symbol: '☳☶', binary: '100001', upper: '震', lower: '艮', palace: '兑', description: '亨，利贞' },
  { id: 54, name: '雷泽归妹', symbol: '☳☱', binary: '100110', upper: '震', lower: '兑', palace: '兑', description: '征凶，无攸利' },
];

// 导出数据
const outputDir = path.join(__dirname, '..', 'assets', 'data');

// 确保目录存在
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

// 导出八卦数据
fs.writeFileSync(
  path.join(outputDir, 'trigrams.json'),
  JSON.stringify({ trigrams }, null, 2),
  { encoding: 'utf8' }
);

// 导出六十四卦数据（完整版）
fs.writeFileSync(
  path.join(outputDir, 'hexagrams.json'),
  JSON.stringify({ hexagrams }, null, 2),
  { encoding: 'utf8' }
);

console.log('✅ 卦象数据导出完成！');
console.log(`  - ${outputDir}/trigrams.json (8个基本卦)`);
console.log(`  - ${outputDir}/hexagrams.json (${hexagrams.length}个六十四卦)`);
