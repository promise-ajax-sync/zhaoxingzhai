# 📊 依赖扫描与归类报告

> ⚠️ 历史快照：本文档生成于早期迁移阶段，文件数量和完成状态已经过期。当前迁移基线与状态以 `docs/MIGRATION_BASELINE.md` 和 `README.md` 为准。

**生成时间**: 2025-01  
**源仓库**: e:\newProject\githubsm\mingyu\packages\core\src\  
**目标**: Flutter/Dart 移植

---

## 📋 扫描汇总表

| 类别 | 文件数 | 可移植性 | 优先级 |
|------|--------|----------|--------|
| **A类（纯数据）** | 4 | ✅ 高 | P1 |
| **B类（纯算法）** | 4 | ✅ 高 | P1-P2 |
| **C类（需lunar）** | 2 | ⚠️ 中 | P2 |
| **D类（不移植）** | 0 | ❌ 低 | - |
| **已完成** | 2 | ✅ | - |

**总计**: 12个文件，已完成2个，待移植10个

---

## 🔍 详细归类

### ✅ 已完成模块

#### 1. algorithms/xiaoliuren.ts → lib/core/engine/xiaoliuren/
**归类**: B类（纯算法）  
**状态**: ✅ 已移植  
**依赖**:
```typescript
import { getShichenByIndex, getTimeIndexFromClock } from '../../calendar/dateUtils';
import { getDivinationTime } from '../../calendar/timeManager';
import { assertOptionalRecord } from '../../shared/validation';
import { attachResultMeta } from '../../shared/result';
import { analyzeXiaoliurenEvidence } from '../xiaoliuren-evidence';
import { resolveXiaoliurenRule } from '../xiaoliuren-rules';
```
**依赖类型**: 全部为本项目内部  
**问题**: ❌ 缺少单元测试

#### 2. tarot.ts + tarot-data.ts → lib/features/tarot/
**归类**: A类（数据）+ B类（算法）  
**状态**: ✅ 已移植  
**依赖**:
```typescript
import { tarotCards, tarotSpreads } from './tarot-data';  // A类数据
import type { RandomOptions } from '../shared/random';     // B类
import { createRandomContext, randomInt } from '../shared/random';
import { attachResultMeta } from '../shared/result';
import { analyzeTarotEvidence } from './tarot-evidence';
```
**依赖类型**: 全部为本项目内部  
**问题**: 
- ❌ 位置错误（应在 lib/core/engine/tarot/）
- ❌ 关键词数据硬编码（应从JSON加载）
- ❌ 缺少单元测试

---

### 🆕 待移植模块

#### 3. algorithms/yarrow.ts
**归类**: ✅ **B类（纯算法）**  
**依赖**:
```typescript
import { createRandomContext, hasRandomOptions, randomInt } from '../../shared/random';
import type { RandomOptions, RandomTrace } from '../../shared/random';
import { assertOptionalRecord } from '../../shared/validation';
import { MingyuCoreError } from '../../shared/result';
```
**依赖类型**: ✅ 全部为本项目内部，无外部依赖  
**功能**: 蓍草起卦（大衍筮法，49策分二挂一揲四归奇）  
**复杂度**: ⭐⭐ 中等  
**移植到**: `lib/core/engine/yarrow/yarrow.dart`  
**预计工时**: 3小时（算法2h + 测试1h）  
**优先级**: 🔥 P1（依赖已就绪）

**移植计划**:
```dart
lib/core/engine/yarrow/
├── yarrow.dart           # 主算法
├── models.dart          # YarrowChange, YarrowLine, YarrowResult
└── yarrow_test.dart     # 单元测试（对照 tests/yarrow.test.ts）
```

---

