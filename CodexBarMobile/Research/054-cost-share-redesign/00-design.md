# 054 — Cost 分享编辑页与 Heatmap 模板

状态：in-progress。设计与实现已完成，当前以 PR #129 的 `release/ios-2.0-app-store` 上 build 210 作为唯一候选；build 203 至 209 均为历史或已淘汰构建，不能作为本轮交付物。完整测试、lint 和 CloudKit Production NO_DEPLOY 审计已记录在 `01-testing-release.md`；当前仍待最终 clean review、合并、归档、TestFlight 上传与 App Store Connect 绑定。
分支：最初实现来自 `feature/ios-cost-share-redesign`，从已完成 TestFlight 202 的本地 `3ecbcae2a` 派生，并保留 iPhone/iPad 底部导航规则；后续修复与发布准备均在 `release/ios-2.0-app-store` 进行。本轮沿用同一 2.0.0 更新说明，构建号为 210。

## 已审计的现状

- `Views/CostShareSheet.swift`：顶部连续两个 segmented Picker（Style / Period），下方 ScrollView 放卡片，底部大按钮。风格和时间控件占据首要位置；预览不按可用空间主动适配。
- `Models/CostShareService.swift`：Classic / Vibe 两种模板；当前实际范围为 Today / 7 Days / 30 Days，并无 Yesterday。渲染在 MainActor，失败时仍把 showingActivitySheet 设为 true，可能打开空白分享 sheet，应在本轮处理。
- `Views/CostShareCardView.swift` 和 `CyberShareCardView.swift`：现有导出画布固定 390×520pt（3:4，@3x 1170×1560）。预览应缩放同一画布，不能导出另一套布局。
- Cost 页传给分享页的只有 CostDashboardInsights；Token Activity 另走 TokenActivitySection / TokenActivity.series / ledger 路径。不能从 30 天费用柱状图推算 365 天 Token。
- 复用 `TokenActivity.dailyTotals`、`TokenActivityColorScale` 及已有账号/设备合并结果，保留 unknown、known zero、lower-bound 区别。
- 已读历史方案 `002-cost-share-card.md`。上游 PR 检索 `gh search prs --repo steipete/CodexBar 'share heatmap' --limit 5 --json number,title,url,state` 返回空；该检索未发现现成方案，不代表上游绝无相关工作。

## 方案：以预览为主体

iPhone 从上到下：简洁标题及关闭按钮 → 可完整看清的成品预览 → 三个带缩略图的模板选项 → 当前范围/来源的小型选择入口 → 固定底部系统分享按钮。

- 缩略图分别为 Classic、Vibe、Heatmap，选中态用清晰边框和文字；不能只以颜色区分，也不依赖左右滑动才能选择。
- 时间范围采用一个显示当前选择的菜单，例如“近 30 天 ⌄”；打开后有勾选项和实际日期范围，不再叠一整排 segmented control。
- Classic：现代简洁报告。金额为主、趋势为辅、Provider 占比紧凑。保留清楚的数值单位和可靠性标记。
- Vibe：更有个性的海报。克制的渐变/品牌点缀与更好的字体层级，减少霓虹装饰对数字的干扰。
- 编辑器用系统原生材质和按钮，卡片本身采用适合导出/跨背景阅读的实色设计；不把所有表面都做成玻璃。
- iPad 宽窗口：左侧大预览、右侧紧凑控制区；小窗口或大字体自动上下排布。主 App 的底部 Tab Bar 策略保持，分享 sheet 不引入另一套主导航。

## Heatmap：按天画，按 Provider 筛选

初始范围为近 365 天；提供 90 / 180 / 365 天。Classic / Vibe 保留代码中已有且有明确费用语义的 Today / 7 Days / 30 Days。本轮不新增 Yesterday，因为现有分享数据没有独立的昨日费用投影；不能用累计数相减伪造。Heatmap 使用独立范围，切换模板不会把 Today 变成仅一个点。

