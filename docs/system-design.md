# ProductListTestApp system design

This document describes the current implementation and contracts. The app uses remote DummyJSON data; the temporary sample repository/catalog has been removed. Development previews live under lib/debug/component_showcase/ with one bundled image. The implementation plan tracks delivery status; the external AI overview and Git history retain implementation chronology.

## Current source structure

| Location | Responsibility |
| --- | --- |
| lib/app/ | Composition, router/navigation, adaptive shell, app theme state and shared app controls. |
| lib/core/ | Pure-Dart failures, cancellation and shared numeric/rating/pricing/text/image URL policies. |
| lib/design_system/ | Theme tokens and configurable components without repositories or navigation. |
| lib/features/catalog/models/ | Immutable products, categories, query and pagination values. |
| lib/features/catalog/data/ | Repository contract/remote source, HTTP/API, defensive mapping and raw pages. |
| lib/features/catalog/presentation/ | Cubits/states, screens, feature widgets and display mapping. |
| lib/debug/component_showcase/ | Development preview pages/examples and showcase asset constants. |
| test/ | Focused state/parser/widget tests, local doubles and shared theme setup. |

The default path is CatalogScreen -> CatalogCubit -> ProductsRepository -> RemoteProductsRepository -> ProductsApi -> Dio -> DummyJSON. Categories and detail use independent Cubits over the same repository. The startup repository override remains caller-owned for tests/custom entrypoints; a shipped sample implementation is unnecessary.

## Test and verification scope

Ten tests cover the assessment baseline: four CatalogCubit transition tests, four ProductParser validation/parsing tests and widget tests for RatingBadge and CategoryChip. They use the existing flutter_test dependency, a local stub and real themes without HTTP. This is not exhaustive async/repository/routing/responsive coverage. Final build/manual/profile results and limits are recorded in verification.md and README.md. Localization and rating precision are deferred; frame-budget exceedances and unverified platform/accessibility cases remain follow-ups.

## 1. Scope and constraints

