# ProductListTestApp implementation plan

This document records the initial architecture and implementation decisions for the Flutter Product Catalog assessment. Update it as decisions change and record the reasons for meaningful deviations.

Detailed state ownership, contracts, request flows, failure policies, and acceptance criteria are defined in [system-design.md](system-design.md).

## Required functionality

- Consume the DummyJSON Products API.
- Display products with initial loading placeholders, error/retry, and empty states.
- Support debounced search, category filtering, and infinite scrolling.
- Display product details with an image gallery, title, brand, description, prices, rating, availability, and category.
- Support direct product links at `/products/:id` and preserve catalog filters and scroll position when returning from details.
- Use separate screens on phones and a master-detail layout at 768 logical pixels and above, with a catalog panel approximately 350-400 pixels wide and a selection prompt when no product is selected.
- Provide a reusable design system that supports light and dark themes.
- Validate imperfect API data, render lists lazily, and cache images where supported.
- Include state-management and model-validation unit tests, widget tests for at least two design-system components, and setup/architecture documentation.

The required design-system components are ProductCard (standard and compact variants), a search input, CategoryChip, error/empty states, and RatingBadge. Offline persistence and advanced animations remain optional enhancements after mandatory behavior is complete. The developer explicitly selected Enhancement A during component work: a debug-only component showcase now provides a reusable place for manual visual checks.

## Tablet master-detail implementation

CatalogLayout owns the single breakpoint (768 safe available logical pixels), fixed catalog width (380), and divider width (1). CatalogShell measures after SafeArea. A persistent ShellRoute keeps CatalogScreen and its child Navigator in fixed layout slots: wide mode shows both; narrow mode shows catalog or detail according to the matched route. Hidden panes retain real bounded constraints, exclude focus/semantics and pause tickers. The last visible catalog width is retained while hidden so opening details does not unnecessarily reflow its scroll content. Divider/detail geometry always uses the fixed split width, including when the debug showcase covers the shell.

Nested prompt/detail/recovery pages use NoTransitionPage with the router page key. Their zero-duration transitions allow removed routes to dispose without waiting on tickers in a hidden Navigator; product/provider keys remain ID-based. The shell visibility switch is immediate in both layouts.

The URL alone owns selection. CatalogLayoutScope publishes route-derived visibility and selected ID to presentation; malformed matched detail links remain detail-active independently of successful integer parsing. ProductCard receives a controlled selected flag for its primary border and selection semantics. CatalogDetailAppBar shares phone Back and wide Clear selection chrome across details/recovery; the wide catalog route shows a selection prompt. Existing numeric validation, Cubits, repository, price/text/image rules, and gallery remain reused.

CatalogScreen retains its controllers, draft, query, fetched pages and variant. Automatic viewport filling runs only when the catalog is visible, and dependency changes trigger a new visibility check. ProductDetailCubit and gallery stay route-owned and survive resizing; changing/clearing the route still replaces/closes details. Each pane scrolls independently. Actual visible reflow can change card geometry and clamp offsets to valid extents; exact item anchoring across different widths/text scales is not promised.

UI/design and architect source reviews found no remaining blockers after correcting hidden detail geometry during covered-route resize. Manual checks and the external QA review are recorded separately in the AI overview and qa-adaptive-layout.md. Automated regression, native accessibility/platform execution, performance, and broad constants/localization cleanup remain final-stage work. No dependencies or README changes are required.


## Architecture and responsibilities

Use a small feature-based architecture with UI and data responsibilities separated:

`Screens -> Cubits -> ProductsRepository -> ProductsApi -> DummyJSON`

| Part | Responsibility |
| --- | --- |
| Design-system widgets | Reusable visual components configured through values and callbacks. |
| Screens | Compose components, render state, and forward user actions. |
| Cubits | Own predictable screen state and coordinate loading, filtering, pagination, and retries. |
| Repository | Expose a testable data-access contract and coordinate API requests, filtering, and pagination. |
| API service | Make HTTP requests, validate response structure, parse data, and translate transport errors. |
| Models | Represent products, categories, and page results with explicit validation/defaults. |

Use constructor injection so tests can replace the repository with a fake. Keep state immutable and handle initial, loading, loaded, empty, and error conditions explicitly. Give pagination its own loading/error fields so an unsuccessful next-page request preserves existing products.

Keep category loading independent from product loading. Scope catalog state so it survives detail navigation and responsive-layout changes. Protect asynchronous searches from stale responses with a request-generation check.

Suggested organization:

```text
lib/
  main.dart
  app/                       # App composition and centralized routing
  core/                      # Shared failures and logging, as needed
  design_system/
    theme/
    components/
  features/catalog/
    models/
    data/
    presentation/
      cubit/
      screens/
test/
docs/
```

Create folders as their first implementation files are added. A separate use-case layer is unnecessary for the initial scope; criteria for reconsidering it are recorded under Possible future improvements.

## Technology choices

