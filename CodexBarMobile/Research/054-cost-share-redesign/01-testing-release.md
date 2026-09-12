# 054 — 测试与 TestFlight 证据

状态：in-progress。目标版本：iOS 2.0.0 (203)。分支：`feature/ios-cost-share-redesign`。

## 数据与同步边界

- Heatmap 只消费 `CostHistoryWorker.tokenActivity` / `snapshotTokenActivity` 返回的 `TokenActivitySeries`，再通过 `TokenActivity.dailyTotals` 投影选定窗口。没有直接读取或重复累加 Mac 原始 blob。
- 全部 Provider 使用同一批 series 合计；单一来源只筛选一个现有 series。确定为零、未知、部分下界继续由 `TokenActivityTotal` 区分。
- 本轮没有修改 `Shared/`、CloudKit record type/field/index/zone/subscription、payload 编解码、缓存写入或 Mac producer。相对基线 `3ecbcae2a` 的 schema 关键词审计和 Shared 路径审计均无输出，结论为 **CloudKit Production NO_DEPLOY**。
- 因为 wire/schema/cache/producer 与跨版本读取均未变化，本轮不重新触发 2 Mac × 2 iPhone 的 16 组合兼容矩阵。已有聚合回归仍在全量测试中运行，其中包含 16 组合 Today cost 矩阵；本轮新增 Token 投影测试覆盖未知、零、下界、两台 Mac 去重、重复更新及年度分块。

## 自动化结果

- `PATH=/opt/homebrew/bin:$PATH bash Scripts/lint.sh lint`：通过；SwiftFormat 0 个待格式化文件，SwiftLint 0 violations，四语言 354 个源 key 全部存在并 translated，CI/release policy guards 通过。
- iOS 全量单元测试：`CodexBarMobileTests` 共 746 tests / 49 suites，通过。
- 分享渲染测试：Classic / Vibe 的 Today、7 Days、30 Days 明暗模式，以及 Heatmap 明暗模式全部生成；固定输出为 1170×1560 px。无无效 SF Symbol 警告。
- Token Activity 定向测试：16 tests 通过；365 天上下两个连续区块合计 365 个唯一日期且顺序与原投影一致，总数和 lower-bound 语义保持。
- iPhone 17 Pro UI：分享编辑器、三个模板、Heatmap 范围与 Provider 菜单、可用分享按钮通过；点击按钮后回读到系统 `ActivityListView`，其中包含 Copy / Save Image；运行时截图确认卡片不会压住模板区。
- iPad 13-inch UI：竖屏和横屏均通过；全屏编辑器在宽窗口使用左预览、右设置，底部分享按钮可达。横屏用几何断言确认预览在设置区左侧。

## 人工视觉检查

- Classic：主金额、堆叠费用图、三项摘要、两列 Provider 图例和 QR footer 均在 3:4 画布内；六个来源不会再被压成一行。
- Vibe：去除旧式霓虹仪表盘，改为渐变海报、双指标和四个主要 Provider，明暗主题均可读。
- Heatmap：365 天使用两个连续区块并共享同一强度阈值；未知日期为虚线空格、确定零为弱实色、正数使用四档相对强度；90/180 天使用更大的格子。
- 编辑器：iPhone 上预览优先并纵向滚动；iPad 宽窗口双栏。预览和导出复用同一个 `CostShareCardView` 及同一数据投影。

## 发布记录

- Source commit：待最终提交后填写。
- Archive / IPA：待生成。
- App Store Connect build ID、处理状态、Internal 测试组和四语 What to Test：待上传回读。
