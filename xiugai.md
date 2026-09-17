# 修改记录

> 本文件是**跨会话交接文档**。每轮改动完成后更新三节：本次修改 / 下一步 / 潜在问题。
> 开始新一轮修改前**先读本文件**，避免与并行会话重复劳动或互相覆盖。
>
> 相关文档分工：
> - `docs/MIGRATION_BASELINE.md` —— 上游版本 pin、模块完成状态（权威）
> - `DEPENDENCY_SCAN_REPORT.md` / `TASK_DEVIATION_REPORT.md` —— 早期快照，**结论已部分失效**，勿当作现状
> - `docs/DATA_EXPORT_SUMMARY.md` —— 早期数据导出报告，塔罗牌阵数量已过期（写的是 3 种，实际 18 种）

---

## 状态快照（最近更新：第 2 轮）

| 项 | 状态 |
|---|---|
| git | 本地仓库，无 remote |
| 测试 | 68 个全通过（`flutter test`） |
| 静态分析 | `flutter analyze` 零问题 |
| Web 构建 | `flutter build web --release` 通过 |
| 已移植术式 | 小六壬、塔罗（基础） |
| 数据资产 | `assets/data/{tarot,ganzhi,trigrams,hexagrams}.json` |
| 上游 pin | mingyu `0.4.0` / `878958f`；sydf `ffd2961`（依赖 `mingyu-core 0.2.3`） |

---

## 第 2 轮：修复 Web 平台上的 32 位乘法精度问题

**背景**：用户问「改的是否参考 mingyu 算法且能在 Flutter 中实现」。验证时发现第 1 轮的修复**在 Web 上失效**。

### 本次修改

文件：`lib/core/shared/random.dart`、`test/core/shared/random_test.dart`

**问题**：第 1 轮把 `_imul` 简化成了一行：

```dart
int _imul(int a, int b) => (a * b) & 0xFFFFFFFF;   // ❌ Web 上错误
```

这在原生平台正确（Dart int 为 64 位），但 **Web 上 Dart 的 int 由 JS 数字承载，只有 53 位精度**。
两个 32 位数乘积可达 2⁶⁴，远超 2⁵³，乘法**静默丢精度**。

实测同一份代码：

| 平台 | `seed="test"` 首个样本 | 与上游一致 |
|---|---|---|
| 原生 VM | `0.7171058997` | ✅ |
| Web (dart2js) | `0.1832452207` | ❌ |

即：**若出 Web 版/PWA，同一账号在手机与浏览器上会用同一种子抽到不同的卦。**

**修复**：回到 16 位半字分解，并**补上原实现漏掉的项**：

```dart
int _imul(int a, int b) {
  final ah = (a >> 16) & 0xffff;
  final al = a & 0xffff;
  final bh = (b >> 16) & 0xffff;
  final bl = b & 0xffff;
  return (al * bl + (((ah * bl + al * bh) & 0xffff) << 16)) & 0xFFFFFFFF;
}
```

`ah * bh` 项的真实权重是 2³²，在 32 位截断中必然为 0，故不参与计算也不会引入误差。
任一中间结果都不超过 2⁵³，因此在 Web 与原生上行为一致。

### 验证证据

| 验证项 | 结果 |
|---|---|
| 7 个种子 × 5 样本，原生 vs Web | **逐位一致** |
| 20000 组随机 32 位对，原生 vs Web | **逐字符一致** |
| Dart 结果 vs `Math.imul` | 20000 组 0 处不一致 |
| Dart 结果 vs BigInt 精确值 | 20000 组 0 处不一致 |
| `Math.imul` vs BigInt 精确值（基准自检） | 20000 组 0 处不一致 |
| 边界 `0xFFFFFFFF*0xFFFFFFFF` | = 1 ✅（旧版 Web 返回 0） |
| 7 个种子 vs 上游 TS（`npx tsx` 实跑） | 35/35 全吻合 |
| `flutter build web --release` | 通过 |
| wasm 编译 | 通过（未执行，无 wasmtime） |

### 测试补充（`random_test.dart` 30 → 32 条）

- 「种子哈希应正确截断超过 2^53 的乘积」—— 用 `0xFFFFFFFF * 16777619 ≈ 7.2e16` 这个高危输入钉住 Web 回归
- 「长种子（多轮哈希累乘）应保持确定性」—— 覆盖多轮累乘与中文种子

### 下一步（按优先级）

1. **数据导出流水线 + 三山国王灵签**（推荐的下一件事）
   - 新建 `scripts/export-mingyu-data.mjs`，改写 mingyu 的生成脚本
   - 输出到 `assets/data/<术式>/`
   - 灵签数据在 `ssgw-data/signs-full.ts`(1475 行) 与 `signs-01/02/03.ts` 两处都有，**导出前先确认哪个 authoritative**
   - 选它是因为纯查表、零精度风险，用来验证整条链路

