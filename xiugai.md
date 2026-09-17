# 修改记录

> 本文件是**跨会话交接文档**。每轮改动完成后更新三节：本次修改 / 下一步 / 潜在问题。
> 开始新一轮修改前**先读本文件**，避免与并行会话重复劳动或互相覆盖。
>
> 相关文档分工：
> - `docs/MIGRATION_BASELINE.md` —— 上游版本 pin、模块完成状态（权威）
> - `DEPENDENCY_SCAN_REPORT.md` / `TASK_DEVIATION_REPORT.md` —— 早期快照，**结论已部分失效**，勿当作现状
> - `docs/DATA_EXPORT_SUMMARY.md` —— 早期数据导出报告，塔罗牌阵数量已过期（写的是 3 种，实际 18 种）

---

## 状态快照（最近更新：本轮）

| 项 | 状态 |
|---|---|
| git | 本地仓库，无 remote，最新提交 `1626772` |
| 测试 | 66 个全通过（`flutter test`） |
| 静态分析 | `flutter analyze` 零问题 |
| 已移植术式 | 小六壬、塔罗（基础） |
| 数据资产 | `assets/data/{tarot,ganzhi,trigrams,hexagrams}.json` |
| 上游 pin | mingyu `0.4.0` / `878958f`；sydf `ffd2961`（依赖 `mingyu-core 0.2.3`） |

---

## 第 1 轮：修正随机层数值错误

**提交**：`1626772` — `fix(random): 修正种子随机与安全随机的三处数值错误`

### 本次修改

文件：`lib/core/shared/random.dart`、`test/core/shared/random_test.dart`

发现并修复 **4 处**（原估 3 处，动手时发现第 4 处）：

| # | 位置 | 错误 | 实测影响 |
|---|---|---|---|
| 1 | `_hashSeed` | 用 `(hash * 16777619) & 0xFFFFFFFF` 代替 `Math.imul`，与 32 位截断乘法不等价 | 8 个测试种子中 7 个错 |
| 2 | `_imul` | 手写高低 16 位分解时**漏掉 `ah*bh` 项** | 20 万组随机输入中 50.2% 偏移 |
| 3 | `createSeededRandom` | `value ^= value + ...` 的加法产生 **33 位中间值**，未截断即参与异或 | 20 万组中 50.0% 偏移 |
| 4 | `secureRandomFloat` | 高低位宽写反（应为高 27 / 低 26 位），且每次调用重建熵池 | 值域塌缩 |

第 3 处的技术细节：Dart 的 `int` 是 64 位，`value + _imul(...)` 可达 2³³，而该加法结果**直接参与异或**。尾部掩码只能拦最终结果，拦不住漏进异或的第 32 位。

**关键简化**：Dart 的 `int` 为 64 位，`(a * b) & 0xFFFFFFFF` 恰好等价于 `Math.imul`（JS 需要 `Math.imul` 是因为双精度无法安全表示 2⁵³ 以上整数）。所以 `_imul` 从 7 行缩到 1 行：

```dart
int _imul(int a, int b) => (a * b) & 0xFFFFFFFF;
```

**测试补充**（`random_test.dart` 18 → 30 条）：
- 7 组固定种子向量（含上游自己用的 `资料隔离`）
- 整数种子 42 与字符串 `"42"` 同哈希
- 固定向量落盘 → replay 精确复原
- `secureRandomFloat` 53 位精度不塌缩（均值≈0.5、最大样本>0.9、20000 样本中 99% 互异）
- `secureRandomInt` 无空桶 + 分布检查

另外单独用 300 万样本跑了 `randomInt` 的卡方检验（`maxExclusive` = 6/7/10/78/384），p 值 0.22–0.99，**确认无模偏差**。

### 意外收获

用户已废弃「与上游逐字段一致」的约束，但修正后**自动恢复了与上游逐位一致**——用 `npx tsx` 直接跑上游 `createSeededRandom`，35 个数值（7 种子 × 5 样本）全部吻合。两个目标同时达成，且代码更短。

### 下一步（按优先级）

