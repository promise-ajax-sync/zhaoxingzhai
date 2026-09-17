# sydf 项目分析与可复用边界

> 基准仓库：`githubsm/sydf`
>
> 当前项目版本：`0.1.0`
>
> 核心依赖：`mingyu-core 0.2.3`
>
> 目标项目：Flutter `zhaoxingzhai`
>
> 本文用途：确定 sydf 中哪些产品结构和交互可以作为 Flutter 目标，哪些实现可以借鉴，哪些源码、文案和品牌资产不能直接复制。

## 1. 项目定位

sydf 是一个使用 Vue 3、Vite 和 Capacitor 构建的完整术数产品。它以 `mingyu-core` 为底层算法，自己负责：

- 页面与导航。
- 案例管理。
- 历史记录。
- AI 渠道和模型。
- Agent 工具选择。
- 今日运势等业务组合。
- 传统黄历和个人历。
- 主题、品牌与卡面资产。
- PWA、离线资源和 Android 更新。
- 移动端适配。

sydf 的主要价值是产品流程与业务编排，而不是替代 mingyu 的底层算法。

## 2. 项目结构

```text
sydf/
├─ src/
│  ├─ App.vue             全局状态、路由和业务编排
│  ├─ components/         业务页面和通用 UI 组件
│  ├─ lib/                产品业务逻辑
│  ├─ design-system/      设计变量和基础样式
│  ├─ directives/         Vue 指令
│  └─ main.ts             启动、更新和原生运行时
├─ functions/
│  ├─ api/                AI、模型和应用更新 API
│  └─ shared/             AI 供应商、安全和请求逻辑
├─ public/                PWA、主题、Logo、卡牌与图片资源
├─ android/               Capacitor Android 工程
└─ build/                 主题资产构建
```

当前主要规模：

- `src/lib`：约 105 个文件、17,281 行。
- `src/components`：约 55 个文件、10,844 行。
- 测试：约 57 个文件、5,358 行。
- `App.vue`：约 7,200 行，是明显的集中式应用控制器。

## 3. 产品信息架构

sydf 定义了 15 个一级入口：

| 路由 | 页面 |
|---|---|
| `tools` | 首页/AI 问答入口 |
| `charts` | 排盘 |
| `compatibility` | 合盘 |
| `oracle` | 灵签 |
| `xiaoliuren` | 小六壬 |
| `daily-hexagram` | 每日一卦 |
| `fortune` | 今日运势 |
| `almanac` | 传统黄历和个人历 |
| `fengshui` | 居家风水 |
| `tarot` | 西方占卜 |
| `name-number` | 姓名与数字 |
| `zhuge` | 诸葛神数 |
| `kongming` | 孔明神卦 |
| `cases` | 案例 |
| `settings` | 设置 |

二级结构包括：

- 案例：输入案例、案例记录。
- 设置：偏好、主题、AI。
- 全局历史：作为独立抽屉或路由状态存在。

本项目确立：案例与历史必须是两个独立概念。

## 4. sydf 与 mingyu-core 的职责边界

### 4.1 主要由 mingyu-core 提供

- 梅花易数。
- 六爻。
- 三山国王灵签底层抽签与签数据接口。
- 小六壬。
- 金口诀。
- 奇门遁甲。
- 大六壬。
- 太乙神数。
- 五运六气。
- 皇极经世。
- 黄历择日基础。
- 八字。
- 紫微斗数。
- 西方星盘。
- 七政四余。
- 塔罗。
- 雷诺曼。
- 历法、地区、时区和真太阳时。

### 4.2 主要由 sydf 自己提供

- 首页对话体验。
- 工具选择与 Agent 路由。
- 案例 CRUD 和全局选中案例。
- 案例快照。
- 历史记录迁移与恢复。
- 今日运势的产品组合算法。
- 每日一卦的日期产品逻辑和方向文案。
- 个人历。
- 居家风水编辑器。
- AI 渠道、模型、超时、取消和失败降级。
- 外部 AI 分享。
- 主题系统和卡面资产管理。
- PWA、离线缓存和应用更新。
- Android 容器适配。
- 设计系统和响应式 UI。

因此，复刻 sydf 功能时必须同时查看 sydf 业务层与 mingyu-core 算法层。

## 5. 可以复制为“产品要求”的内容

以下内容可以转写为 `zhaoxingzhai` 自己的需求和验收标准：

- 侧栏与顶栏的信息架构。
- 15 个一级功能入口。
- 窄屏抽屉、宽屏固定侧栏的响应式行为。
- 首页默认态与聊天态的状态转换。
- 案例和历史分离。
- 案例支持公历/农历、性别、时间和地区。
- 两人合盘至少需要两个不同案例。
- 历史记录保存当时的案例快照。
- AI 请求可以取消，旧请求不能覆盖新结果。
- AI 不可用时可以复制 Prompt 到其他 AI。
- 重型算法和数据按需加载。
- 盘面缓存需要上限，并在案例资料变化时失效。
- 离线时保留本地可计算功能。
- 主题支持浅色、深色和画风资产。
- 所有术式结果可保存、恢复和继续解读。

