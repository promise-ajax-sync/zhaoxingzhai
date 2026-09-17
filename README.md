# 昭星斋（Zhaoxingzhai）

昭星斋是一个 Flutter 东方术数与占卜应用。算法、数据结构和兼容性测试以本地 `mingyu 0.4.0` 为基准，产品结构与交互参考 `sydf`。

> 所有排盘与占卜结果仅供传统文化研究和休闲参考，不构成医疗、心理、法律、投资等专业建议。

## 当前状态

当前是可演示的 Alpha：应用外壳、案例/历史地基以及小六壬、塔罗两个样板术式已经落地；其余导航入口多数仍为占位页。首页 AI 输入、今日运势、渠道选择和功德箱目前只有交互外壳，不包含真实服务。

产品外壳：

- 15 个一级入口，宽屏固定侧栏、窄屏抽屉导航
- 顶栏、案例入口和独立历史抽屉
- 对话优先首页、今日运势占位条和统一主题 token
- 未实现入口统一显示占位页，不伪装成已完成业务

已经接入应用导航的功能：

- 三山国王灵签
  - 92 签完整签谱
  - 随机抽签和手动签号查询
  - seed/replay、算法版本、案例快照和历史记录

- 小六壬时间起课
  - 通行掌诀与《多能鄙事》两种规则
  - 固定东八区民用时间口径
  - 农历、四柱干支、计算轨迹、结果 meta 与结构化 evidence
- 塔罗占卜
  - 78 张塔罗牌
  - 与 mingyu 0.4.0 同步的 18 种牌阵
  - 自动抽牌与实体牌手动录入页面
  - 正逆位、seed/replay 随机轨迹和证据分析

基础能力：

- 案例库：案例可新建、编辑、删除，并作为当前占卜主体被引用
- 历史记录保存**案例快照**与算法版本：修改或删除案例不会改变已有历史
- 小六壬与塔罗结果自动保存，提供当前设备本地历史记录
- IANA 历史时区与 DST 歧义/跳时识别
- 中国 1986—1991 夏令时与真太阳时基础代码
- 八卦、六十四卦、干支和塔罗 JSON 数据加载
- Android 和 Web 构建

### 案例与历史的关系

案例是可反复使用的**占卜主体**，历史是一次次**占卜结果**，两者互不串用：

- 案例页只管理主体，不展示任何结果。
- 历史记录保存计算当时的**案例快照**，不是案例引用。修改或删除案例后，
  旧历史仍显示当时的资料。
- 快照字段缺失时取缺省值，不会回退到当前案例补齐。
- 每条历史记录都带 `algorithmId` / `algorithmVersion` / `schemaVersion`，
  用于判断旧结果能否被当前实现 replay。

## 运行

```bash
flutter pub get
flutter run
```

检查项目：

```bash
powershell -ExecutionPolicy Bypass -File scripts/verify_foundation.ps1
```

只做分析和测试、不构建产物时追加 `-SkipBuild`。

从本地 mingyu 重新同步塔罗牌面、牌阵和关键词数据：

```bash
node scripts/export_data.js
```

### Android Release 签名

正式发布前，将 `android/key.properties.example` 复制为
`android/key.properties`，并填写上传密钥信息。真实的 properties 文件和
keystore 已加入忽略规则，不应提交到版本库。未配置密钥时，Debug 构建不受
影响，Release 产物不会使用 Flutter 的共享调试密钥签名。

## 项目结构

```text
lib/
├── app/                    应用外壳与导航
├── core/
│   ├── calendar/           历法、时区、夏令时和真太阳时
│   ├── data/               JSON 数据加载
│   ├── engine/             与 UI 无关的术式算法
│   ├── models/             案例、快照与算法身份模型
│   ├── shared/             随机、结果协议和验证
│   ├── theme/              统一主题与设计 token
│   └── widgets/            通用组件
└── features/
    ├── cases/              案例库与全局案例选择
    ├── history/            历史记录仓储与页面
    ├── home/               功能首页
    ├── xiaoliuren/         小六壬页面
    └── tarot/              塔罗引擎与页面
```

迁移版本、上游提交和验收原则见 [`docs/MIGRATION_BASELINE.md`](docs/MIGRATION_BASELINE.md)。

## 后续计划

1. 固化静态分析、测试、Web/Android 构建和跨平台随机验证；
2. 扩充小六壬和塔罗的边界向量，并固定 Web 随机回归；
3. 建立统一数据导出流水线，用灵签或每日一卦验证第三个完整术式；
4. 将案例和历史从 SharedPreferences 迁到 Drift/Isar，并补设置、主题和详情页；
5. 再依次迁移梅花、六爻及奇门、八字、紫微等复杂模块。

算法的实际完成边界见 [`docs/ALGORITHM_STATUS.md`](docs/ALGORITHM_STATUS.md)。

## 上游与许可证

- mingyu：<https://github.com/Brhiza/mingyu>
- sydf：<https://github.com/Brhiza/sydf>

本项目包含从 mingyu 移植和改写的代码，按照 GNU AGPL-3.0-only 发布，详见 [LICENSE](LICENSE)。