2. **验证 `scripts/export_data.js` 能否导出全部 18 种牌阵**（1 分钟即可确认，见潜在问题 3）

3. **补 golden 向量到塔罗/小六壬端到端**
   - 同一种子下，Dart 抽牌序列应可完全复现
   - 塔罗洗牌 = 77 次 `randomInt`，是最能暴露随机层问题的用例

4. **`lib/core/models/` 不存在**
   - 目录约定里写了它，但代码里没有 → 文档与代码不一致
   - 要么建，要么从约定里删掉

5. **塔罗算法位置错误**
   - `lib/features/tarot/tarot_divination.dart`（1286 行）应移到 `lib/core/engine/tarot/`
   - 该文件内 `TarotKeywords`（约 989 行处）是硬编码关键词表，违反规则 1（应走 JSON）

6. **历法 1232 行手写代码待决**
   - `true_solar_time.dart`(425)、`civil_time.dart`(255)、`historical_timezone.dart`(239)、`china_dst.dart`(125)、`date_validation.dart`(121)、`date_utils.dart`(67)
   - 仅 4 个测试。与规则 3（统一改用 `lunar`，不要自己实现历法）冲突
   - 两个选择：删掉改用 `lunar`，或补齐上游测试（`true-solar-time.test.ts` 9 例、`civil-time.test.ts` 4 例）

### 潜在问题

1. **⚠️ 随机层已两次变更输出** —— 第 1 轮和第 2 轮各改了一次，同一种子在不同版本下结果不同。若任何分支/真机上存过带 seed 的历史记录，**无法再 replay**。当前无真实用户数据。
   - **建议**：给随机层加一个 `algorithmVersion` 常量并写入历史记录，以后再改就能识别旧数据。

2. **⚠️ 平台差异是本项目的一类系统性风险** —— 本轮暴露的不是笔误，而是「Web 的 int 只有 53 位」这个平台语义差异。后续移植中凡涉及**大整数位运算、哈希、校验和**的地方都需同样在 Web 目标下验证。`flutter test` **默认跑在原生 VM 上，测不出 Web 问题**，这是当前 CI 的盲区。
   - **建议**：关键的数值模块补 `dart compile js` + 对比的验证脚本，或在 CI 加 web 目标测试。

3. **`docs/DATA_EXPORT_SUMMARY.md` 已过期且可能有实质隐患** —— 文中写塔罗只有 3 种牌阵，实际 `tarot.json` 已有 18 种。且该文件疑似记录了**手工誊抄**的数据。若 18 种牌阵是后来手工补进去的，重跑 `scripts/export_data.js` 会把它们冲掉。**未验证**，动数据前先跑一次脚本 + `git diff`。

4. **`random.dart` 头注释已改** —— 从「完整移植自 mingyu-core」改为「设计参考…不追求位级一致」。但**当前实现实际与上游逐位一致**（已验证 35/35），注释里未承诺这一点。若希望长期保持一致，应改回注释并加比对脚本。

5. **4 个并行会话编辑同一工作树** —— 曾检测到 peer session `newproject-23/-d3/-71/-52`。开工前先 `git status` 确认无他人未提交改动。

6. **AGPL-3.0-only 传染性未决** —— mingyu 是 AGPL，本地直译算法会产生衍生作品。若未来要闭源发行需要用户决策（法律问题，非技术问题）。网络 API 调用通常不构成衍生作品。

7. **上游版本二选一未决** —— sydf 依赖 `mingyu-core 0.2.3`，本地 mingyu 是 `0.4.0`，baseline 文档 pin 的是 0.4.0。需用户明确。

### 避免重复劳动（给并行会话）

以下分析**已完成**，勿重做：
- mingyu `divination/` 分层结构已摸清：`rules/data`(常量) → `algorithms`(算术) → `evidence`(渲染) → `prompt`(AI)
- `algorithms/` 共 21798 行；其中 `qimen/helpers/` 约 7500 行是格局数据表，真正算术约 3500 行
- `evidence` 层体量最大且本质是 UI 渲染（如 `meihua` 算术 567 行 vs evidence 1897 行），**建议不移植**，改为 Flutter 渲染
- 数据体量分级已量：单文件直载 ≤138KB（灵签/诸葛签），必须分片懒加载的有 `qimen-patterns`(7500 行)、`yilin-pair-index`(968KB)、`chinaBirthPlaceTree`(912KB)、康熙字典
- `generate-zhuge-signs.mjs` 是**从外部 URL 抓网页**的，不能离线跑；但其产物 `zhuge-signs.ts`(1928 行) 已提交，导出脚本应读产物而非重抓

以下验证**已做过**，勿重做：
- `random.dart` 的 `_imul` / `_hashSeed` / `createSeededRandom` 已在原生 + Web 双平台验证通过
- `randomInt` 已跑卡方检验（300 万样本，p 值 0.22–0.99），确认无模偏差