#### 4. algorithms/ssgw.ts（诸葛神签）
**归类**: ✅ **B类（纯算法）** + ⚠️ **A类（需导出签文数据）**  
**依赖**:
```typescript
import type { SsgwData } from '../../types/divination';
import { SSGW_SIGNS } from '../../divination/ssgw-data';  // ⚠️ 数据依赖
import { getDivinationTime } from '../../calendar/timeManager';
import { createRandomContext, randomInt } from '../../shared/random';
import { attachResultMeta } from '../../shared/result';
```
**依赖类型**: ✅ 本项目内部 + ⚠️ 需导出签文数据  
**功能**: 随机抽签（三山国王92签）  
**复杂度**: ⭐ 简单  
**移植到**: `lib/core/engine/ssgw/ssgw.dart`  
**预计工时**: 4小时（数据导出1h + 算法1h + 测试1h + UI 1h）  
**优先级**: 🔥 P1

**前置工作**: 
1. 导出签文数据: `ssgw-data/signs-full.ts` → `assets/data/ssgw_signs.json`
2. 创建导出脚本: `scripts/export_ssgw.js`

**移植计划**:
```dart
lib/core/engine/ssgw/
├── ssgw.dart            # 抽签算法
├── models.dart          # SsgwSign, SsgwResult
└── ssgw_test.dart       # 单元测试

lib/core/data/
└── ssgw_data.dart       # 签文加载器

assets/data/
└── ssgw_signs.json      # 92条签文
```

---

#### 5. algorithms/meihua/（梅花易数）
**归类**: ⚠️ **C类（需lunar库）**  
**依赖**: 需要查看详细文件  
**功能**: 梅花易数起卦  
**复杂度**: ⭐⭐⭐ 中高  
**移植到**: `lib/core/engine/meihua/`  
**预计工时**: 8小时（算法4h + lunar集成2h + 测试2h）  
**优先级**: 🔥 P2（需先集成lunar库）

**前置工作**:
1. 集成 pub.dev/lunar 库
2. 查看详细依赖

---

#### 6. algorithms/liuyao.ts（六爻占卜）
**归类**: ⚠️ **C类（需lunar）** + ⚠️ **A类（需导出纳甲数据）**  
**依赖**: 需要查看详细文件  
**功能**: 六爻排盘与装卦  
**复杂度**: ⭐⭐⭐⭐ 高  
**移植到**: `lib/core/engine/liuyao/`  
**预计工时**: 12小时（数据2h + 算法6h + 测试2h + UI 2h）  
**优先级**: 🔥 P2

**前置工作**:
1. 导出纳甲、世应、六亲数据
2. 集成 lunar 库

---

### 📦 数据文件（A类）

#### 7. ssgw-data/（诸葛神签数据）
**归类**: ✅ **A类（纯数据）**  
**文件**:
- `signs-full.ts` - 92条完整签文
- `interpretation.ts` - 签文解释
- `types.ts` - 类型定义

**处理方式**:
```javascript
// scripts/export_ssgw.js
导出为: assets/data/ssgw_signs.json
[
  {
    "id": 1,
    "title": "签题",
    "poem": "签诗四句",
    "story": "典故",
    "details": "详解"
  },
  ...92条
]
```

#### 8. tarot-data.ts（塔罗牌数据）
**归类**: ✅ **A类（纯数据）**  
**状态**: ✅ 已导出 `assets/data/tarot.json`  
**问题**: ⚠️ 关键词仍硬编码在Dart中，需要补充到JSON

---

### 🔧 工具模块

#### 9. calendar/lunar.ts
**归类**: ⚠️ **C类（应使用pub lunar库替换）**  
**依赖**:
```typescript
// 需要查看是否依赖 tyme4ts 或其他天文库
```
**处理方式**: ❌ 不自己实现，改用 `pub.dev/lunar`（6tail，MIT）

#### 10. calendar/timeManager.ts
**归类**: ✅ **B类（部分已移植）**  
**状态**: ✅ 部分功能已在 `civil_time.dart` 中实现  
**需要**: 补充完整

---

## 📊 移植优先级矩阵

### 🔥 P1 - 立即可移植（依赖已就绪）

| 模块 | 类别 | 复杂度 | 工时 | 价值 |
|------|------|--------|------|------|
| yarrow | B类 | ⭐⭐ | 3h | 高 |
| ssgw | B类+A类 | ⭐ | 4h | 高 |

