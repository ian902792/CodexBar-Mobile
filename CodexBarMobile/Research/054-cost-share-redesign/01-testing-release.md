# 054 — 测试与 TestFlight 证据

状态：in-progress。目标版本：iOS 2.0.0 (204)。发布分支：`release/ios-2.0-app-store`。

## Build 204 发布替换验证（2026-09-14）

- build 203 保留为历史 Internal TestFlight 构建；本轮只会以 build 204 作为 iOS 27 / iPadOS 27 的候选交付物。
- `project.yml` 与生成后的 `.xcodeproj` 中主 App、Widget、Push Extension、Sync Extension 均为 `MARKETING_VERSION=2.0.0`、`CURRENT_PROJECT_VERSION=204`。
- 工具链：Xcode 27.0 (`27A266a`)、iOS 27.0 SDK (`24A430`)；在 iOS 27.0 Simulator runtime (`24A434`) 的 iPhone 18 Pro 上验证。首次下载的 runtime 未通过密封资源校验，已删除并重新下载；新设备可正常引导后才开始最终验证。
- 完整测试：`xcodebuild ... -scheme CodexBarMobile -destination 'platform=iOS Simulator,id=83278BCC-AE64-41F8-97A1-05CA13FA5CAE' -parallel-testing-enabled NO test` 返回 `TEST SUCCEEDED`。UI 套件 14 个执行、0 failure；6 个依赖已放置 Home Screen Widget 或 roomy 窗口的用例按测试前提跳过。结果包：`/Volumes/StudioSSD/Developer/BuildScratch/CodexBar/Xcode27/results/CodexBarMobile-iOS27-final.xcresult`。
- Heatmap 分享回归：iOS 27 下原先同时设置图片和 sheet 状态会偶发先呈现空 sheet。改为由带图片的 `ActivityPresentation` 驱动 `.sheet(item:)`，保证只有渲染完成后才显示系统分享面板。定向 UI 测试和完整 UI 套件均回读到 `ActivityListView`。
- `bash Scripts/lint.sh audit-i18n` 通过：四语言全部 translated，354 个 source key 全部存在；`git diff --check` 通过。
- CloudKit Production 审计：相对最近公开 tag `v0.58.0.1-mobile.1.23.0`，`CloudConstants.swift`、record type/field/index/zone/subscription、`providerPayloadVersion` 与新增非 optional shared 字段审计均无输出；本轮没有新 schema，结论为 **NO_DEPLOY**。

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

- Source commit：`70b39c7f0e70cccda5b50c5d6f2a6c894bb47354`（`feat(ios): redesign cost sharing cards`）。归档时工作树除既有未跟踪 `output/`、`tmp/` 外无变化。
- Archive：`/tmp/CodexBarMobile-2.0.0-203-share.xcarchive`，41 MB；归档内容清单 SHA-256 为 `0852047182f78a70a83bfb155b385526259550d48c9665bf134fbde9f210bc46`。
- 归档核验：主 App、Widget、Push Extension、Sync Extension 均为 `2.0.0 (203)`；`codesign --verify --deep --strict` 通过；主 App entitlement 的 `com.apple.developer.icloud-container-environment` 为 `Production`；归档图标和 App Store Connect 回传图标均人工确认正确。
- 上传：2026-09-11 21:55 PDT，`xcodebuild -exportArchive` 返回 `Upload succeeded` / `EXPORT SUCCEEDED`。该 upload destination 不在本地保留 IPA；可复现交付物为上述已核验 `.xcarchive`。
- App Store Connect：App `6760216772`，build ID `77b79982-fe71-4d1c-8a08-5c8c04d484cf`；build `203` 的 processing state 为 `VALID`，Internal 状态为 `IN_BETA_TESTING`，External 状态为 `READY_FOR_BETA_SUBMISSION`。
- Internal 分发：API 回读确认 build 203 已属于唯一的 `Internal` 测试组，`autoNotifyEnabled=true`。
- What to Test：`en-US`、`zh-Hans`、`zh-Hant`、`ja` 四个 locale 均已由 `AppStoreMetadata/2.0.0/*/release_notes.txt` 写入，并逐项回读验证内容完全一致。
- CloudKit：相对 `3ecbcae2a` 无 schema、Shared payload、producer、缓存写入或跨版本读取变化，Production schema 结论为 **NO_DEPLOY**。