- **Flutter and Dart:** use the installed stable SDK and record its version in the README; commit the application dependency lockfile.
- **bloc and flutter_bloc with Cubit:** the pure-Dart bloc package supplies the ViewModel; flutter_bloc binds its state/actions to Flutter Views through providers/builders. This follows the assessment's encouraged approach.
- **Equatable:** compare immutable states, models, and effective queries by value without a code-generation pipeline.
- **go_router:** centralized declarative routes, product-ID parameters, and direct detail links.
- **Dio:** HTTP requests, timeouts, and consistent transport-error handling.
- **ThemeExtension and Material ThemeData:** custom color, spacing, radius, and semantic tokens shared by light/dark components.
- **Flutter testing tools:** add and run automated unit/widget tests during the final verification step. During implementation, use manual review, static analysis, formatting, and appropriate build checks.

Add dependencies when implementation begins using them. The first card increment uses AssetImage for bundled fixtures and NetworkImage for remote sources, with Flutter memory caching and fixed USD formatting; no supporting package is needed yet. Persistent disk caching and broader locale formatting remain explicit later decisions; document platform-specific behavior when introduced.

## Assumptions and API behavior

### Search and categories

- Search is a case-insensitive substring match on the product title. Trim leading/trailing whitespace. For example, `red` can match `Red Lipstick` but must not match `Eggs` merely because its description contains `ingredient`.
- Keep server-side search, then apply title matching in the repository because DummyJSON's search also returns description matches.
- Use a 300ms input debounce. Enter submits immediately and cancels the pending debounce; clearing updates immediately. Ignore duplicate effective queries.
- Support one selected category plus an All products option. Requests use category slugs; chips display category names.
- Search and category selection work together. The documented API exposes separate search and category endpoints, so the repository intersects matching titles and the selected category locally when necessary.

### Pagination

- Start with a batch size of 20 and use the server's limit/skip pagination.
- Advance the cursor by raw server records consumed, including records removed by filtering or validation.
- Continue scanning pages until a display batch is collected or server results are exhausted. A raw page without visible matches does not prove that the complete result is empty.
- Retain all matches from consumed pages, deduplicate product IDs, and prevent concurrent next-page requests.
- The server total may describe broader search results rather than the title/category intersection. Show a loaded-item count rather than presenting that total as an exact filtered count.

### Prices, validation, and theme

- Assume USD because the brief does not provide a currency field.
- Treat API price as the original price; calculate the discounted price using discountPercentage and keep card/detail formatting consistent.
- Display Price unavailable for missing, negative, or non-finite prices and log the issue. Ignore invalid discounts.
- Use readable defaults for missing descriptive fields; keep unknown rating and stock distinct from zero.
- Show placeholders for missing/broken image URLs and log warnings. Skip malformed product records with invalid IDs; treat malformed response envelopes as errors.
- Start with the brief's theme colors, 12px/default and 8px/small radii, and 8px base spacing. Document visual extensions or deviations.
- Rating colors: green at 4 and above, amber from 3 to below 4, and red below 3.
- During API parsing, use the API rating directly; do not recompute it from individual reviews. When reviews is a list, derive reviewCount from reviews.length (an empty list means zero). If reviews is missing, null, or not a list, keep reviewCount null so the badge hides the count. This is the count of returned reviews, not a separately guaranteed total rating/review count.

## Implementation sequence

