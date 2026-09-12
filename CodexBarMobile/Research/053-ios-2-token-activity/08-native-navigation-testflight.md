# iPhone / iPad native navigation and TestFlight 201 / 202

Status: build 201 uploaded and superseded; build 202 validation in progress.

- Source branch: `feature/ios-adaptive-duo-preview`
- Archive source: `b91754893d4a0f2c0fe061001983c61245b17b08`
- Version: **2.0.0 (201)**, main app / sync framework / widget / push extension aligned.
- Fix: close provider search before entering detail; measure adaptive layout independently of keyboard occlusion without disabling content keyboard avoidance.
- No Mac, Shared, wire or CloudKit schema change. Production entitlement verified in archive.

## Validation

- Full app iPhone 17 Pro: repeated push/back, tab restoration, portrait/landscape, Usage final footer clear of tab buttons, Settings navigation, token overview / provider heatmap selection and scrolling.
- Full app iPhone 17e: same navigation/rotation/footer regression passed.
- Full app iPad Pro 13: two-column portrait cards, search keyboard dismissal, keyboard-open landscape navigation, provider and Settings selection across portrait/landscape, Cost layout.
- 745 Swift Testing + 41 XCTest cases and 5 UI case/device executions passed. No animation-idle timeout on the final iPhone/iPad runs.
- Full repository lint passed. Six preview PNGs losslessly compressed to satisfy repository size guard; all 24 decoded RGBA images are unchanged.
- Four-language notes updated in existing 2.0.0 entry and TestFlight metadata inputs.
- Source 1024 px opaque icon and decoded archive 120 px opaque icon visually inspected.
- Self-review: no outstanding blocking finding. No remote PR/merge required for this authorized beta; neither performed.

Results: `/tmp/cbm-native-final-phone.xcresult`, `/tmp/cbm-native-ipad-final.xcresult`, `/tmp/cbm-native-compact.xcresult`.
Logs: `/tmp/cbm-201-lint-final.log`, `/tmp/cbm-201-archive.log`, `/tmp/cbm-201-upload.log`.
Actual screenshots: `output/qa/native-navigation/`; temporary sharing: https://subdivision-testament-msg-reprint.trycloudflare.com/native/ . Earlier fixed-window previews are not safe-area or full-app navigation evidence.

## Upload provenance

- Archive: `/tmp/CodexBarMobile-2.0.0-201-native.xcarchive`
- Sorted archive file-content manifest: `/tmp/cbm-201-archive-manifest.sha256`
- SHA256 of manifest: `4d8542bcc8b927ff190a825c75d7a63f0d2dcbadec331f1047dd9caf3ee9839d`
- Archive: `ARCHIVE SUCCEEDED`.
- Export/upload: `EXPORT SUCCEEDED`, accepted by Apple at 2026-09-11 20:52 PT.
- ASC build ID / processing / beta access / CDN icon: pending readback below.

## Boundaries

Duo-specific SDK/runtime, actual folding, multi-display handoff and physical safe areas remain unverified. The installed iOS runtime is 26.5; this is not an iOS 17 runtime or physical-device test. Real-account CloudKit multi-device convergence remains covered only by the prior documented substituted matrix; no new physical 16-combination pass is claimed. No production schema deploy, Git push/merge/tag or App Review/public release performed.

## Build 202 correction

User clarified after the 201 upload: ordinary iPad keeps bottom tabs in portrait and landscape. Wide two-column/list-detail content remains supported. Duo trailing navigation is explicitly preview-only and disabled in Release. Build 201 is not accepted as satisfying this clarified requirement. Build 202 will supersede it.

### 202 verification

- Full unit run: 745 Swift Testing cases / 49 suites and 42 XCTest cases passed, including the new independent content/navigation policy test.
- iPad full-app rotation tests passed: 34.666 s and 55.383 s. Both assert bottom tab placement and no trailing rail. Search keyboard and provider/Settings restoration covered.
- Actual iPad portrait, landscape provider detail and landscape Cost screenshots visually inspected: bottom tabs, retained wide content.
- Repository lint and four-language release note checks passed. No Mac/Shared/schema changes.
- iPhone 17 Pro: three full-app navigation / heatmap UI tests passed. iPhone 17e confirmation is running; archive/upload evidence follows.
- Results: `/tmp/cbm-202-phone.xcresult`, `/tmp/cbm-202-ipad.xcresult`; full lint `/tmp/cbm-202-lint.log`.
- Actual build 202 screenshots: `output/qa/native-navigation-202/`, mirrored to the temporary `/native/` gallery.