- 一个格子对应一天；颜色强度对应当日 Token 总量。初版不再加费用/Token 指标切换，避免与已有费用卡片重复并堆积选项。
- 默认“全部 Provider”，用 App 蓝色统一呈现每日合计。可以选择一个有 Token 数据的 Provider，使用其品牌色。
- 不把每个 Provider 的全年图全部堆进同一张图片。分享图应在聊天缩略图里仍能理解；缺乏 Token 数据的 Provider 不进入可选项，并用“已记录 Token”表达覆盖范围。
- 365 天导出为上下两个时间连续的日历区块，按整周列划分，每段约半年；日期不重复、不丢失，不错误标成自然年上下半年。每个区块有真实日期/月标注。
- 90 / 180 天可用单个日历区块。手机界面通过等比缩放显示完整成品；导出图片不能依赖横向滚动或截取当前 viewport。
- 顶部：Token Activity、所选日期范围、全部 Provider/指定 Provider。
- 主数字：该范围内已记录 Token 总数，下界用 ≥；辅助数字为已知活跃天数与已记录峰值日。缺失历史时不宣称完整连续打卡天数。
- 底部：相对强度图例、简洁缺失数据说明和低干扰 CodexBar 标识。未知与确定为零使用不同表现，不能把空历史绘成零。
- 颜色阈值在所选范围和来源确定后固定；上下两块共用阈值，异常高峰不能令其余天都一个颜色。相同计数必须同色。

## 数据与渲染约束

先建立不可变的分享输入/投影（建议 `CostShareSnapshot` / `HeatmapShareData`），捕获同一 referenceDate、日历、Provider 选择、已归并日数据和覆盖状态。分享编辑期间的新同步不应只更新卡片一部分；预览和导出使用同一份投影。

费用卡继续使用经过验证的费用计算；Heatmap 消费页面已有的 Token 聚合结果，不重新扫描/叠加 Mac 原始 blob。Yesterday 必须从对应日的记录计算，不能用两个累计总数相减；历史未知时明确显示未知。

纯数据准备尽量不阻塞主线程；ImageRenderer 按要求在 MainActor 使用。快速切换模板取消/丢弃过期准备结果，固定数量的可见缩略图不应每次重算全年数据。成功生成图片后才打开系统分享；失败给出四语言提示和重试操作。

现有 Shared 日字段足以支持方案，初步不需要 Mac 或 CloudKit schema 更新；实现时审计输入是否覆盖所有来源，若发现数据缺口需先给出明确证据。

## 实施和验收顺序

1. 确认本设计，先制作三模板的实际 SwiftUI 成品预览和编辑页；保留已有 3:4 画布，不随意更改现有分享尺寸。
2. 接通不可变投影与系统分享，完成全年 Heatmap、Provider 选择和失败处理；保留原有三个已验证费用范围。
3. 测试：图上 Token 总数=相同日期/来源的页面总数；多设备/多账号已归并结果不重复；跨午夜、时区/夏令时、缺失、零、下界、单天、空集、极端高峰、重复计数、长 Provider 名；365 天分块每一天恰好一次；切换控件后导出与预览一致。
4. 渲染：三个模板 × 范围 × 明暗色；iPhone 小屏和大屏、iPad 横竖屏/窄窗口、大字体；检查卡片完整缩放、控制区可达、分享弹窗锚定、长本地化字符串、失败重试和切换流畅性。静态 mockup 不算真实 UI 通过。
5. 所有新增文案四语言；更新同一 2.0.0 release notes 条目，准备下一 build 时再升级 build number；按适用的同步兼容 gate 记录替代与未实测风险。新的上传/PR/merge 按用户该阶段授权处理。

当前实现证据：三种模板共用 390×520pt 导出画布；Heatmap 的 365 天被无重复、无遗漏地拆成两个连续区块，两个区块共享同一强度阈值；演示模式使用显式示例投影，真实模式继续读取 `CostHistoryWorker` 的既有 Token 聚合结果。测试与发布证据记录在 `01-testing-release.md`。
