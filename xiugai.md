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
| 已提交 | `4ba8b7b` 第 2 轮修复；`6ace8b1` 建本文档；`1626772` 第 1 轮修复；`fb4019a` 初版快照 |

---

## TODO 总表（截至第 2 轮，未完成的事项都在这里）

> 分三档：**近期待办**（已明确要做、只差开工）／**待定决策**（需要用户拍板）／**未开工大项**（任务书要求但尚未开始）。
> 每轮改动后**回来勾选**，不要只在「下一步」里留一份。

### A. 近期待办

| # | 事项 | 出处 | 备注 |
|---|---|---|---|
| A1 | 数据导出流水线：写 `scripts/export-mingyu-data.mjs`，改写 mingyu 生成脚本 → `assets/data/<术式>/` | 规则 1 | 推荐先做，纯查表零精度风险，用来打通整条链路 |
| A2 | 三山国王灵签数据导出 | 规则 1 | **前置**：先确认 `ssgw-data/signs-full.ts`(1475 行) 与 `signs-01/02/03.ts` 哪个是权威源 |
| A3 | 补塔罗端到端 golden 向量（同种子抽牌序列可复现） | 验收 1 | 洗牌 = 77 次 `randomInt`，最易暴露随机层问题 |
| A4 | 补小六壬端到端 golden 向量 | 验收 1 | |
| A5 | 塔罗算法挪位：`lib/features/tarot/tarot_divination.dart`(1286 行) → `lib/core/engine/tarot/` | 目录约定 | 该文件约 989 行处的 `TarotKeywords` 硬编码表违反规则 1，应改走 JSON |
| A6 | 处理 `lib/core/models/` 不存在的问题 | 目录约定 | 要么建目录，要么从约定文档里删掉 |
| A7 | 随机层加 `algorithmVersion` 常量，并随历史记录持久化 | 潜在问题 1 | 见下方说明，越早加越省事 |
| A8 | 给随机层加 Web 目标验证脚本（`dart compile js` 后跑同一批种子对比） | 潜在问题 2 | `flutter test` 跑原生 VM，**测不出 Web 问题**，这是当前 CI 盲区 |
| A9 | 验证 `codeUnitAt` 与上游 `charCodeAt` 在代理对字符（emoji）上是否分叉 | 潜在问题 8 | 未验证，尚未构成已知 bug |
| A10 | 收敛小六壬的硬编码配色，并入 `AppTheme` | 本轮 UI 比对 | 4 个文件共 50 处硬编码色值（`0xFFE9A568` 32 处 + 墨蓝渐变 18 处），自成一套暗色皮肤，**不吃深色/浅色主题切换**。当前 App 内存在两套互斥视觉语言，塔罗↔小六壬切换像换 App |
| A11 | 补宽屏断点与侧栏/顶栏布局 | 本轮 UI 比对 | 现状无任何 `LayoutBuilder`，全部按手机竖屏写死；Web 版在桌面浏览器会呈窄柱居中。**前置**：需先决定是否复刻 sydf 的 15 视图侧栏结构（见 B6） |

### A10 / A11 补充说明（本轮 UI 比对结论）

**已经做到的部分**（无需返工）：`AppTheme` 与 sydf `tokens.css` 的色值**精确相同**——浅色 13 个主 token（canvas `#f3f2f5`、surface `#fbfafc`、surface-raised `#ffffff`、text-primary `#2e2b36`、text-secondary `#6a6572`、text-tertiary `#77717f`、line `#dfdce4`、line-strong `#cbc6d0`、accent `#8368ab`、accent-strong `#694c96`、accent-soft `#e9e2f2`、danger `#a65364`、success `#55796e`）与深色主题全套逐一对应；间距/圆角/动画时长三组数值也全部对齐。

**A10 排查范围**：`xiaoliuren_page.dart`、`date_time_input_section.dart`、`result_display_section.dart`、`calculating_animation.dart`。改法是把这些色值提成 `AppTheme` 里的语义 token，或直接复用现有 accent/warning 槽位。改完顺带验证深色模式下的观感（当前它在浅色模式下也是一整片墨蓝）。

**A11 缺失的布局 token**（sydf 有、Flutter 无）：`--ds-topbar-height: 64px`、`--ds-page-content: 1180px`、`--ds-page-gutter`、`--ds-control-sm/md/lg: 34/38/44px`、`--ds-reading-card-width: 136px`、`--ds-reading-section-x/y`。宽屏排版要散，缺的就是这些约束。