这些是产品行为，不要求复制 Vue 源码。

## 6. 可以借鉴并在 Flutter 中重新实现的工程方案

### 6.1 应用外壳

sydf：

```text
侧栏 + 顶栏 + 内容区 + 全局历史 + 对话框
```

Flutter：

```text
AppShell
├─ AppRouter/AppView
├─ ResponsiveSidebar
├─ AppTopBar
├─ FeatureHost
├─ HistoryDrawer
└─ Dialog/Navigator service
```

可以保持相同信息架构，但不复制 Vue 模板和 CSS。

### 6.2 案例快照

可采用相同业务原则：

- 当前案例用于新计算。
- 历史记录保存计算当时的完整案例快照。
- 修改或删除当前案例不改变旧历史。
- 历史缺失字段时不能偷偷用当前案例补齐。

### 6.3 可取消异步任务

sydf 使用 `AbortController` 和 generation token。Flutter 应重新实现为：

- 请求 ID。
- 取消令牌。
- StreamSubscription 取消。
- 页面销毁后忽略旧结果。
- AI 流式请求在离开页面时中止。

### 6.4 有界缓存

可采用：

- 盘面缓存数量上限。
- 按案例资料签名失效。
- 只缓存可重建结果。
- 图片缓存限制内存和磁盘容量。
- 主题切换时停止旧主题预热。

### 6.5 算法、证据与 AI 分层

```text
AlgorithmResult
    ↓
EvidenceModel
    ↓
PromptBuilder
    ↓
AiRepository
    ↓
ReadingHistory
```

可以采用这套层次，但 Prompt 和解释文案应重新编写。

## 7. 不能直接复制的内容

### 7.1 Vue/TypeScript 源码

在独立 Flutter 实现路线下，不直接复制：

- `App.vue` 的逻辑和模板。
- Vue 组件脚本。
- CSS 选择器和整套样式源码。
- 本地存储迁移函数的逐行翻译。
- AI Provider、Agent 和请求函数的逐行翻译。
- 测试文件的逐行翻译。

应提炼行为后，用 Dart/Flutter 架构重新实现。

### 7.2 品牌内容

不直接复制：

- “时月东方”名称。
- sydf Logo。
- 功德箱链接和其品牌语境。
- 独有插画。
- 自定义塔罗牌面。
- 主题 Logo 和主题图片。
- 页面中的品牌文案。

`zhaoxingzhai` 应使用“兆星斋”的独立品牌资产。

### 7.3 文案、Prompt 和语料

不直接复制：

- 长篇 AI 系统 Prompt。
- 解答偏好的完整说明文本。
- 今日运势语料库。
- 每日一卦方向建议原文。
- 黄历现代建议原文。
- 风水建议文本。
- 错误提示和帮助说明的大段表达。

可以保留相同功能目标，但应重新设计表达和生成规则。

### 7.4 主题数值和完整视觉表达

可以借鉴“语义 Token + 浅深色 + 画风资产”的方法，但不应把六套主题的全部色值、图片、渐变和视觉组合原样复制为闭源产品。

本项目应建立自己的：

- 色彩系统。
- 字体。
- Logo。
- 图标组合。
- 插画。
- 动效。
- 品牌文案。

## 8. UI 可参考范围

### 8.1 可以采用的通用布局模式

- 移动端抽屉导航。
- 桌面端固定侧栏。
- 顶栏标题和操作区。
- 首页 Hero。
- 底部或浮动问题输入框。
- 分段控制器。
- 空状态。
- 表单卡片。
- 结果卡片和阅读区。
- 对话消息列表。
- 历史抽屉。

### 8.2 应做出独立差异的部分

- 颜色和渐变。
- Logo 和头像。
- 组件圆角与阴影组合。
- 导航图标。
- 标题文案。
- 首页布局比例。
- 功能入口动效。
- 卡牌和灵签视觉资源。

目标是功能和信息层级一致，而不是像素级复制 sydf 品牌。

## 9. sydf 主要业务模块与 Flutter 映射

| sydf 模块 | Flutter 目标 |
|---|---|
| `App.vue` | 拆为 AppShell、路由、Controller 和 Repository |
| `appRoute.ts` | `AppView` + Router 状态 |
| `divination.ts` | `DivinationService` |
| `caseProfile.ts` | `CaseProfile` 模型与校验 |
| `caseSelection.ts` | 全局案例选择 Controller |
| `readingProfile.ts` | 不可变案例快照 |
| `dailyFortune.ts` | 独立 `DailyFortuneEngine` |
| `dailyHexagram.ts` | `DailyHexagramEngine` |
| `almanac.ts` | `AlmanacService` |
| `personalAlmanac.ts` | `PersonalAlmanacEngine` |
| `ai.ts` | `AiRepository` |
| `aiProvider.ts` | AI Provider 配置和请求适配器 |
| `agent.ts` | 受限工具路由器 |
| `divinationTheme.ts` | `ThemeExtension` + 自有资产主题 |
| `localStorage.ts` | 数据库、偏好与安全存储 |
| `cardImageCache.ts` | 有上限的图片预热和磁盘缓存 |
| `appUpdate.ts` | Flutter 平台更新策略 |