Build a Flutter client consuming the public DummyJSON Products API over HTTPS, with base URL `https://dummyjson.com` ([API reference](https://dummyjson.com/docs/products)). There is no application backend, authentication, checkout, or payment flow. The mandatory scope is catalog browsing, title search, a single category filter, infinite scrolling, product details/deep links, a themed component library, and phone/tablet layouts.

Android and web are the local delivery/verification baseline. Retain portable Flutter code and iOS scaffolding; native iOS build/run signoff requires a Mac with Xcode and remains explicitly pending until performed. Other generated desktop runners are scaffold support rather than verified product targets. When networking is introduced, declare Android Internet permission in the main manifest and verify browser CORS against the actual serving origin alongside web route fallback.

The verified development baseline is Flutter 3.47.8 with Dart 3.13.7. The root package requires Dart ^3.13.7, and the current lockfile records a dependency floor of Flutter >=3.47.0. Both constraints must be satisfied; the dependency floor alone does not establish that Flutter 3.47.0 is a verified supported app version. Record the verified SDK pair in final setup documentation. Supporting another reviewer SDK requires a separate compatibility check and, if necessary, dependency resolution; editing the lockfile alone does not establish compatibility.

Keep the design proportionate to the assessment's 3-4 hour scope. Offline data persistence, advanced animations, additional state-management frameworks, and a separate use-case layer remain optional/deferred. The developer explicitly selected the debug component showcase during component implementation; its scope is described below.

## 2. Components and dependency rules

```text
main.dart -> app composition and long-lived dependencies
                   |
                   +-> GoRouter -> catalog/detail Views
                   |                       |
                   |                    Cubits + immutable state
                   |                       |
                   +--------------> ProductsRepository contract
                                           |
                                   RemoteProductsRepository
                                           |
                                       ProductsApi -> Dio -> DummyJSON

Views also use shared theme tokens and configurable design-system widgets.
Cubit state notifications travel back to Views through BlocBuilder.
```

This is MVVM-style: Views render and forward actions; Cubits provide the ViewModel responsibility; models/repository/API supply data. Widgets receive values and callbacks. Cubits expose state/actions and use constructor-injected repositories; they do not navigate or depend on BuildContext. Models and repository contracts remain independent of Flutter widgets, GoRouter, and Dio types. The remote implementation handles HTTP-specific concerns behind those contracts.

The existing StatefulWidget app owns its GoRouter once and disposes it when removed. Do not recreate a router or client in build(). Introduce feature folders with their first real files.

Use cases are recorded as an optional future extension between Cubits and repository contracts. Reconsider them for complex/reused workflows or combining multiple repositories; MVVM remains the presentation pattern. The current repository contract continues to return complete filtered batches. Moving query policy into a use case would require preserving raw-page scanning, atomic cursor/results, overfill, and the single operation budget together; filtering only one retrieved page would break sparse-result behavior. CatalogQuery.matches already supplies the pure title/category predicate. A use-case layer remains optional; see the implementation plan's Possible future improvements.

## 3. State ownership and lifetime

| State/resource | Owner | Lifetime and reset rule |
| --- | --- | --- |
| ThemeMode | App-level ThemeCubit | Starts from the system preference; user choice survives navigation/rebuilds, resets on process restart. |
| Route and selected product ID | GoRouter | `/products` or `/products/:id` is the source of truth. There is no second mutable selected-ID store. |
| Loaded products, committed query/category, cursor, loading/failure | CatalogCubit | One catalog session scoped above detail routes and layout changes. A new effective filter resets products/cursor and scroll. |
| Category metadata and its loading/failure | CategoriesCubit | Loads once per app session; retries independently. |
| Product detail and detail failure | ProductDetailCubit keyed by ID | Created for the active detail route; reloads for a new ID, closes on leaving that route. |
| Draft search text, debounce timer | Search widget | Retained with the catalog View; synchronized when committed query is changed externally; timer disposed with the widget. |
| Scroll controller/offset and list/grid choice | Catalog View | Retain the catalog subtree across detail navigation and phone/tablet switches. Reset scroll for effective filter changes. |
| Gallery controller/index | Detail View keyed by ID | UI-local; starts at the first image for a new product. |
| Dio and repository | App composition root | One shared instance of each per app lifetime. |

No process-death restoration, filter persistence, or persisted theme preference is promised in the baseline. A cold detail URL starts default catalog filters and fetches its product by ID, even when the item is absent from the loaded catalog.

Composition owns disposal: close feature Cubits (invalidating generations and cancelling active work) before closing Dio; dispose route/UI controllers with their scopes. Providers may manage the lifetimes they create. The repository does not close a Dio instance it did not create.

## 4. Data and repository contracts

### Product and category data

Use one immutable Product model for the fields needed by cards and details. It contains a positive integer ID; title, description, category and brand; nullable valid price/rating/stock; a valid discount percentage; and valid image URLs. Category contains a stable slug and a display name. API field names and validation are handled at the data boundary.

Defaults: untitled product, unknown brand/category, and a readable missing-description message. Unknown rating/stock stay unknown rather than becoming zero. Prices must be finite and >=0; otherwise show Price unavailable and log an error. Discount must be finite and between 0 and 100; invalid values become no discount. Assume USD and treat API price as original price. Share the discount calculation/formatting between cards and detail. Ratings outside 0-5 and negative/invalid stock become unknown.

Reject invalid IDs and log skipped records. Invalid or broken image URLs use a placeholder and warning. Validate response envelopes separately: malformed JSON/list metadata is a data failure, not empty content. For a nonempty raw HTTP page with zero parseable Product records, fail the whole logical batch as invalidData. This rule is evaluated before local title/category filtering. A parseable page with zero local matches continues scanning; an empty raw page at reported exhaustion is normal completion.

### Repository contract

```dart
abstract class ProductsRepository {
  Future<ProductPage> getProducts({
    required CatalogQuery query,
    int skip = 0,
    int limit = 20,
    RequestControl? control,
  });

  Future<List<Category>> getCategories({RequestControl? control});
  Future<Product> getProduct(int id, {RequestControl? control});
}
```

- **CatalogQuery:** immutable trimmed text and optional category slug. Its effective key uses lowercase text plus the category slug, so casing/outer whitespace alone does not refetch results. The search widget keeps the user's draft text separately.
- **ProductPage:** immutable `products`, `nextSkip`, `hasMore`, and `remoteTotal`. The total describes the remote source query before local title/category filtering; UI uses loaded count instead of an invented filtered total.
- **RequestControl:** a small pure-Dart per-operation cancellation signal. The owning Cubit cancels it on replacement/disposal; the remote implementation links it to an effective operation scope and Dio cancellation. Each catalog, category, and detail operation has an independent control, and one logical catalog batch shares one scope across every raw page. A supplied control is used for one operation only; an omitted control still gets internal deadline enforcement. RemoteProductsRepository bridges the signal to its HTTP token/deadline scope.
- **CatalogFailure:** typed connection, timeout, server, notFound, and invalidData failures with user-safe messages. Failure exceptions are caught by Cubits and represented in state. Superseded/cancelled work is an internal control outcome, not a visible error.

The API service selects `/products`, `/products/search?q=...`, `/products/category/{slug}`, `/products/categories`, or `/products/{id}`, encoding parameters through Dio. It validates responses and derives the raw next offset before dropping malformed records. The repository applies title/category rules and deduplication.

### Filtering and cursor semantics

Search is a case-insensitive title substring match. Keep server-side search, then filter titles locally because the remote search also matches descriptions. With a category, intersect the title matches with that category. Without search, use the category endpoint directly when selected.

Start with raw pages of 20. Advance skip by every raw record consumed, including filtered-out or malformed records. Continue until at least a display batch of unique matches is collected or raw results are exhausted. Return all matches from consumed pages, even if this exceeds 20; truncation would lose results unless an additional buffer were introduced.

Use the response total and cursor progress to determine hasMore. Reject inconsistent/non-progressing pagination rather than looping. An empty raw page is valid exhaustion when its cursor is at/beyond the reported total. Do not emit an empty search result just because an intermediate raw page has no local matches.

A logical load/batch is atomic: if a later scanned page fails, publish a failure without advancing the caller's cursor. Retry starts from the original input cursor. Existing visible pages remain intact during a pagination failure.

## 5. Request flows and screen states

Catalog state contains: status (initial/loading/loaded/empty/error), committed CatalogQuery, immutable products, nextSkip, hasMore, isLoadingMore, and separate initial/pagination failures. Pagination is allowed only for loaded state with hasMore and no active next-page operation. Preserve a consistent state: empty means completed filtering with zero products and no remaining raw pages; loadingMore never replaces loaded content with initial skeletons.

### Initial load and category metadata

Create catalog/category Cubits at catalog-session scope. Start their loads independently. The category provider is lazy: its first consumer creates CategoriesCubit and calls load; direct showcase startup still performs no unused category request; CatalogCategoryFilters is now the normal catalog consumer. Category load returns the active Future while busy and reuses loaded/empty metadata. Explicit retry cancels/replaces the category operation; product state is unaffected. Catalog moves initial -> loading -> loaded, empty, or error. Category failure shows an inline retry while product browsing remains available.

### Search and category changes

The search component owns one 300ms timer. Enter cancels the timer and submits immediately; clear commits immediately. Suppress duplicate effective queries. Selecting a category applies it to the latest committed query; any pending debounced text subsequently applies with the current category.

On an effective filter change, increment the catalog generation, cancel the old operation, capture the new immutable query, clear products/cursor, reset scroll after layout safely, and load from skip=0. A success or failure can update state only if its captured generation still matches and the Cubit remains open. Cancellation is an optimization; generation checks remain the correctness guarantee.

### Pagination and overlapping requests

When remaining scroll content drops below approximately 320 logical pixels, request the next batch. Keep current products, set isLoadingMore, and capture query/cursor/generation. Merge results by ID, retain server order, then update nextSkip/hasMore and clear pagination busy/failure state. Pagination uses the current generation; it does not start a new result set.

A new filter invalidates any pending old page. After page layout, recheck whether the viewport needs more content, including cases where only the raw cursor advanced. Automatic filling stops on failure or exhaustion; errors require explicit retry rather than an automatic retry loop.

### Detail selection and responsive navigation

At available safe-area width >=768 logical pixels, use a persistent catalog panel around 380px wide and a detail panel. `/products` shows a selection prompt; selecting an item updates `/products/:id` and the panel. Below the breakpoint, show the matched detail route while retaining the offstage catalog in its fixed shell slot. Use the same measured breakpoint for layout and Back visibility. CatalogShell keeps catalog and child Navigator in fixed slots with bounded constraints. Hidden panes exclude focus/semantics and disable tickers; hidden catalog auto-fill pauses and rechecks when visible. Child prompt/detail/recovery routes use NoTransitionPage so removal does not wait on muted transition tickers. Visible reflow may clamp scroll offsets; exact item anchoring is not promised.

Parse decimal route syntax to an integer before requesting detail; repository validation owns the positive/safe numeric range. Fetch detail independently of the current catalog, using a detail-specific generation/control. Keep the route's ID when catalog filters change, even if that product leaves the visible results; filtering does not silently navigate away. Back restores the catalog; a cold detail entry has a catalog fallback. Resizing preserves the route, catalog query, products, and scroll rather than creating a new feature session.

Unknown routes/invalid IDs get a friendly recovery action. A product 404 gets a product-not-found message and a way back to the catalog. The current app uses hash URLs and has HTTP-hosted cold/reload evidence. If clean web paths are selected for deployment, they require Flutter's path URL strategy plus server fallback to index.html; verify a real HTTP-hosted reload when navigation is completed. Widget-level route checks alone do not verify hosting behavior.

## 6. Failures, retry and observability

| Situation | Visible result | Recovery |
| --- | --- | --- |
| Initial catalog connection/timeout/server failure | Full error state; no stale rows for the new filter | Retry current query from skip=0. |
| Next-page failure | Keep current rows and show inline footer error | Retry same nextSkip; merge only complete batches. |
| Valid exhausted query without matches | Empty state | Change/clear filters. |
| Category request failure | Inline category warning | Retry categories independently. |
| Invalid envelope/all malformed records | Readable data error | Explicit retry; log diagnostics. |
| Invalid/missing product or unknown route | Recovery state | Browse products; no automatic repeated 404 requests. |
| Missing field, invalid price/image, failed image fetch | Readable fallback within the product | Other valid content remains usable. |
| Cancelled/superseded response | No new UI error/state | Latest operation owns the outcome. |

Use 10s connection and 15s receive timeouts, plus a 30s overall deadline for one logical catalog scan. Start the overall timer once at repository-call entry, including when no RequestControl is supplied; do not restart it per raw page. Link the optional caller signal to one effective operation scope and one Dio CancelToken used by all subrequests in that batch. Check cancellation before the first request and between scanned pages; a pre-cancelled call performs no HTTP work, and cancellation aborts an in-flight request.

Record the first cancellation reason in that scope: caller supersession/disposal yields a silent internal cancellation outcome; deadline expiry yields a typed timeout failure. Map a deadline-triggered Dio cancellation to timeout rather than swallowing it as ordinary cancellation. Per-request connection/receive timeouts also map to timeout. Generation checks still suppress any outcome from an obsolete operation.

In finally cleanup, cancel the overall timer and detach caller-cancellation listeners for success, failure, and cancellation. Discard partial matches/cursor advancement on a failed batch. Retry creates a fresh operation scope and budget. Do not keep issuing subrequests after cancellation, deadline, or non-progress. No automatic request retries in the baseline.

Log operation type, query/category/cursor or product ID, error category, and diagnostic stack traces where useful. Log malformed records and image warnings once per offending item/URL where practical; do not log errors from build() on every frame. Normal cancellation is not an error. Avoid logging complete product/review payloads.

## 7. Caching, performance and visual system

Baseline product data is session state: CatalogCubit retains its loaded pages, CategoriesCubit retains its metadata, and the active detail Cubit retains its current product. There is no repository data cache, database, offline indicator, or stale-data fallback initially. Reopening a detail route fetches by ID again. This makes freshness and invalidation explicit without an extra cache lifecycle.

Build list/grid items lazily and retain only fetched metadata for the active query; do not preload the whole catalog. Use thumbnails for cards and lazy gallery pages, with decode dimensions appropriate to the display size where supported. ProductImage now encapsulates image loading with Flutter memory caching. Evaluate an additional caching package only if persistent native disk caching is introduced. Native image disk caching and Flutter memory caching are distinct from persistent offline web caching, which is not promised.

ThemeExtension holds the agreed colors, spacing, radii and semantic rating colors, with copyWith/lerp. Material ColorScheme and reusable controls derive from the same tokens. Components accept display values and callbacks, support light/dark and standard/compact variants, and do not know repositories. Ratings include numeric/semantic labels, so meaning does not depend on color alone. Keep tap feedback, keyboard focus, image semantics, readable contrast, short-height layouts and larger text in the acceptance checks.

Measure scrolling with 100+ products on a representative device during final verification. Lazy builders and caching are implementation choices, not proof of zero dropped frames.

## 8. Acceptance criteria and delivery decisions

These are full-product acceptance checks, not a claim that every platform and edge case has been certified. The ten-test assessment baseline is implemented. Use source review, static analysis, appropriate builds and scoped manual checks for remaining verification.

| Requirement | Observable completion criterion |
| --- | --- |
| Theme and component library | All required APIs/variants render in both themes with fallbacks and usable large text. |
| Search | Debounced input, Enter and clear work; red excludes description-only matches such as Eggs. |
| Combined category/search | Later matching raw pages are reached; no false empty state, lost overfill matches, or duplicate IDs. |
| Pagination | One request per result set at a time; raw cursor advances; exhaustion stops loading; failed next page preserves content. |
| Asynchronous safety | Older success/failure cannot overwrite a newer query/detail; pre-cancelled calls send no request; in-flight work aborts; one batch deadline applies with or without caller control; timeout stays visible while supersession is silent; timers/listeners are released. |
| Validation and failures | Missing fields/invalid prices/images are safe; malformed envelopes and 404s have distinct recovery. |
| Routing | Root, catalog, valid/invalid/cold detail, unknown URL, Back, and HTTP-hosted reload behave deliberately. |
| Responsive behavior | Phone/tablet layout and exact 767/768 available-width boundary work; filters/scroll survive details and resize. |
| Performance/platforms | Observe 100+ item scrolling and image loading; record actual Android/web builds and any iOS verification separately. |
| Tests and handoff | The required model/state and two-component widget baseline passes; remaining verification and final README/history reflect actual results. |

The required reusable components, catalog/detail integration and adaptive presentation are implemented. The developer handles staging, commits and pushes. Remaining checks are tracked separately from completed behavior.

## 9. Presentation reuse and debug boundaries

ThemeToggleButton owns the shared theme icon, tooltip and callback used by catalog and showcase. AppTokens supplies palette, accent foreground, spacing, radii, border widths, focus/hover overlays and semantic rating colors. ProductCard/RatingBadge/ProductPrice/ProductImage and the ErrorState/EmptyState/StateMessage composition remain display-driven. CatalogRowsSliver and ProductCardLayout share loaded/skeleton geometry.

ImageUrls.remote owns HTTP(S) syntax normalization for ProductParser and ProductImage. The parser accepts remote URLs; ProductImage separately permits bundled assets for previews and owns loading/failure fallback. Product canonicalizes image ordering/deduplication; ProductPresentation chooses thumbnail fallback; ProductGallery owns its controller/index. These are distinct responsibilities.

Debug routes and entry button stay guarded by kDebugMode. ShowcaseAssets names one real image and a deliberately missing path for failure previews. Only assets/images/showcase/ is declared in pubspec.yaml; its small image is still packaged by Flutter in all build modes even when debug routes are absent. Catalog fixtures, simulated-delay/error scenarios and unused thumbnails are removed.

## 10. Review decisions and follow-ups

A conservative local-import audit found no cycles, no unreachable Dart source after sample removal, and no Flutter/GoRouter/debug imports in catalog models, data or Cubits. Design-system components do not import feature repositories/app navigation. The feature-based structure remains suitable; empty domain/use-case folders would add indirection without a current consumer.

Similar generation/control/cleanup code in the three Cubits stays explicit because their lifetimes differ: catalog replacement/pagination, coalesced category metadata and per-ID detail. Parser/repository/Cubit page checks protect different contracts; shared facts live in helpers, but guards are not removed solely because they look similar.

Technical docs describe the current design rather than repeating checkpoint logs and retired sample-startup instructions. Cupertino Icons is retained because removing it produced a Flutter adaptive-font warning despite no direct app reference. The repository override and small test doubles remain useful seams.

Remaining work: English localization and text/model/presentation boundaries, broader async/route/adaptive tests if needed, real accessibility/performance/platform verification, and final README/history delivery. Wide-desktop proportions and rating rounding versus raw color thresholds remain recorded improvements, not completed fixes.
