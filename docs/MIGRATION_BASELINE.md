# 昭星斋迁移基线

## 上游职责

- `mingyu`：算法、数据结构、随机重放、证据分析和兼容性测试的唯一基准。
- `sydf`：产品信息架构、页面流程和交互体验的参考，不作为算法真值来源。

## 当前锁定版本

| 项目 | 版本/提交 | 本地路径 |
| --- | --- | --- |
| mingyu | `0.4.0` / `878958f86be2e9d0bafa3cb9084452b9ffbd750a` | `E:/newProject/githubsm/mingyu` |
| sydf | `ffd2961affd7d05fb9df8a479f6fb2da9a4f42c1`，其依赖 `mingyu-core 0.2.3` | `E:/newProject/githubsm/sydf` |

后续移植默认对照上述 `mingyu 0.4.0`。如升级上游，必须先更新本文件并重新执行对应的兼容性测试。

## 当前模块状态

| 模块 | 状态 | 说明 |
| --- | --- | --- |
| shared/random | 已迁移 | 支持 system、seed、custom、replay；继续对照上游随机向量测试 |
| 小六壬 | 基础迁移完成 | 两种规则、东八区口径、干支、meta、evidence、UI 与兼容性测试已接入 |
| 塔罗 | 基础迁移完成 | 78 张牌、18 种牌阵、seed/replay、手动录牌引擎、证据分析、UI 与测试已接入 |
| 历史记录 | 基础能力完成 | 小六壬与塔罗自动保存；Android/Web 本地持久化、去重、删除和清空已接入 |
| 历法基础 | 迁移中 | IANA 历史时区和 DST 已使用 timezone 数据库；真太阳时与中国夏令时仍需补齐上游测试 |
| 其他术式 | 未开始 | 按蓍草、灵签、梅花、六爻，再到复杂排盘的顺序推进 |

## 数据同步

运行：

```bash
node scripts/export_data.js
```

脚本会直接读取本地 mingyu 的 `tarot-data.ts`，生成 Flutter 使用的 `assets/data/tarot.json`，避免手工复制导致漂移。

## 验收原则

每个迁移模块必须同时具备：

1. 明确的上游源文件和版本；
2. 与上游同输入、逐字段可比较的测试；
3. 边界与非法输入测试；
4. UI 可达入口；
5. README 中准确的完成状态。
