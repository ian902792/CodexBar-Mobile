# 055 — iOS 2.0 App Store 版本与 Token Activity 活动

状态：draft。App Store 2.0.0 版本已创建并写入四语言更新说明；Heatmap 活动素材等待用户视觉确认，尚未创建或送审活动。

## App Store 2.0.0

- App Store Connect version ID：`0dff79b3-74c6-4747-9022-34c0e70e81e9`。
- 状态：`PREPARE_FOR_SUBMISSION`，发布方式：`MANUAL`。
- `en-US`、`zh-Hans`、`zh-Hant`、`ja` 更新说明已通过 API 写入并逐项回读一致。
- 更新说明优先级：iOS 27 / iPadOS 27、全新数据架构与显著性能提升、Token Activity Heatmap、iPad 宽屏布局、分享卡片重构。
- 当前未绑定 build，也未创建 review submission。现有 build 203 使用 Xcode 26.6 / iOS 26.5 SDK；在正式宣称 iOS 27 / iPadOS 27 支持并送审前，需要用 Xcode 27 RC 和 iOS 27 runtime 重新构建及验证。

## Token Activity In-App Event

- Apple 对活动卡要求 16:9、1920×1080 起；详情页要求 9:16、1080×1920 起；当前草图已按最低正式规格输出且无 Alpha。
- 设计以 2.0 的 Token Activity 分享卡片为主体：全年两段 Heatmap、Recorded tokens、Active Days、Peak Day；不使用手机模型或旧 Widget 拼贴。
- 横图左侧保留 App Store 活动标题安全区，右侧展示完整 Heatmap 分享卡片；竖图将同一分享卡片居中放大。
- 拟定 badge：`MAJOR_UPDATE`；purpose：`ATTRACT_NEW_USERS`；purchase requirement：`NO_COST_ASSOCIATED`；priority：`HIGH`。
- 拟定排期：2026-09-16 00:00 PDT 开始，2026-09-30 23:59 PDT 结束；正式创建前仍可调整。
- 拟定主文案：`Token Activity Heatmaps` / `See a year of AI activity`。
- 活动 review item 必须提供可用 deep link。当前 `VALID` build 仅处理 `codexbar://widgets`；活动需要新增并验证 `codexbar://cost`，进入新的 `VALID` build 后才能送审。活动对象与 2.0.0 App Store version 独立，但这个 deep-link build gate 不能省略。

## 当前素材

- `draft-heatmap-event-card.png`：待上传的无文字横图。
- `draft-heatmap-event-detail.png`：待上传的竖图。
- `draft-heatmap-event-card-preview.png`：仅用于模拟 App Store 标题叠加效果，不上传。
- `generate_heatmap_event.py`：可重复生成三张图的确定性脚本。

## 下一步

1. 用户确认横图和竖图的视觉方向。
2. 完成四语言活动文案与最终素材，增加 `codexbar://cost` 并以 Xcode 27 RC 验证。
3. 创建活动草稿、上传素材并以 `assetDeliveryState=COMPLETE` 回读。
4. 活动送审与 2.0.0 版本送审分别执行并分别报告状态。
