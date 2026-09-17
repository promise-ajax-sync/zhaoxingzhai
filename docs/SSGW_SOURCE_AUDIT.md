# 三山国王灵签数据源审计

## 当前决策

项目决定先使用 mingyu 0.4.0 当前完整数据推进功能，不再把来源核验作为开发阻塞条件。数据资产仍保留上游文件、版本和生成方式，方便后续替换或重新审计。

## 审计结论

mingyu 0.4.0 运行时使用的权威入口是：

```text
packages/core/src/divination/ssgw-data/index.ts
  -> SIGNS_FULL
  -> signs-full.ts
  -> enrichSsgwSign()
```

`signs-01.ts`、`signs-02.ts`、`signs-03.ts` 当前没有被运行时入口引用，不能作为 Flutter 导出的权威源。

文件包含 92 签的签诗、现代故事整理、现代解签总论和分类建议。当前已按项目决策导出使用，但仍未找到可独立核验的出版物、庙方页面、数据授权或许可说明。

## 已实现

- 1—92 签号校验。
- 手动指定签号。
- 使用项目随机系统从 92 签中抽取编号。
- seed/replay、算法版本和历史协议。
- 完整 92 签数据加载。
- 签诗、故事和增强解签展示。
- 历史记录与案例快照。

## 数据接入前置条件

后续若要重新核验或替换数据，可按以下路径处理：

1. 找到可公开使用的原始签谱，并记录书名、版本、页码或稳定网址；
2. 获得文本整理者或权利人的明确授权；
3. 只录入能够确认属于公共领域的原始签诗，并由本项目重新编写现代解签；
4. 将完整签谱放在独立联网服务中，并确认服务侧具备合法使用依据。

## 当前生成方式

```powershell
node --experimental-strip-types --experimental-transform-types `
  --experimental-loader ./scripts/reference/ts_extension_loader.mjs `
  ./scripts/export_ssgw_data.mjs
```

输出为 `assets/data/ssgw.json`，记录 mingyu 版本和实际运行时入口。
