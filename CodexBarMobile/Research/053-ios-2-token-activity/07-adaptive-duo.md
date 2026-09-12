# Adaptive layout preparation and Duo-size previews

Status: done for native iPhone/iPad adaptation and TestFlight 202; Duo-specific SDK/device validation pending. Earlier results below are historical.
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


## Reopened: native navigation release verification

Status: in-progress. User authorized iPhone/iPad navigation and bottom clearance fixes, followed by TestFlight. Existing custom-window previews are not sufficient safe-area evidence. Validate full app on actual simulator device profiles, repeated push/back, tab state, orientation, last-content clearance, search/keyboard, and Settings. Preserve useful iPad columns. No Duo certification claim.


### Native release verification result

Status: code and local QA complete; TestFlight upload authorized, pending.

- Found and fixed a real search/resize bug: selecting a provider left search presentation active; keyboard occlusion changed the layout decision. Search now dismisses before selection. A keyboard-independent background measurement determines layout while actual content retains keyboard avoidance.
- `/tmp/cbm-native-final-phone.xcresult`: iPhone 17 Pro, 745 Swift Testing + 41 XCTest + 3 UI cases passed. Includes repeated provider push/back, tab restoration, rotation, final Usage footer above tab buttons, Settings navigation and token overview/provider history interaction.
- `/tmp/cbm-native-ipad-final.xcresult`: iPad Pro 13, passed. Portrait cards align in two columns; search selection dismisses keyboard; landscape search keeps the trailing navigation; selected provider and Settings destination survive rotation; Cost changes layout correctly.
- `/tmp/cbm-native-compact.xcresult`: iPhone 17e, repeated navigation/rotation/footer clearance case passed. No Duo runtime used.
- `/tmp/cbm-201-lint-final.log`: complete repository lint passed (portable guards, formatter, strict Sources/Tests SwiftLint and localization). Screenshot PNGs were losslessly compressed below the repository size limit; decoded RGBA equality verified for all 24 images. iOS ContentView retains its pre-existing monolithic strict-lint limitations described above.
- Native screenshots: `output/qa/native-navigation/`; temporary owner-requested sharing at https://subdivision-testament-msg-reprint.trycloudflare.com/native/ . Full-screen capture replaces cropped app capture after orientation transitions.
- Source AppIcon visually inspected, 1024 x 1024, no alpha. Archive and Apple CDN checks follow upload.
- CloudKit audit: Shared/schema/wire and production cache semantics unchanged; Production entitlement retained. No schema deploy or Mac update needed. Prior 16-case substituted matrix remains the limitation for real multi-device sync, not a claimed physical pass.
- Four-language 2.0 notes updated in the existing block; build 201 in all four project targets. No push/merge/PR or public release requested. Source self-review found no outstanding blocking issue after the search/keyboard fix.

## 202 — iPad navigation correction (done)

The user clarified that ordinary iPad must keep bottom tabs in both orientations. Build 201 had already been uploaded when this clarification arrived; it is superseded by 202, not a release acceptance result for this requirement.

Content columns and navigation placement are now independent. Shipping iPhone/iPad windows always use the bottom tab bar, including wide iPad landscape. Wide Usage/Settings list-detail and paired Cost content remain enabled. Trailing navigation requires explicit preview opt-in and is disabled unconditionally in Release. It is an illustrative Duo design, not an inferred device capability based on screen dimensions.

Validation: model coverage separates navigation from columns; full-app iPad UI tests assert bottom location and horizontal tab arrangement in portrait/landscape, absence of a right rail, search/keyboard stability, and preserved provider/Settings selection across resize. Re-run iPhone regression, localized release-note audit, archive entitlement/version checks and upload 202.

Build 202 validation and TestFlight handoff completed: 745 Swift Testing + 42 XCTest and 6 UI case/device executions passed; native iPhone/iPad screenshots inspected; ASC VALID / IN_BETA_TESTING / Internal plus four beta locales confirmed. See 08-native-navigation-testflight.md for archive source/hash and evidence.
