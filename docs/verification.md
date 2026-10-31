# Final verification

This checkpoint changes documentation only. Rating precision and English localization were explicitly deferred to README future improvements.

## Builds and automated checks

| Check | Result |
| --- | --- |
| dart format --output=none --set-exit-if-changed lib test | Pass: 77 files, zero changes. |
| flutter analyze | Pass: no issues. |
| flutter test | Pass: 10 tests. |
| flutter build web --release | Pass, including font tree shaking and Wasm dry run. JavaScript build smoke checked; Wasm runtime not tested. |
| flutter run --profile on Pixel 7 Pro / Android 17 | Pass: build/install/launch, Impeller Vulkan. |
| flutter build apk --release | Pass. Device interaction used the profile artifact, not the release APK. |

SDK: Flutter 3.47.8 stable / Dart 3.13.7. Gradle emitted a Java native-access warning; builds completed. Release signing remains scaffold debug signing, not store-delivery signoff.

## Browser checks

The fresh release build was served locally; Flutter web semantics were enabled.

- 390/320 phone layouts: search, horizontal categories and list/grid fit. At 320px compact content reduced to one column.
- Exactly 768 safe logical pixels: master/detail visible together. At 767: detail alone, hidden catalog excluded from accessible tree.
- Tab reached layout/theme controls; Enter activated them; visible focus inspected. Search submission also checked through the accessible textbox.
- Search red returned nine title matches; Beauty reduced to two. Opened Red Lipstick, crossed the breakpoint and returned with query/category/grid retained.
- No-match search showed recovery; its Clear search action restored five products in the retained Beauty category.
- Cold hash /products/1 loaded its detail; /products/not-a-number showed recovery; /products/999999 showed Product not found.
- Light/dark appearance, selected-card semantics and labeled detail headings/images/rating/count/price/stock inspected.
- Standard/compact ProductCard inspected at 200% text/320px. Selected/disabled/long CategoryChip inspected at 200%, including 160px wrapping with full semantic label.
- Scoped release and inspected showcase browser warning/error logs were empty.

Text scaling covered representative components, not full-app OS settings. No full screen-reader/contrast/tap-target/keyboard-order audit is claimed. Flutter's experimental accessibility evaluator was attempted, but the stable SDK reported it unavailable without another channel/feature flag. No SDK settings were changed.

## Android checks

Pixel 7 Pro / Android 17, profile mode, through a temporary official scrcpy USB mirror. Display reported 120Hz; no screen recording.

- Loaded remote catalog/images, switched list/grid, and paginated from initial products through mobile accessories beyond product 100 (Apple AirPods Max Silver is API ID 101).
- Opened that product and checked gallery/title/brand/prices/rating/stock/description.
- Android system Back returned to the same visible grid region; light-theme switching also retained it.
- Scoped logs contained no app-specific E/flutter, fatal exception, unhandled-error or RenderFlex overflow entry. This smoke check is not a crash-free guarantee.

A rotation shortcut was attempted but the device remained portrait, so native rotation/master-detail is unverified. Browser breakpoints supply adaptive evidence. Native search/combined filters were checked in an earlier checkpoint; the current browser run repeated those behaviors.

## Profile measurements

Local VM timeline exports were analyzed by pairing complete Frame and GPURasterizer::Draw begin/end events. Durations are milliseconds; p95 uses nearest rank. These are stage samples, not counted dropped display frames or end-to-end FPS.

| Sample | Stage | Events | Median ms | p95 ms | Max ms | >8.33ms | >16.67ms |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Initial traversal and controls | UI Frame | 282 | 1.901 | 8.477 | 93.906 | 16 | 10 |
| Initial traversal and controls | Raster draw | 280 | 2.521 | 6.963 | 11.481 | 8 | 0 |
| Four short revisited-content passes | UI Frame | 35 | 3.060 | 32.952 | 35.933 | 4 | 4 |
| Four short revisited-content passes | Raster draw | 35 | 6.000 | 10.458 | 12.021 | 2 | 0 |

Initial export includes layout/control/keyboard interactions and first-use images during traversal toward the first hundred products. Later visual inspection confirmed content beyond 100; the initial trace is not asserted to cover every product or uninterrupted scrolling. The second buffer was cleared afterward and covers four short up/down passes through recently visited watches/mobile accessories. Idle gaps, small sample size and USB mirroring limit conclusions.

At 120Hz the nominal stage budget is about 8.33ms; at 60Hz, 16.67ms. Both samples include budget exceedances. An Android startup log also reported skipped frames before measured buffers. **The no-dropped-frames requirement has not received full performance signoff.** Image decode/cache behavior, layout/build bursts and startup work are investigation targets, not established causes.

Raw traces, summary utility and screenshots stay in external project notes. Reproduce with flutter run --profile and DevTools: scroll beyond 100 products, record first-use and revisited-content samples separately, and compare stages against device refresh budget.

## Remaining limits

iOS, other desktop runners, native OS links and native rotation/tablet are unverified. TalkBack/VoiceOver, full-app font scaling, sustained pacing and memory profiling remain follow-ups. Tests do not comprehensively cover API/repository failures, cancellation/deadlines/races or routing lifetimes. Rating precision, localization and wide-desktop proportions remain improvements. No app fixes were made during this checkpoint.
