# 2.0 内测热力图反馈修订

Status: done (local implementation and validation; not uploaded)
Branch: fix/ios-token-heatmap-layout; base: 7adb360d0.

用户明确更正前一轮需求：Cost 外层必须是每日跨 Provider Token 合计热力图，不能只显示 Recorded tokens。详情全部 Provider 默认展开，名称在图上方放大，去掉左侧固定空白列。保留长按查看每日数据。最后一句左右操作为语音转写错误，不实施。

代码审计：原 grid 单格18pt、间隔4pt，一屏约四个月；固定10M最高颜色档导致高用量用户颜色饱和。修订为12pt格子、3pt间隔，完整365天仍可滚动。按整年正值日的四分位数着色（不按当前可见月份重新计算）；同值同色，0与未知保持不同。总图蓝色，单 Provider 沿用其颜色。

总图与详情共享已加载 series、dailyTotals/total：按日求和，不读取第二份数据库、不修改Mac/Shared/wire/schema。部分已知保留下界，未知不当作0；不提供Token的Provider沿用已有过滤。

验证计划：高用量与极端离群值分档，按日总图与分项一致、未知与0；模拟器 Cost → 详情、全展开与长按、全年横向滚动；四语言、构建和现有数据回归。兼容矩阵沿用03-testing旧新payload合成用例并复跑；不宣称完成真实两Mac历史费用对账。

## Build 201 validation
- 2.0.0 (201), all targets regenerated with xcodegen.
- Full suite: /tmp/cbm-heatmap-tests.log, 745 tests / 49 suites passed. Initial UI navigation failure was fixed with a full-row contentShape.
- Final: /tmp/cbm-heatmap-final.log, 15 TokenActivity tests and 2 UI tests passed; TEST SUCCEEDED. Result: /tmp/cbm-2-build/Logs/Test/Test-CodexBarMobile-2026.09.11_16-50-44--0700.xcresult.
- Inspected screenshots: evidence/build-201-cost-heatmap.png and evidence/build-201-expanded-providers.png. All providers are expanded, titles above full-width grids. Long press, selected date, scrolling and return-to-today passed. Synthetic fixtures only.
- Strict SwiftLint, four-locale checks, 330 source-key audit, diff check and CI policy passed. Self-reviewed diff; no remote CR claimed.
- Same-version in-app and AppStoreMetadata notes updated in four locales. No push or upload; TestFlight remains build 200.
- No Mac, Shared, CloudKit or persistence changes. Physical multi-device/history reconciliation remains unverified as documented in 03-testing.md.