**总工时**: 7小时  
**阻塞因素**: 无

### 🔥 P2 - 需前置工作

| 模块 | 类别 | 前置工作 | 工时 | 价值 |
|------|------|----------|------|------|
| meihua | C类 | 集成lunar | 8h | 高 |
| liuyao | C类+A类 | lunar+数据 | 12h | 高 |

**总工时**: 20小时  
**阻塞因素**: lunar库集成（1小时）

---

## 🎯 推荐的移植顺序

### Phase 1: 基础算法（P1，本周）
```
1. yarrow（蓍草起卦）     3小时 ✅ 立即可开始
2. ssgw（诸葛神签）       4小时 ✅ 立即可开始
```

### Phase 2: 集成lunar + 复杂算法（P2，下周）
```
3. 集成 pub.dev/lunar      1小时
4. meihua（梅花易数）      8小时
5. liuyao（六爻占卜）      12小时
```

---

## 📝 移植规范检查表

每个模块移植时必须：

### ✅ 代码规范
- [ ] 保持原函数名和参数语义
- [ ] 使用标准目录结构 `lib/core/engine/<术式>/`
- [ ] 数据从JSON加载，不硬编码
- [ ] 实现完整的随机数 seed + replay

### ✅ 测试规范
- [ ] 创建对应的单元测试
- [ ] 测试用例来自 `mingyu/tests/` 同名测试
- [ ] 输入输出逐字段一致
- [ ] 使用相同的测试数据

### ✅ 数据规范
- [ ] 使用脚本导出，不手工誊抄
- [ ] JSON格式规范
- [ ] UTF-8编码
- [ ] 大数据支持分片和懒加载

---

## 🚨 发现的问题

### 已完成模块的问题

1. **小六壬**:
   - ❌ 缺少单元测试
   - ⚠️ 应创建 `test/core/engine/xiaoliuren/xiaoliuren_algorithm_test.dart`
   - ⚠️ 对照 `mingyu/tests/xiaoliuren-algorithm.test.ts`

2. **塔罗占卜**:
   - ❌ 位置错误：在 `lib/features/tarot/`，应该在 `lib/core/engine/tarot/`
   - ❌ 关键词硬编码：78张牌关键词在 `TarotKeywords` 类中
   - ❌ 缺少单元测试
   - ⚠️ 应对照 `mingyu/tests/tarot.test.ts`

3. **历法模块**:
   - ❌ 缺少单元测试
   - ⚠️ 未使用 lunar 库（应集成）

---

## 🎯 下一步行动

### 立即执行（今天）

**选项A: 补充现有模块测试** ✅ 推荐
```
1. 创建小六壬单元测试（1小时）
2. 创建塔罗占卜单元测试（1小时）
3. 对照上游验证结果
```

**选项B: 开始新模块移植**
```
1. 移植 yarrow（蓍草起卦）（3小时）
   - 算法直译
   - 创建测试
   - 验证结果

2. 导出ssgw签文数据 + 移植算法（4小时）
```

**选项C: 重组现有结构**
```
1. 移动 tarot_divination.dart 到正确位置
2. 将关键词导出到JSON
3. 补充测试
```

---

## 💡 我的建议

**立即执行选项A + 选项B并行**：

**今天任务**：
1. ✅ 补充小六壬单元测试（1小时）
2. ✅ 移植 yarrow 蓍草起卦（3小时）
3. ✅ 导出ssgw签文数据（1小时）

**明天任务**：
4. ✅ 移植 ssgw 诸葛神签（2小时）
5. ✅ 补充塔罗单元测试（1小时）
6. ✅ 集成 lunar 库（1小时）

**预期成果**：
- 4个术式算法完成
- 全部有单元测试
- 严格符合任务规范

---

**你希望我现在开始：**

**A. 补充小六壬单元测试** ✅ 推荐（对照上游）  
**B. 移植 yarrow（蓍草起卦）** ✅ 推荐（新模块）  
**C. 导出ssgw签文数据** ✅ 推荐（前置工作）  
**D. 其他建议？**