1. **App and MVVM architecture skeleton:** separate startup, app composition, and centralized routing. Implement one working offline catalog slice with immutable models, a repository contract/sample implementation, a pure-Dart Cubit/ViewModel and state, and a View displaying example products with reload and loading/empty/error states. Inject the repository/Cubit above routing. Completion: the sample runs, analysis is clean, and the architect reviews the complete layer boundaries. Automated tests remain deferred.
2. **Theme foundation (implemented):** AppTokens extends ThemeExtension for colors, spacing, radii, and rating colors; AppTheme supplies light/dark ThemeData. An app-level ThemeCubit starts with ThemeMode.system; the app listens through BlocBuilder, and the sample screen sends appearance actions directly to that Cubit without router callbacks. Manual switching preserves the route, loaded state, Cubit instance, and scroll position. Formatting, analysis, a web release build, and independent architecture/design review complete this checkpoint; automated tests remain deferred.
3. **Reusable components (implemented):** RatingBadge and ProductCard are implemented in standard/list and compact/grid variants, with shared image loading/fallbacks, defensive price/rating presentation, and manual component checks. The catalog maps models into display values and exposes a local list/grid choice. ErrorState and EmptyState now share a theme-aware StateMessage layout with caller-owned text/actions, full-area/inline variants, and catalog retry integration. ProductSearchField now supplies debounced typing, immediate clear/Enter callbacks, controller/focus ownership, and showcase coverage. CategoryChip now provides parent-controlled selection with native chip interaction, themed selected/disabled states, wrapping labels, and showcase examples. Automated component tests remain final-stage work.
4. **Models and API (implemented):** defensive decoded-JSON mapping is implemented in a pure-Dart ProductParser at the data boundary. It constructs the existing Product/Category values and a separate RawProductPage with validated raw counts/cursors; trusted fixture constructors and the domain ProductPage remain unchanged. Optional-field defaults, safe integer identities/metadata, HTTP(S) image validation, category deduplication, and malformed-envelope/all-invalid-page failures are covered. API ratings remain direct; reviewCount follows the reviews-list policy above. ProductsApi and its caller-owned Dio client factory are now implemented: one raw request, endpoint selection/encoding, status-first JSON decoding, parser integration, requested detail-ID consistency, typed failures, and CancelToken cancellation. Dio ^5.11.1 is declared and 5.11.1 is locked. RemoteProductsRepository now adds atomic title/category scans, raw-cursor progress, per-batch deduplication/overfill, stable-total guards, and independent cancellation/deadline scopes with cleanup. Main-app remote binding, catalog/category state and screen controls are implemented.
5. **App binding and catalog/category Cubits (implemented):** initial loading defaults to the remote path, with composition-owned Dio disposal, caller-owned repository overrides and Android Internet permission. CatalogCubit now owns effective search/category changes, generation/cancellation guards, guarded pagination, cross-batch ID merging and footer retry. CategoriesCubit independently coalesces/caches metadata and handles replacement retries; its app provider is lazy until consumed. Manual state/live-data checks and data/state/architect reviews complete this checkpoint. Detail state belongs to step 8.
6. **Catalog screen (implemented):** reusable search/category controls now consume the independent Cubits; status/empty/error recovery, loaded count, lazy list/grid and footer retry share one scrollable. Initial loading now uses static themed skeleton cards matching both layouts and responsive/text-scale rules.
7. **Search, filters, and pagination (implemented):** input debounce/Enter/clear, title/category intersection, raw cursor handling, stale-response guards, cross-batch deduplication, near-bottom/post-layout/resize refill and explicit footer retry are wired. Query changes clear both layout scroll offsets; append/theme/showcase preserve position. Manual edge cases and role-based reviews passed; exact native input/screen-reader and automated regression coverage remain final-stage verification.
8. **Phone details and navigation (implemented):** route-owned ProductDetailCubit drives loading/recovery/error/notFound and complete product details/gallery. Cards open nested /products/:id; decimal URL parsing delegates numeric validity to the repository. Shared price/text/image policies avoid duplicate rules. Hash direct links/reload, Back/Browse, gallery controls and warm catalog retention have manual evidence. Tablet master-detail is implemented in step9; final native/automated/accessibility checks remain next.
9. **Tablet layout (implemented):** persistent catalog/detail shell, shared safe-width policy, route-derived selection prompt/highlight, adaptive Back/Clear chrome, independent scrolling and retained state across resizing.
10. **Final verification and handoff (required test baseline implemented):** ten focused tests cover Cubit transitions, data validation/model parsing and two design-system components. Remaining work includes localization, target-platform/accessibility/layout/performance verification and final documentation. Deeper repository, asynchronous-safety and routing regression tests remain recommended follow-ups beyond the PDF baseline.

The architecture checkpoint is a runnable offline MVVM example with a catalog route, injected repository, Cubit/state, sample products, clean analysis, manual reload verification, and an architect review. The theme checkpoint now builds on it without changing the data layers. RatingBadge/ProductCard are the first completed component increment, with clean formatting/analysis, builds, UI/design and architecture review, and manual variants/themes, phone-width, large-text, fallback, keyboard, and scroll checks. ErrorState/EmptyState extraction is complete with clean formatting/analysis, production/preview builds, UI/design and architecture reviews, and manual empty/error/retry, inline, narrow/short, large-text, and keyboard checks. ProductSearchField and CategoryChip complete the required reusable-component implementation checkpoint. Defensive model parsing, ProductsApi, and RemoteProductsRepository are now implemented and reviewed. Main-app remote initial loading, catalog/category state and screen-control integration are implemented and reviewed. Initial skeletons and phone details/navigation are implemented. Adaptive master-detail is implemented; full-product acceptance remains in the final stage.

Describe the overall folder structure in this plan and create each folder when its first real file is added. Each increment should leave the app runnable and be checked through review, static analysis, and appropriate manual/build checks. Automated tests are deferred to final verification. Keep changes small enough to review and explain. The user handles all staging, commits, and pushes.

Defensive parsing verification: formatting and full static analysis passed, as did a production web build. Temporary external console inspection used public API samples and deliberately imperfect decoded values; it confirmed field fallbacks, safe identity/metadata rejection, raw cursor preservation, category policies, diagnostics, and the unchanged six-product sample repository. Data/state and independent architect reviews found no blockers. No automated tests were added or run; required parsing/state coverage remains final-stage work. This checkpoint does not connect the app to HTTP or establish browser/native-platform parser coverage.

ProductsApi verification: formatting/full analysis and a production web build passed. Temporary external native-Dart and loopback HTTP inspection covered live browsing/search/categories/details, status-before-body error classification, invalid/mismatched data, encoded path/query values, no I/O for invalid/pre-cancelled calls, in-flight cancellation, receive timeout, and unchanged shared client response settings. A temporary browser page using the actual API/client completed live category/page/detail requests from localhost, providing an origin-specific HTTP/CORS check. Data/state and architect reviews found no blockers. Connection/certificate and other unexercised transport branches remain source-reviewed; automated/native-device/full-product coverage remains deferred. The catalog still uses SampleProductsRepository. No automated tests, staging, or commits were performed.

