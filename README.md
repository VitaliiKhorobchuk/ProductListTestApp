# ProductListTestApp

A Flutter product catalog assessment using the public [DummyJSON API](https://dummyjson.com/docs/products). Browse a paginated catalog, combine title search with a category, switch list/grid and light/dark themes, and open product details. Phone navigation becomes master-detail at tablet widths.

## 1. Setup and run

Verified with **Flutter 3.47.8 stable / Dart 3.13.7**. The package requires Dart `^3.13.7`; the lockfile also requires Flutter `>=3.47.0`. Use the verified SDK pair: older Flutter 3.x installations are not automatically compatible.

~~~sh
git clone https://github.com/VitaliiKhorobchuk/ProductListTestApp.git
cd ProductListTestApp
flutter --version
flutter doctor
flutter pub get
flutter run -d chrome --web-port 8800
~~~

For Android, configure the Android SDK/toolchain, connect an authorized device, run `flutter devices`, then `flutter run -d <device-id>`. Internet access to DummyJSON and its image CDN is required. No API key, environment file, generated model code or sample-data flag is needed.

Web uses Flutter's default hash routes:

- Catalog: `http://localhost:8800/#/products`
- Direct product: `http://localhost:8800/#/products/1`
- Component showcase: `http://localhost:8800/#/debug/components`

### Debug component showcase

Run the app in debug mode to explore reusable components independently of the live catalog:

~~~sh
flutter run --debug -d chrome --web-port 8800
~~~

Open the catalog and select the toolbar button with the tooltip **Open component showcase**, or navigate directly to `http://localhost:8800/#/debug/components`. On Android, run `flutter run --debug -d <device-id>` and use the same toolbar button.

The screen lists available components. Select one to inspect its variants, interactive examples and relevant selected/disabled/loading/error/empty/image-fallback states. Preview controls let you change the available width (including 160px, 320px and 600px presets), text size (100%, 150% or 200%), and light/dark theme. Width presets are capped by the available space.

The showcase routes and entry button are guarded by `kDebugMode` and are absent in profile/release builds. Its retained preview image remains declared as a bundled asset.

### Checks and builds

~~~sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
flutter build apk --release
flutter run --profile -d <android-device-id>
~~~

Outputs: `build/web/` and `build/app/outputs/flutter-apk/app-release.apk`. Android release currently uses the scaffold's debug signing configuration for assessment use; production signing/application identity are separate work. iOS requires macOS/Xcode and has not been built or run for this submission.

## 2. Architecture

**MVVM-style responsibilities:** Views render state and forward actions; Cubits act as ViewModels; immutable models and repository/API layers supply data.

~~~text
View -> Cubit -> ProductsRepository -> RemoteProductsRepository
                                           -> ProductsApi -> Dio -> DummyJSON
View <- immutable Cubit state
~~~

| Location | Responsibility |
| --- | --- |
| `lib/app/` | Dependency composition, centralized routes, adaptive shell, theme state and shared app controls. |
| `lib/core/` | Typed failures, cancellation and shared numeric/rating/pricing/label/URL rules. |
| `lib/design_system/` | ThemeExtension tokens, themes and configurable widgets without feature data/navigation dependencies. |
| `lib/features/catalog/models/` | Products, categories, query and page/cursor values. |
| `lib/features/catalog/data/` | Repository contract, remote implementation, Dio API and defensive parsing. |
| `lib/features/catalog/presentation/` | Catalog/category/detail Cubits, immutable states, screens and feature widgets. |
| `lib/debug/` | Debug-only route registration, showcase navigation and the catalog entry button. |
| `lib/debug/component_showcase/` | Component list/detail screens, state/variant examples, preview width/text-size controls, example models and scoped asset constants. |
| `test/` | State, parser and component tests, local doubles and shared theme setup. |

### Libraries and state ownership

- **bloc / flutter_bloc:** explicit asynchronous transitions and a small Cubit API, without an event layer for these workflows.
- **Equatable:** value equality for immutable models/state and effective queries.
- **GoRouter:** centralized routes, direct URLs and route-owned detail selection.
- **Dio:** injectable HTTP client, cancellation, timeouts and transport error handling.
- **Flutter Material + ThemeExtension:** shared tokens/components without another UI framework. Cupertino Icons remains for Flutter adaptive-control font use.

Constructor injection keeps Cubits independent of BuildContext, navigation and Dio. The app owns one client/repository/router. Catalog/category state survives detail navigation; each detail route owns an ID-keyed ProductDetailCubit. Theme starts from the system preference; the user's override lasts for the app session.

The catalog View owns draft text, scroll and layout. A persistent shell retains its subtree. Below **768 logical pixels of safe available width**, one pane is visible; at/above it, a **380px** catalog sits beside details or a selection prompt. Back preserves catalog state at the same layout; reflow may clamp offsets rather than preserve an exact item/pixel anchor.

### Search, pagination and errors

Typing is debounced by 300ms; Enter submits immediately; clear cancels pending typing and searches immediately. Search is a case-insensitive title substring intersected with one selected category.

The API returns raw pages. The repository scans further pages until a complete matching batch or exhaustion, advancing raw offsets before removing malformed records/local nonmatches. Overfilled batches retain their matches so cursor advancement loses no products. Batches are atomic: later-page failure publishes neither partial results nor an advanced cursor.

The repository deduplicates within a batch; CatalogCubit merges IDs across batches. Cancellation plus Cubit generation counters reject superseded results. Initial failures show a full error state; pagination failures retain rows and retry at the same cursor. Categories load/retry independently.

Dio has 10s connect and 15s receive timeouts. One 30s repository-operation deadline covers every scanned page. Expiry cancels work and becomes a retryable timeout.

See [system design](docs/system-design.md), [implementation plan](docs/implementation-plan.md) and [code review](docs/code-review.md).

## 3. Design system

`AppTokens` is a `ThemeExtension` in both themes: semantic/rating colors, 8px-based spacing, radii (12px/8px), borders and interaction overlays. Component-specific geometry stays named near its owner. Material controls inherit the theme.

Light primary is `#2563EB`; dark primary is `#3B82F6`. Foreground/rating colors differ by theme for readability. Dark accent controls use a dark foreground rather than low-contrast white. These contrast-oriented deviations from the guideline palette are intentional.

| Component | API and behavior |
| --- | --- |
| `ProductCard` | Title/category, optional brand/image, current/original prices, rating/count, selected, onTap and standard/compact variants. Standard is horizontal when space/text size permits; compact is stacked. Narrow/large-text standard cards also stack. Material ripple, derived discount label and image fallbacks. |
| `ProductSearchField` | onChanged/onSubmitted, hint/clear tooltip, enabled, optional controller/focus node and configurable debounce. Internally created resources are disposed internally; supplied resources remain caller-owned. Programmatic text changes do not automatically search. |
| `CategoryChip` | label, selected and callback; null callback disables it. Parent owns selection. Catalog uses single selection and All products in a horizontal strip. |
| `ErrorState / EmptyState` | Configurable icon/title/message and optional action over shared StateMessage layout; full-area and inline uses. |
| `RatingBadge` | Optional rating/reviewCount, star/numeric text: green >=4, amber >=3 and <4, red <3. Unknown remains unknown. One semantic label describes rating/count independently of color. |
| `ProductImage / ProductPrice` | Shared loading/fallback image slots and current/original prices. Flutter's image cache is in memory; persistent disk caching is not implemented. |

Loading skeletons reuse card/row geometry and exclude decorative content from semantics. Showcase width/text-size controls expose component states; the showcase is a manual development tool, not automated coverage.

## 4. Verification, limitations and future improvements

Final results: **77 Dart files formatted, clean analysis, all 10 tests pass, release web/profile Android/release APK builds pass**. Android interactions used a Pixel 7 Pro / Android 17 profile build. Browser checks used the release app and debug showcase.

| Automated area | Tests | Coverage |
| --- | --- | --- |
| CatalogCubit | 4 | Loading/loaded, empty, failure/retry and pagination with duplicate merging/retained rows. |
| ProductParser | 4 | Valid fields, optional fallbacks, rejected IDs and raw cursor advancement. |
| Components | 2 | RatingBadge content/color/semantics; CategoryChip callback and parent-owned selection. |

This covers the assessment's test categories and two-component minimum, not exhaustive async/repository/routing coverage.

Manual checks covered 320/390 phone layouts, the 767/768 breakpoint, keyboard activation of catalog controls, combined search/category filters, empty recovery, cold/malformed/missing detail links, retained state and both themes. Representative ProductCard and CategoryChip states were inspected at 200% text. Android traversed beyond 100 products, opened details and preserved the grid/visible region after Android Back and theme switching.

**Performance still needs improvement.** Profile samples include frame-budget exceedances, including a short pass over previously visited content. A zero-dropped-frame claim is unsupported. USB-mirrored interaction samples are not a sustained FPS benchmark. See [verification measurements and limits](docs/verification.md).

Future improvements and known limits:

- **Rating precision:** choose consistent rounding/color rules; raw 3.999 can display 4.0 while using amber. Intentionally deferred.
- **Localization:** move English strings, errors, semantic labels, plurals and currency formatting into resources, with presentation-owned failure mapping. Intentionally deferred; translations are not an assessment requirement.
- Profile/tune scrolling, image decode/cache behavior, layout bursts and startup; measure sustained frame pacing/memory before claiming smooth performance.
- Improve wide-desktop proportions: fixed tablet-oriented list width and centered detail content leave unused space on large monitors.
- Complete TalkBack/VoiceOver, full-app OS font scaling, native rotation/tablet and additional platform checks. Browser semantics/scaled previews provide partial accessibility evidence.
- Native Android App Links/iOS Universal Links are not configured. Verified browser hash URLs do not establish native OS link handling.
- No offline persistence, process-death restoration or persisted theme/filter preferences; reuse is session/in-memory only.
- Add targeted API/repository/cancellation/navigation regression tests. Other generated desktop runners are unverified.
- Consider use cases only when orchestration becomes reused/complex; no separate domain layer is added for the current scope.

## 5. Specification issues and assumptions

| Ambiguity | Decision and reason |
| --- | --- |
| DummyJSON search also matches descriptions. | Use remote search then enforce title-only matching locally. Search takes endpoint precedence; repository scanning intersects the results with the selected category. |
| No combined search/category endpoint. | Intersect in the repository across raw pages rather than filtering only the first visible page. |
| Filtered result count. | Display loaded count; the API total belongs to the remote query and can exceed final local matches. |
| Rating/review count. | Use API rating directly; derive reviewCount from reviews.length and hide when absent. Returned reviews are not claimed to be the complete review total. |
| Price/discount/currency. | Assume USD and API price as original; share discount calculations. Invalid/negative/missing prices show Price unavailable; zero stays valid. |
| ProductCard percentage argument. | Accept calculated current/original prices instead of the PDF's direct percentage argument. Shared pricing derives the label; the widget stays independent of API models. |
| Missing/malformed data. | Optional fields use readable/unknown fallbacks; invalid IDs are skipped with diagnostics. Inconsistent envelopes/nonempty raw pages with no valid products fail the logical batch rather than imply no results. |
| Optional showcase route. | Use /debug/components behind kDebugMode instead of public /showcase to keep the tool out of release navigation. |
| Links/platform support. | /products/:id is the app route; web uses #/products/:id. Native URL registration and iOS runtime checks remain outside the verified baseline. |

## 6. AI assistance

The developer directed scope, architecture choices, checkpoint acceptance and refinements, and performed all staging/commits. AI contributed architecture suggestions, explanations, substantial scoped Dart implementation, reviews, debugging and verification. Earlier checkpoints used UI/design, data/state, architect and QA agents; final cleanup/tests/handoff checks used the coordinating assistant.

Developer feedback refined readability/controller ownership, removed premature tests/sample paths and duplicated rules, required title-only filtering, and deferred localization/rating precision. AI work was refined during checks: a proposed Cupertino Icons removal was reverted after a build exposed an adaptive font dependency. Profile limitations are recorded rather than presented as a complete performance pass.

The undated [AI development overview](docs/ai-development-overview.md) records milestones, decisions, corrections and verification without a request-by-request transcript. Plans/review documents are included under docs/.

## 7. Approximate time spent

Developer-reported estimates, not a timer log:

| Work | Approximate time |
| --- | --- |
| Setup, planning and system design | About 1.5 hours |
| App, data integration and screens | 2+ hours |
| Tests, verification and documentation combined | About 1 hour |
| Design-system work | Not tracked separately; included within the broader implementation estimate |

Rough total: **4.5+ hours**. These estimates do not independently quantify every AI run, review or explanation.