**A11 与 A10 的取舍**：A10 改动小、收益直接，建议先做；A11 改动大且依赖 B6 的结构决策，建议后置。若打算先把术式铺开再统一样式，两者都往后排，但 **A10 不宜拖太久**——后续每加一个页面都可能再抄一遍那套暗色。

### B. 待定决策（需要用户拍板）

| # | 事项 | 两个选项 | 影响 |
|---|---|---|---|
| B1 | 1232 行手写历法代码怎么办 | ①删掉改用 `lunar`（合规则 3）②保留并补齐上游测试 | 若删改，`true-solar-time`/`civil-time` 的 13 个上游测试是现成验收依据；若保留，需自行承担历法正确性 |
| B2 | 上游 baseline 用哪个版本 | ①mingyu `0.4.0` ②sydf 依赖的 `0.2.3` | 影响所有算法比对的参照物 |
| B3 | AGPL-3.0-only 传染性 | ①接受 GPL 系开源 ②只用 REST 不本地直译 ③其他 | **法律问题非技术问题**。本地直译算法构成衍生作品；网络 API 调用通常不构成 |
| B4 | `evidence` 层是否移植 | ①全部在 Flutter 侧重写渲染（建议）②移植 | 该层体量最大（如 meihua 算术 567 行 vs evidence 1897 行），本质是 UI 渲染 |
| B5 | 《这一条》的具体所指 | 待确认 | 已废弃「验收标准 2 的与上游逐字段一致」与「规则 2 的保持原函数名」。**seed + replay 保留**（那是 App 自身功能） |
| B6 | 是否复刻 sydf 的 15 视图侧栏结构 | ①复刻（侧栏 + 顶栏，移动端收抽屉）②保持现在的 4 Tab ③两者都做（宽屏侧栏 / 窄屏底部 Tab，响应式切换） | sydf 的 `appRoute.ts` 列了 15 个视图（13 个工具入口 + `cases`/`settings`），现有 Flutter 只落实了 2 个工具 + 自加的历史页。**决定 A11 怎么做**；选项 ③ 最贴近 Web/移动双端目标但工作量最大 |

### C. 未开工大项

| # | 事项 | 现状 | 说明 |
|---|---|---|---|
| C1 | 全量 A/B/C/D 扫描报告 | **未开始** | mingyu 共 557 个 `.ts`；现有 `DEPENDENCY_SCAN_REPORT.md` 只覆盖 12 个文件且自述已过期，不可当现状 |
| C2 | 逐文件移植计划 | **未开始** | 依赖 C1 |
| C3 | 规则 3 的历法前置 | **未开始** | 任务书要求先移植 `calendar/true-solar-time.ts` 等 4 个文件再移植依赖它们的术式；但当前这 4 个文件是**手写实现**而非移植（见 B1） |
| C4 | D 类 REST 封装 `ApiClient` | **未开始** | 规则 4；目前也没确认 mingyu 里是否真有 D 类模块 |
| C5 | 大字表分片懒加载 | **未开始** | 需分片的：`qimen-patterns`(7500 行)、`yilin-pair-index`(968KB)、`chinaBirthPlaceTree`(912KB)、康熙字典 |
| C6 | 离线/联网双模架构 | **未开始** | 用户目标：离线可用一部分，联网完整使用。依赖 C4 |
| C7 | 其余术式移植 | **未开始** | 小六壬、塔罗已完成；mingyu 顶层 `divination/` 另有约 20437 行 |

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

7. **上游版本二选一未决** —— sydf 依赖 `mingyu-core 0.2.3`，本地 mingyu 是 `0.4.0`，baseline 文档 pin 的是 0.4.0。见 TODO B2。

8. **`codeUnitAt` vs `charCodeAt` 在代理对字符上可能分叉（未验证）** —— `_hashSeed` 逐码元哈希，Dart 的 `codeUnitAt` 与 JS 的 `charCodeAt` 都是 UTF-16 码元，BMP 内字符等价；但 emoji 等增补平面字符由代理对构成，两者行为是否一致**尚未实测**。若未来允许用户用 emoji 当种子，可能出现同种子跨平台不同结果。见 TODO A9。

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