Remote repository verification: formatting/full analysis and a production web build passed. Native-Dart live/loopback inspection covered title/category intersection, raw-page scanning through no matches/malformed records/duplicates, overfill, atomic later-page failure/retry, total-change/nonprogress rejection, shared token/deadline without caller control, pre/in-flight cancellation, reason precedence, independent operations, late synchronous work, and successful scope cleanup. Browser inspection confirmed live filtering/cursor continuation and local deadline/caller-cancellation outcomes. Data/state and architect reviews found no blockers. The app remains sample-backed; no automated tests, dependencies, staging, or commits changed. Future Cubit pagination must deduplicate across calls, retain existing rows on an exhausted empty continuation, advance raw cursors even without new IDs, and retry a failed pagination cursor without restarting the whole catalog.

Remote binding verification: the default app now creates one Dio/API/RemoteProductsRepository in initState, preserves its router/providers across appearance rebuilds, and closes only the app-owned client on disposal. An explicit startup repository override creates no client and stays caller-owned. Catalog copy reports the loaded count without offline/example claims, and Android's main manifest declares INTERNET. Formatting/full analysis and debug/release builds passed. Manual standalone browser checks showed 20 live products, CDN images/prices/ratings/review counts, both themes and card layouts including 320px width, and no warning/error-level app diagnostics. An external BlocObserver inspection retained the same Cubit/loaded state through theme/grid/showcase/back; an injected initial failure recovered through Retry on the same Cubit; unmount closed its Cubit while the caller-owned client remained usable. Empty/sample overrides and manifest XML were verified. Data/state and architect reviews found no blockers. App-owned allocation/close count is source-reviewed; Android release/profile and broader device coverage, teardown during pending load, and automated coverage remain final-stage work. SAMPLE_CATALOG defines now affect only explicitly injected SampleProductsRepository.fromEnvironment(), not default startup. No tests, staging, or commits were performed.

With the developer's subsequent authorization, the debug APK was built/installed/launched on the connected Pixel 7 Pro (Android 17/API37). Device inspection confirmed 20 live products and images, dark/list and light/grid presentation, rapid reload, scrolling, and showcase/Back retention of visible products/layout/theme. App-scoped Flutter/Android runtime error logs were empty. Debug startup platform/skipped-frame notices were observed, so this is functional smoke evidence rather than performance signoff. The app was left installed/running; Android induced-failure/retry, release/profile, pending-load teardown, broader-device and iOS checks remain later verification. No code changes were needed for the device check.

## Phone product detail UI and navigation checkpoint

Product cards now navigate by ID to the nested /products/:id route. CatalogNavigation owns route names, decimal URL syntax parsing and Back/Browse behavior. Parsing checks only URL text shape/int conversion; positive/safe numeric validity remains repository-owned. Malformed text and unknown routes render friendly recovery, while numeric invalid IDs reach typed repository failure. Declarative goNamed updates the browser URL; the persistent catalog shell is retained beside the child detail Navigator. Back pops with a catalog fallback, while Browse explicitly targets the catalog.

ProductDetailRoute creates/closes a ProductDetailCubit keyed by numeric ID using the shared repository. It introduces no app-level selected-ID state or detail cache. ProductDetailScreen renders loading, idle recovery, notFound/Browse and retryable failure, then a naturally scrollable phone detail layout with gallery, category, direct API rating/review count, title, brand, shared prices, availability and description. Unknown stock remains separate from zero. The adaptive shell now places this shared detail layout beside the catalog on wide viewports (step9).

Gallery presentation uses lazy PageView pages, viewport-bounded image height, previous/next buttons and a page counter. Product owns one immutable ordered trim/nonblank/dedup image-list invariant across parsed and directly constructed values; the parser keeps URL validation/diagnostics and only collects entries. ProductPresentation selects canonical images or an immutable thumbnail fallback. ProductImage retains URL/asset validation, loading and broken-image handling. Gallery index/controller are local and reset by product/source identity; theme changes do not reset identical images. Reduced-motion settings use immediate page changes.

Common rules have explicit owners: core ProductPricing supplies validity, discount calculation/comparison/percent and USD formatting for parser/model/cards/details; ProductPrice supplies shared price semantics/rendering. ProductLabels supplies fallback constants/display normalization used by parsing, model defaults and presentation. Cards no longer keep a private second price implementation. RatingBadge and ProductImage are reused. Status announcements are scoped to loading/errors/idle/notFound and the loaded title; decorative images/controls are not announced as duplicate status text.

Formatting/full analysis and the final production web build passed. UI/design, data/state and architect source reviews found no remaining blockers after resolving imperative navigation's URL behavior, explicit Browse recovery, scoped announcements and duplicate gallery normalization. Independent QA executed print-only pure-Dart shared-helper inspection and reviewed coordinator screenshots/observations; actual browser interaction was coordinator-executed because child controls were unavailable.