1. **数据导出流水线 + 三山国王灵签**（推荐的下一件事）
   - 新建 `scripts/export-mingyu-data.mjs`，改写 mingyu 的生成脚本
   - 输出到 `assets/data/<术式>/`
   - 灵签数据在 `ssgw-data/signs-full.ts`(1475 行) 与 `signs-01/02/03.ts` 两处都有，**导出前先确认哪个 authoritative**
   - 选它是因为纯查表、零精度风险，用来验证整条链路

2. **补 golden 向量到塔罗/小六壬端到端**
   - 同一种子下，Dart 抽牌序列应可完全复现
   - 塔罗洗牌 = 77 次 `randomInt`，是最能暴露随机层问题的用例

3. **`lib/core/models/` 不存在**
   - 目录约定里写了它，但代码里没有 → 文档与代码不一致
   - 要么建，要么从约定里删掉

4. **塔罗算法位置错误**
   - `lib/features/tarot/tarot_divination.dart`（1286 行）应移到 `lib/core/engine/tarot/`
   - 该文件内 `TarotKeywords`（约 989 行处）是硬编码关键词表，违反规则 1（应走 JSON）

5. **历法 1232 行手写代码待决**
   - `true_solar_time.dart`(425)、`civil_time.dart`(255)、`historical_timezone.dart`(239)、`china_dst.dart`(125)、`date_validation.dart`(121)、`date_utils.dart`(67)
   - 仅 4 个测试。与规则 3（统一改用 `lunar`，不要自己实现历法）冲突
   - 两个选择：删掉改用 `lunar`，或补齐上游测试（`true-solar-time.test.ts` 9 例、`civil-time.test.ts` 4 例）

### 潜在问题

1. **⚠️ 本轮修复改变了种子随机的输出** —— 同一种子现在给出与修复前不同的结果。若真机/某分支上已存过带 seed 的历史记录，那些记录**无法再 replay**。当前无真实用户数据，但需确认无其他分支存在此类数据。

2. **`random.dart` 头注释已改** —— 从「完整移植自 mingyu-core」改为「设计参考…不追求位级一致」。虽然当前实现恰好一致，但注释有意不承诺一致性，以便后续自由改动。若后续要长期保持与上游一致，需把这条注释改回来并加 CI 比对。

3. **`docs/DATA_EXPORT_SUMMARY.md` 已过期** —— 文中写塔罗只有 3 种牌阵，实际 `tarot.json` 已有 18 种。且该文件疑似记录了手工誊抄的数据，而 `scripts/export_data.js` 也需要实际跑一次确认能导出全部 18 种牌阵（若当初是手工补的，重跑脚本会丢）。**未验证**。

4. **4 个并行会话编辑同一工作树** —— 本轮曾检测到 peer session `newproject-23/-d3/-71/-52`。开工前先 `git status` 确认无他人未提交改动。本轮改动只涉及 2 个文件，未冲突。

5. **AGPL-3.0-only 传染性未决** —— mingyu 是 AGPL，本地直译算法会产生衍生作品。若未来要闭源发行需要用户决策（这是法律问题，不是技术问题）。注意：网络 API 调用通常不构成衍生作品。

6. **上游版本二选一未决** —— sydf 依赖 `mingyu-core 0.2.3`，本地 mingyu 是 `0.4.0`，baseline 文档 pin 的是 0.4.0。需用户明确。

### 避免重复劳动（给并行会话）

以下分析**已完成**，勿重做：
- mingyu `divination/` 分层结构已摸清：`rules/data`(常量) → `algorithms`(算术) → `evidence`(渲染) → `prompt`(AI)
- `algorithms/` 共 21798 行；其中 `qimen/helpers/` 约 7500 行是格局数据表，真正算术约 3500 行
- `evidence` 层体量最大且本质是 UI 渲染（如 `meihua` 算术 567 行 vs evidence 1897 行），**建议不移植**，改为 Flutter 渲染
- 数据体量分级已量：单文件直载 ≤138KB（灵签/诸葛签），必须分片懒加载的有 `qimen-patterns`(7500 行)、`yilin-pair-index`(968KB)、`chinaBirthPlaceTree`(912KB)、康熙字典
- `generate-zhuge-signs.mjs` 是**从外部 URL 抓网页**的，不能离线跑；但其产物 `zhuge-signs.ts`(1928 行) 已提交，导出脚本应读产物而非重抓
