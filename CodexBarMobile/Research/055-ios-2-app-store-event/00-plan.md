# 055 — iOS 2.0 App Store 版本与 Token Activity 活动

状态：draft。App Store 2.0.0 版本已创建并写入四语言更新说明；活动与版本发布分开处理。此前两轮 Heatmap 活动草图均被否决，已从发布分支移除，尚未创建或送审活动。

## App Store 2.0.0

- App Store Connect version ID：`0dff79b3-74c6-4747-9022-34c0e70e81e9`。
- 状态：`WAITING_FOR_REVIEW`；发布方式：`MANUAL`（审核通过后仍需手动发布）。
- `en-US`、`zh-Hans`、`zh-Hant`、`ja` 更新说明已通过 API 写入并逐项回读一致。
- 更新说明优先级：iOS 27 / iPadOS 27、全新数据架构与显著性能提升、Token Activity Heatmap、iPad 宽屏布局、分享卡片重构。
- build 211 已归档、上传并处理为 `VALID`，已绑定此 2.0.0 version 且自动出现在 Internal TestFlight group；已于 `2026-09-15T00:56:50.480Z` 通过 App Store Connect API 创建 review submission `81f04f3d-9dbe-4338-95cd-afe28590d240`，提交项为 version 2.0.0 / build 211，当前 `WAITING_FOR_REVIEW` / `MANUAL`。build 203 使用 Xcode 26.6 / iOS 26.5 SDK，保留为历史 Internal TestFlight build；build 204 至 210 因后续 PR 审查修复而淘汰。

## Token Activity In-App Event

- Apple 对活动卡要求 16:9、1920×1080 起；详情页要求 9:16、1080×1920 起。最终视觉方向尚未确认。
- 用户要求活动素材只使用实际的 Token Activity Heatmap 控件，避免额外的榜单、手机模型或旧 Widget 拼贴；需要先取得认可的视觉参考再继续设计。
- 拟定 badge：`MAJOR_UPDATE`；purpose：`ATTRACT_NEW_USERS`；purchase requirement：`NO_COST_ASSOCIATED`；priority：`HIGH`。
- 拟定排期：2026-09-16 00:00 PDT 开始，2026-09-30 23:59 PDT 结束；正式创建前仍可调整。
- 拟定主文案：`Token Activity Heatmaps` / `See a year of AI activity`。
- 活动 review item 必须提供可用 deep link。当前 `VALID` build 仅处理 `codexbar://widgets`；活动需要新增并验证 `codexbar://cost`，进入新的 `VALID` build 后才能送审。活动对象与 2.0.0 App Store version 独立，但这个 deep-link build gate 不能省略。

## 下一步

1. 用户提供或确认横图和竖图的视觉参考。
2. 完成四语言活动文案与最终素材，增加 `codexbar://cost` 并以一个后续 build 验证。
3. 创建活动草稿、上传素材并以 `assetDeliveryState=COMPLETE` 回读。
4. 活动送审与 2.0.0 版本送审分别执行并分别报告状态。