Manual browser evidence also includes idle Load recovery and closing a held request during loading: cancellation/route Cubit disposal were observed, with no late detail update after the completion window. Manual browser evidence includes live card-to-detail URL updates, browser/AppBar Back, actual API fields/prices, controlled multi-image Next/Enter boundaries and per-product reset, missing/broken images and field fallbacks, zero rating/reviews/out-of-stock versus unknown, a failed detail request recovering on Retry, and explicit Browse recovery. A Red/Groceries compact catalog with39 loaded fixture records retained its query, layout, count and visible scrolled card region across detail30 and Back; same catalog DOM/Cubit and no extra catalog request were observed. This is visible-region evidence, not instrumented pixel equality. Malformed abc performed no detail request; numeric0 was repository-validated. Cold/reloaded hash URLs on the production HTTP build loaded real product1 with no warning/error-level app logs. Narrow320x568 at200% text remained scrollable, including light-theme multi-image controls and long text.

Current web URLs retain Flutter's hash strategy (for example /#/products/1). Clean paths/hosting rewrites and native OS link registration are not claimed. Tablet master-detail, Android/iOS/system-Back execution of this new UI, real screen-reader/IME/exact typing, automated regression and profile/performance checks remain later verification. Broad localization/constants cleanup and final README remain planned. No automated tests/assertions, dependencies, staging or commits changed. Earlier pending detail/repository work was preserved; temporary manual inspection source/server were removed.

## Product detail state checkpoint

Product-ID input validation is now an explicit ProductsRepository.getProduct contract. RemoteProductsRepository and SampleProductsRepository call the same data/product_id_validation.dart helper after checking pre-cancelled controls and before HTTP, fixture lookup or simulated delay. Invalid IDs complete the returned Future with the same CatalogFailure.invalidData message; valid but missing IDs remain notFound. ProductDetailCubit delegates numeric policy, retains the requested ID and supersession/retry behavior, and still checks response identity. Invalid requests may enter the repository method, but do not perform data-source work. Custom repositories and diagnostic fakes must honor this contract. Standalone ProductsApi retains its direct-caller argument guards.

ProductDetailCubit and immutable Equatable ProductDetailState now provide a pure-Dart detail ViewModel using the existing ProductsRepository.getProduct contract. Status is initial/loading/loaded/error, with nullable requested productId, product and CatalogFailure. Each visible field participates in value equality. Whole-state transitions clear stale product/failure; no copyWith or separate selected-ID store is needed.

load(id) always starts a fresh operation, including repeated IDs. retry() repeats the last requested ID; before any request or after close it performs no work. The requested ID remains in loading/error/current-cancellation idle state. Repository-owned positive safe-integer validation runs before HTTP/fixture access; invalid latest requests deliberately supersede/cancel older work and become typed invalidData, retaining the invalid requested ID for deterministic no-I/O retry. Route integration will still validate links and offer friendly recovery before loading. The Cubit also rejects a returned product whose ID differs from the request.

Typed notFound, connection, timeout, server and invalidData failures remain intact; an error status plus failure.kind distinguishes missing products without a second contradictory status/flag. Unknown errors become a user-safe invalidData failure. Only current failures are logged, with operation ID, sanitized failure and diagnostic stack; superseded/cancelled work is silent.

Each detail load owns its own generation/control, independent of catalog/category operations. Publication requires an open Cubit, current generation/control identity and a noncancelled signal. Finally cleanup checks ownership without excluding cancelled controls, releases a still-current loading state to initial/idle with its ID, and never clears a replacement operation. close invalidates/cancels active work and closes only the Cubit, not the shared repository/client.

The Cubit is available for future route-owned injection; no detail provider, screen, gallery, product-card navigation or route was added in this checkpoint. The route remains the source of selected identity, with state.productId recording the request being represented. Details UI/navigation and adaptive master-detail remain next. Automated tests stay in the final stage.

Verification: formatting and full static analysis passed, along with the existing app's production web build. Independent QA executed a temporary external native-Dart console with printed observations only, covering pre-first/closed no-ops, repeated-ID fresh requests/retry, all typed failure kinds, generic and synchronous failures/recovery, stale successes/errors/finally, invalid-ID supersession with no repository I/O, mismatched response identity, current cancellation/idle retry identity, pending close/late outcomes, independent catalog/category controls and immutable/value-equal state. Live RemoteProductsRepository calls loaded product 1 and classified missing product 999999 as notFound. Data/state and architect source reviews found no blockers. No automated tests, assertions or test framework were used. The new Cubit is not yet in the app's route tree; the web build confirms the unchanged application still builds, while detail browser/device integration remains later verification. Temporary console source was removed after inspection.

Focused repository-boundary follow-up: both actual repositories rejected zero, negative and oversized IDs with the same typed invalidData and no remote API/HTTP calls or sample read timers. Pre-cancelled valid/invalid requests yielded RequestCancelled first. Synthetic maximum-safe fixtures were accepted; valid unknown IDs remained notFound. Actual detail Cubit/repository chains preserved invalid-ID supersession/retry and stale-result suppression. Expected errors completed returned Futures consistently. Formatting, analysis, the final web release build and source reviews passed; QA used an external print-only inspection driver, then removed it. No automated tests were added or run.

## Initial loading skeleton checkpoint

Fresh catalog loading now renders six static, decorative card placeholders through CatalogLoadingSliver. It follows the selected list/grid variant, current width and text scale. Search/category controls stay mounted and enabled; initial idle/error/empty recovery is unchanged. Pagination continues to retain real products with its separate footer indicator.

