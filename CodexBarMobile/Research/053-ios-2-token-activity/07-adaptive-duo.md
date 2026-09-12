# Adaptive layout preparation and Duo-size previews

Status: done (local adaptive layout preparation; Duo-specific validation pending)
Branch: feature/ios-adaptive-duo-preview, based on build 201 heatmap fixes.

User approved: outer compact single column; roomy portrait two-column provider cards and bottom navigation; roomy landscape Usage/Settings master-detail and trailing navigation; Cost summary/provider share beside token and spending charts. Preserve selected provider, account, date and navigation through resizing. Screenshots required for every pose and main destination.

No Duo SDK/runtime is installed (Xcode 26.6/iOS 26.5); all render sizes are illustrative container sizes, not claimed Duo hardware dimensions. Production uses available width/height and Dynamic Type, never model names. Keep narrow phone landscape compact. Native NavigationSplitView owns master/detail transitions; stable TabView selection owns navigation. Existing SDK trailing SwiftUI navigation is a fallback, pending actual Duo system bar/hinge verification.

Render actual ContentView with synthetic data in a contained hosting window, using the same wrapper as Xcode #Preview. Test compact portrait/landscape, roomy portrait/landscape, narrow split width, large type, empty state and dark mode. No private CloudKit writes, real account data or SDK installs. Hardware fold/safe-area behavior remains unverified.

## Implementation and evidence — 2026-09-11

Build remains 2.0.0 (201), not uploaded. Uses content width/height and accessibility text size; no hardware-name checks. Usage and Settings retain NavigationSplitView identity across resize. Cost uses AnyLayout with stable children. Existing provider linkage actions remain available. The trailing navigation is an existing-SDK fallback, not a Duo system bar implementation.

Screenshot gallery: [24 actual SwiftUI renders](evidence/adaptive/index.html). Eight poses times Usage/Cost/Settings: compact portrait/landscape, roomy portrait/landscape, narrow split, dark, accessibility text and empty. These are synthetic data, not owner-account sync evidence. Main four poses were visually inspected; additional accessibility/dark/empty samples checked. Ordinary compact layout stays single column.

Validation:
- `xcodebuild ... -only-testing:CodexBarMobileTests test`: 745 Swift Testing cases in 49 suites and 41 XCTest cases passed. Log `/tmp/cbm-duo-closeout.log`; result `/tmp/cbm-2-build/Logs/Test/Test-CodexBarMobile-2026.09.11_17-43-23--0700.xcresult`.
- Three ordinary iPhone UI tests passed: overview navigation/long press, history scroll/back-to-today, Settings usage toggle. Log `/tmp/cbm-duo-final.log`.
- Generic iPad simulator resize test passed with explicit window-orientation waits: select Codex, rotate portrait, preserve detail, open Usage Setting, rotate landscape, select Cost via trailing navigation. Log `/tmp/cbm-duo-resize-final.log`; result `/tmp/cbm-duo-ipad/Logs/Test/Test-CodexBarMobile-2026.09.11_17-44-48--0700.xcresult`. XCTest emitted animation-idle timeouts and eventually passed in 206 seconds: functional evidence only, not a smoothness/performance claim.
- Initial navigation test uncovered inherited accessibility identifiers on rail buttons. Added containment grouping; individual button IDs now pass UI automation.
- Preview initialization now explicitly skips history/account persistence hydration. Production initializer defaults to hydration as before. Regression case passes.
- `python3 Scripts/audit_localized_keys.py CodexBarMobile/CodexBarMobile/Localizable.xcstrings CodexBarMobile/CodexBarMobile`: all 330 source keys present. New release note translated in all four languages and added to the existing 2.0.0 block and ASC metadata files.
- `bash Scripts/check_ci_policy.sh` and `git diff --check`: passed. Focused new-file SwiftLint passed; ContentView retains pre-existing monolithic-file complexity/length and long-string warnings, so whole-file strict lint is not claimed clean.
- Self-review covered view identity, narrow-screen navigation, linkage action preservation, preview isolation and state preservation. No known blocking code defect identified. No remote CR run or merge performed.

## Scope and remaining verification

No Mac, Shared payload, CloudKit schema, production history retention or merge arithmetic changes. This layout-only increment changes placement of existing rendered data, not its decoding/interpretation. The prior 2.0 data compatibility matrix remains recorded in 03-testing; these screenshots do not replace it or claim any additional physical-device combinations.

Apple's https://developer.apple.com/iphone-duo/ still lists Xcode 27.1 beta as coming later this month on this date. Local Xcode 26.6/iOS 26.5 cannot validate Duo-specific API, system bars, hinge/safe areas, physical folding or actual inner/outer display transitions. Those remain pending the supported SDK/runtime. No SDK installation, push, PR, merge or TestFlight upload was performed for this increment.