## 10. Flutter 数据存储决策

sydf 主要依赖 `localStorage` 和 `sessionStorage`。Flutter 不照搬这种方案。

| 数据 | Flutter 存储建议 |
|---|---|
| 主题、显示偏好 | SharedPreferences |
| AI API Key | `flutter_secure_storage` |
| 案例 | SQLite/Drift/Isar |
| 历史记录 | SQLite/Drift/Isar |
| 大型排盘结果 | 数据库或文件缓存 |
| 图片和主题资产 | 有上限的磁盘缓存 |
| 临时会话 | 内存状态，必要时保存草稿 |

所有持久化模型都需要：

- `schemaVersion`。
- `algorithmId`。
- `algorithmVersion`。
- 创建和更新时间。
- 可恢复的迁移策略。

## 11. Flutter 页面生命周期决策

sydf 已经使用取消请求和释放监听器来避免泄漏。Flutter 必须继续遵守：

- `TextEditingController`、`FocusNode`、`ScrollController` 必须释放。
- Timer 必须取消。
- StreamSubscription 必须取消。
- 页面销毁后不得无条件 `setState`。
- AI 请求离开页面时中止或转入明确的后台任务管理器。
- 图片预热必须可取消。
- 大型数据不得由永久单例无限缓存。
- 重型页面不默认全部放入永久 `IndexedStack`。

## 12. sydf 架构中不应复制的问题

### 12.1 超大 `App.vue`

`App.vue` 约 7,200 行，承担路由、案例、缓存、AI、历史、更新和页面业务。Flutter 不采用同样的超级状态类。

### 12.2 存储过度依赖单个 JSON

复杂历史和盘面长期使用 localStorage 会产生整体序列化、容量和迁移压力。Flutter 从开始就使用结构化数据库。

### 12.3 UI 与业务文案耦合

今日运势等模块混合了计算、语料和展示。Flutter 应拆为：

```text
信号计算 → 结构化结果 → 文案生成 → Widget 渲染
```

### 12.4 固定 mingyu-core 旧版本

sydf 使用 `0.2.3`，本地 mingyu 为 `0.4.0`。Flutter 不混合摘取两个版本的代码；每项能力都要记录行为基准和差异。

## 13. 当前确立的可复用清单

| 内容 | 决定 |
|---|---|
| 15 个入口与分组 | 可作为产品信息架构 |
| 响应式侧栏/抽屉 | 可重新实现 |
| 首页默认态/聊天态 | 可作为交互规格 |
| 案例与历史分离 | 必须采用 |
| 案例快照 | 必须采用 |
| 有界排盘缓存 | 可以采用 |
| 请求取消和旧结果隔离 | 必须采用 |
| 算法/evidence/Prompt 分层 | 可以采用 |
| AI 失败时复制 Prompt | 可以采用 |
| PWA/Android Capacitor 代码 | Flutter 不需要迁移 |
| Vue 组件和 App.vue 源码 | 不直接复制 |
| 品牌 Logo、主题图和卡面 | 不直接复制 |
| Prompt 与现代解释文案 | 重新编写 |
| localStorage 架构 | 不照搬 |

## 14. 功能实现优先级

### 第一阶段：产品地基

1. 完成独立品牌的 AppShell、侧栏和顶栏。
2. 建立案例数据库和案例快照。
3. 将案例与历史页面分离。
4. 建立算法版本和历史模型。
5. 建立 AI Provider 接口与安全密钥存储。

### 第二阶段：完整闭环

选择一个低风险功能完成：

```text
输入 → 算法 → 结果 → AI → 历史 → 恢复
```

建议顺序：

1. 小六壬。
2. 塔罗。
3. 每日一卦。
4. 梅花易数。
5. 三山国王灵签。

### 第三阶段：日常工具

- 今日运势。
- 传统黄历。
- 个人历。
- 姓名与数字轻量功能。

### 第四阶段：命盘和复杂术式

- 八字。
- 紫微。
- 西洋星盘。
- 合盘。
- 风水。
- 奇门、大六壬、七政四余等。

## 15. 验收标准

每个参考 sydf 的功能必须至少满足：

1. 用户流程与需求文档一致。
2. 不依赖未授权品牌资产。
3. 算法来源和版本可追踪。
4. 案例数据和历史快照不会串用。
5. 异步旧结果不会覆盖新结果。
6. 页面退出后控制器、Timer、Stream 和请求正确释放。
7. 缓存有明确上限和失效条件。
8. Web、Android 和 iOS 的关键计算结果一致。
9. 离线能力和联网能力边界明确。
10. AI 失败时仍能查看盘面或复制结构化 Prompt。

## 16. 最终结论

本项目对 sydf 的复用定位为：

```text
复制产品目标和行为规格
借鉴工程思想
重新实现 Flutter 架构
重新设计兆星斋品牌视觉
重新编写 Prompt 和解释文案
算法回到独立规格与 mingyu 黑盒验证
```

也就是说，`zhaoxingzhai` 可以做到与 sydf 功能一致，但不需要、也不应成为 sydf Vue 源码的逐行 Flutter 翻译。