ProductCardLayout shares the existing horizontal/stacked image and content geometry between real and loading cards. ProductCardVariant remains available through product_card.dart via re-export. CatalogRowsSliver shares lazy rows, spacing, padding and responsive columns. This avoids a second layout policy without adding fake Product values, dependencies, animation or data-layer work. Bars use flexible widths, theme fills and text-scaled heights; no fixed total card height is imposed.

One live loading label replaces the decorative subtree in semantics. Placeholder descendants and synthetic row indices are excluded; there are no placeholder actions, images, product names, prices or ratings. Static presentation requires no ticker or reduced-motion branch.

Formatting, final full analysis and a production web build passed. UI/design, architect and quick QA source reviews found no blockers. Coordinator browser inspection checked dark standard/light compact skeletons, narrow320x568 at200% text and scrolling through stacked placeholders, editable/selectable filters, and transition to real products. Changing Beauty while held loading then releasing returned one real product; a fresh inspection session released to six fixtures. Standalone debug/release browsing retained real-card layout, and debug theme/grid switching had no warning/error-level logs. QA independently reviewed screenshot artifacts and coordinator evidence; its own browser execution remained unavailable.

The original temporary external release-control host produced framework focus/view assertions around focus/startup/hot restart. A fresh revised host with its inspection control excluded from focus and the standalone debug app did not reproduce them. No production focus workaround was added. Temporary inspection code/server were removed. Pagination separation is source-reviewed in this checkpoint; native screen-reader/input, automated tests, device/performance and full-product acceptance remain final-stage checks. Details and adaptive navigation are next. No dependencies, README, staging or commits changed.

## Catalog UI integration checkpoint

CatalogScreen now connects the reusable search input and category chips to the existing Cubits. The screen owns/disposes its search controller, preserves raw drafts and pending debounce across category/page/theme changes, and only synchronizes genuine external committed-text changes. Enter and clear use the same commit callback; ProductSearchField remains the only debounce owner. Categories load on their first UI consumer, expose independent loading/idle/empty/error/retry, and keep All products and a missing-selected-category fallback usable.

One vertical CustomScrollView contains filters, status, lazy product slivers and pagination feedback. CatalogCategoryFilters isolates metadata presentation; CatalogProductSliver preserves natural-height standard/compact rows. Filter-aware empty recovery, initial idle load actions, loaded count, footer loading and explicit same-cursor retry are connected. Asynchronous status/footer and loaded-count messages have live-region semantics; loaded rows remain outside status announcements.

Pagination checks current state and remaining extent at roughly 320 logical pixels, then coalesces work after layout. Metrics-only changes request a frame explicitly. Recheck after raw cursor/busy changes, layout/resize and duplicate-only batches; stop on busy, error or exhaustion. Query changes/forced reload clear both layout offsets and reset to the top only after a valid matching position exists. Layout switches save/restore bounded per-variant offsets without recording stale pixels during rapid pending restores. Append, theme and showcase navigation retain browsing position.

UI/design, data/state and architect reviews identified and resolved pending reset consumption, per-layout position retention, missing frame requests, rapid local-query marker consumption and asynchronous announcement gaps. Formatting, full analysis and production web builds passed. Coordinator-executed browser checks covered live red title results/category intersection, no-match/clear, independent category/product retries, retained footer errors/same-cursor retry, duplicate-only automatic continuation, raw exhaustion, both layouts/themes, showcase Back, filter reset across layouts, tall-viewport refill/resize and narrow/short layouts with 200% text. Controlled fixtures were injected through a temporary external inspection entrypoint, not shipped application diagnostics or automated tests.

QA now participates in manual acceptance and evidence review. Its browser controls were unavailable in this checkpoint, so the coordinator executed browser checks and QA independently reviewed source, three screenshot artifacts and the reported call/cursor observations; the external QA record distinguishes these roles. Per-character Flutter-web accessibility input automation was unreliable; atomic editing, Enter, clear and result transitions were observed, while exact typing/debounce timing, native IME/soft keyboard and real screen-reader behavior remain unverified.

The subsequent skeleton checkpoint completes the initial placeholder requirement. Remaining work includes product details/navigation, adaptive master-detail behavior and final automated/native/accessibility/performance verification. Broad constants/localization cleanup remains deferred. No dependencies, README, automated tests, staging or commits changed; pre-existing unstaged state-management work was preserved.


## Catalog and category state checkpoint

CatalogCubit now exposes `setSearch`, `selectCategory`, `loadMore` and `retryLoadMore` alongside forced `load/retry`. Search changes preserve the category and category changes preserve committed text. CatalogQuery equality suppresses casing/outer-whitespace duplicates; the input component remains the only debounce owner. Effective filter changes and forced reloads increment a generation, cancel the previous control, clear rows/cursor/failures and fetch from zero.

CatalogState now includes `isLoadingMore`, `paginationFailure` and `copyWith` with explicit nullable-failure clearing. Its collections remain immutable and every visible field participates in Equatable equality. Pagination starts only from loaded state with remaining raw data and no active operation. It retains rows and status while busy, merges IDs in existing-first order, and advances the raw cursor even when a complete batch contributes no new IDs. An exhausted empty continuation retains the loaded rows. A failed page preserves query/rows/cursor/hasMore, exposes a footer failure and blocks automatic repetition; `retryLoadMore` retries the same cursor. Repository page metadata is checked for invalid progress/consistency before publication; totals are not compared across separate calls.

Publication requires current generation, current control identity, an open Cubit and a noncancelled control. Finally cleanup checks ownership without requiring a noncancelled control, so it releases a still-current busy operation while never clearing a newer request. Unexpected current cancellation is silent and returns an initial load to initial/idle or a page to loaded/not-busy; normal production cancellation occurs on replacement/disposal. UI integration must distinguish idle from an active load.

CategoriesCubit/CategoriesState now own independent initial/loading/loaded/empty/error metadata. `load` shares the actual in-flight Future and reuses loaded/empty metadata; `retry` deliberately cancels/replaces the operation. A Completer is installed before work begins to keep coalescing correct even for synchronous repository failures. Category controls, generations, failures and close cleanup do not affect product requests. App composition registers a lazy category provider above the router: the first category consumer starts loading, with the subsequent UI checkpoint adding the first real category consumer.

Formatting/full analysis and a production web build passed. Temporary external console inspection printed controlled outcomes for duplicate queries/IDs, overlapping pages, duplicate-only cursor progress, exhausted empty continuation, typed footer failure and explicit retry, stale successes/errors/finally, invalid page data, current cancellation and pending-load close, immutable state, category coalescing/caching/replacement, synchronous/generic failures and independent cancellation. Live Cubits loaded 20 then 40 unique products, 24 categories, nine title-only red matches and only Red Onions for red plus groceries. These are manual inspection results, not automated test coverage. Data/state and architect source reviews found no blockers. Automated tests remain final-stage work.

The subsequent catalog UI checkpoint now wires the actual search input, category strip, inline category retry, near-bottom/post-layout pagination refill, footer retry and effective-query scroll reset. Detail state/navigation remain later work. No dependencies, README, automated tests, staging or commits changed.

## Enhancement A - debug component showcase

Showcase implementation lives under lib/debug/. A catalog app-bar button opens /debug/components only when kDebugMode is true; component detail routes live below that path. Non-debug builds register neither the button nor the showcase routes. The index lists currently implemented design-system components and their named examples; ProductSearchField and CategoryChip are registered.

Detail pages render real components with visual-state examples, optional-action feedback, light/dark switching through the existing ThemeCubit, width presets, and system/100%/150%/200% text settings. Examples are separate from catalog fixtures and repository/Cubit logic. They use bundled images and deterministic fallbacks/loading, with no API calls. A debug-only pending asset bundle holds a ProductImage load for inspection and evicts its pending cache entry on disposal. ProductImage's first-frame loading feedback is shared production behaviour, not a debug switch.

The showcase now contains eight components and 73 named examples, including 11 ProductSearchField examples and eight CategoryChip examples. Formatting/analysis, debug/release web builds, and manual navigation/settings/action/loading/release-exclusion checks passed. Continue mandatory component/API work after this increment. Automated showcase/routing regression checks and constants/localization cleanup remain final-stage work; the showcase is a manual development tool, not test coverage.

## Possible future improvements

- [ ] Review wide-desktop master-detail proportions. The current fixed 380px catalog becomes visually narrow in large browser windows, while the remaining detail pane centers content capped at 720px and leaves large empty margins. Consider a separate desktop breakpoint with a proportionally wider, bounded catalog and an image/information layout using two columns when space allows. Keep the existing tablet proportions, centralized layout policy, route-owned selection, state retention, keyboard access, and large-text behavior. Exact desktop dimensions and acceptance checks remain undecided. This is a recorded visual issue/optional improvement; implementation is deferred rather than automatically included in final cleanup.


- Consider a domain/use-case layer between Cubits and repository contracts when workflows become complex, are reused by multiple Cubits, or combine data from multiple repositories. This remains compatible with MVVM and is optional after mandatory requirements, not an automatic final-cleanup task. A possible GetCatalogProductsUseCase should encapsulate meaningful application policy/orchestration. If query orchestration moves, preserve coordinated title/category filtering, continued raw-page scanning, cursor progress, overfill retention, atomic batches, and one operation deadline. A smaller alternative is a shared pure title/category matching policy for the sample and remote repositories. Implementation remains deferred.

- Reconsider read-only search input only when a concrete flow needs a visible, selectable query that cannot be edited (for example, a locked saved search). It is intentionally absent from the current component API and showcase; enabled/disabled behavior remains supported.

## Final cleanup progress

### Constants and shared rules (implemented)

- SafeInteger owns the shared native/web integer ceiling, range checks and integral JSON-number parsing. The parser, API, repository and catalog page checks reuse it; each boundary retains its existing failure type/message. Product-ID domain validation remains in product_id_validation.dart, with no new detail-UI/Cubit ID check.
- CatalogPagination owns the default batch size. ProductsApiConfig and ProductsEndpoints own request timeouts, the overall operation budget, headers and HTTP paths. Transport paths remain separate from application routes.
- CatalogQuery.matches owns final title/category matching for remote and sample repositories; the sample source still deliberately simulates broader description search before applying that predicate.
- ProductRating owns rating bounds and raw-value color thresholds; DiagnosticLevel names the existing logging severities. Pricing and descriptive fallback helpers remain reused.
- AppTokens now owns accent foreground and normal/emphasized border widths plus shared focus/hover overlays. These preserve the existing colors, dimensions and opacity values, including copyWith/lerp support for configurable tokens.
- Remaining meaningful icon sizes, text line limits, component/preview dimensions, debounce and sample-delay defaults have contextual names. Bundled sample-image paths live in fixtures/sample_product_assets.dart and are reused by sample data and debug previews.
- Removed replaced private validation helpers and the repeated matching predicate. Full analysis reports no unused declarations. Public fixture factories/injection seams remain intentional; simple index arithmetic, explicit sample values and API schema keys stay local.

Formatting, full analysis, release web and Android debug builds passed. Print-only external inspection covered numeric/rating boundaries, parser fallbacks, encoded endpoints, defaults, sample filtering and live20+20 pagination/Red-Groceries matching. Browser smoke checks and Pixel7Pro/Android17 manual launch, native typing/Enter, combined red/Beauty filtering, detail, Android Back and light/dark appearance were checked. External QA notes distinguish these observations from deferred automated coverage. No tests, dependencies, README, staging or commits changed.

### Assessment-required automated tests (implemented)

The compact baseline contains ten tests using the existing flutter_test dependency. The PDF specifies three coverage areas rather than an exact total number of tests.

| Required area | Tests | Coverage |
| --- | --- | --- |
| State-management unit tests | 4 | CatalogCubit initial/loading/loaded, empty results, failure/retry and pagination with duplicate-ID merging. |
| Model parsing/data-validation unit tests | 4 | Valid API fields, optional-field fallbacks, rejected IDs and raw cursor advancement while malformed records are skipped. |
| Design-system widget tests | 2 | RatingBadge content/color/accessibility label with light theme; CategoryChip callback and parent-owned selection with dark theme. |

Files live under test/features/catalog/ and test/design_system/components/, with one small shared theme wrapper under test/support/. Run `flutter test` from the project root. Tests use an in-memory repository stub and decoded maps; no HTTP, fixture delays, mocks package or additional dependencies are needed.

All ten tests and full analysis passed; test sources are formatted. This is the selected minimum-scope baseline, not exhaustive coverage of all Cubits, API/repository failures, cancellation/deadlines, search races, routes, responsive layout or every component state. Those remain possible regression follow-ups alongside the remaining manual/platform verification. No production code, dependency files, README, staging or commits changed for this checkpoint.


### Localization (next checkpoint)

- Move app-owned visible text, tooltips, fallback/error messages, accessibility labels, plural forms, and number/currency presentation into localization resources using Flutter's localization workflow. Establish English resources first; additional translations require an explicit language decision.
- Keep models/repositories/Cubits independent of Flutter localization. Map typed failure kinds to localized messages in presentation; do not expose diagnostic messages directly as UI text.
- Keep route identifiers, asset paths, developer diagnostics, and API/sample product content separate from translatable interface copy.
- Recheck remaining literals, update documentation, and continue final-stage automated tests, builds, accessibility/layout and device/performance checks.

## AI-assisted development workflow and final documentation

Maintain an undated development overview outside the repository in `ai-development-overview.md` while implementation is in progress. Add it under docs/ during final handoff and write the final README at that stage.

Use concise milestone summaries covering the development approach, important decisions, completed functionality, corrections, AI assistance, and observed verification results. Keep the record at an overview level rather than logging every request or copying the conversation. Identify developer decisions and changes, AI suggestions, and material AI-generated implementation accurately.

Follow an incremental development loop:

1. Define a small checkpoint and observable completion criteria.
2. Discuss the proposed approach, important alternatives, and Dart/Flutter concepts as needed. The developer directs scope and acceptance decisions.
3. Implement a scoped, runnable change, review its responsibilities, and run appropriate manual/static/build checks. Add automated tests during final verification.
4. Update the external overview after meaningful milestones, retaining completed results and significant refinements. Distinguish completed work and executed checks from planned work.
5. Leave staging, commits, and pushes to the developer.

AI supports the developer with architecture suggestions, explanations, implementation assistance, debugging, and review. Keep the overview specific to ProductListTestApp and update it as actual work is completed.

## Completion checks

Verify rapid query changes, Enter/clear behavior, combined filtering across initially nonmatching pages, pagination failures, direct/invalid detail links, and preserved query/scroll position. Check narrow and short screens, larger text, both themes, the exact responsive breakpoint, and image fallbacks.

Record measured results and outstanding checks honestly. iOS build/device verification requires a Mac with Xcode; generated platform files alone do not demonstrate a working iOS build.

At final handoff, write the README sections for setup, architecture, design-system rationale, limitations, spec issues/assumptions, AI usage, and approximate time spent. Add the externally maintained development overview under docs/ at that stage.
