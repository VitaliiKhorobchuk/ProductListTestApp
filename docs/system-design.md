# ProductListTestApp system design

This is the design baseline for the product-catalog assessment. The implemented foundation now includes startup, centralized routing, and one working offline MVVM catalog slice: immutable models, a repository contract and fixture-backed implementation, CatalogCubit/state, app-level injection, a state-rendering View, and token-based light/dark themes with an app-level switch. The remaining full-product behaviors below are the target design, not a claim that networking or every screen/action is complete. The [implementation plan](implementation-plan.md) defines the delivery sequence.

## Implemented MVVM architecture example

The sample demonstrates the complete dependency path with six offline products:

`CatalogScreen -> CatalogCubit -> ProductsRepository -> SampleProductsRepository -> sample_product_data`

Results flow back as immutable ProductPage/Product values, then CatalogState, then BlocBuilder output. The View sends load/retry actions and renders initial/loading/loaded/empty/error states. It does not read fixture data or construct a repository.

| Responsibility | Implemented files |
| --- | --- |
| Model | `features/catalog/models/product.dart`, `category.dart`, `catalog_query.dart`, `product_page.dart` |
| Data contract and sample source | `features/catalog/data/products_repository.dart`, `sample_products_repository.dart`, `sample_product_data.dart` |
| ViewModel and state | `features/catalog/presentation/cubit/catalog_cubit.dart`, `catalog_state.dart` |
| View | `features/catalog/presentation/screens/catalog_screen.dart`, `presentation/widgets/sample_product_tile.dart` |
| Composition | `app/app.dart` injects a repository and lets BlocProvider create/close the Cubit above the router. |
| Shared request/failure types | `core/request_control.dart`, `core/catalog_failure.dart` |

Paths above are relative to lib/. CatalogCubit imports the pure-Dart bloc package; catalog Flutter integration is confined to app/View code through flutter_bloc. The app-level ThemeCubit is separate from the catalog feature and uses Flutter appearance enums. Equatable supplies value comparisons. The app accepts a repository override at startup. The default binding uses SampleProductsRepository; the later remote implementation can replace it without changing the View's data source knowledge.

The sample repository implements product pages, categories, and single-product lookup from fixtures. It simulates broad source search before local title/category filtering and retains raw cursor semantics, but the View currently exposes only initial load and reload. `remoteTotal` is a simulated source count, not observed server metadata. The fixtures are trusted in-memory model values; JSON parsing, transport errors, API record validation, Dio cancellation mapping, and remote operation deadlines remain later work. The sample's 500ms delay is cancellable and cleans up its timer/listener.

Manual scenario commands from the configured project terminal:

```powershell
flutter run -d chrome
flutter run -d chrome --dart-define=SAMPLE_CATALOG=empty
flutter run -d chrome --dart-define=SAMPLE_CATALOG=error
```

Stop and relaunch to switch compile-time scenarios. The default is loaded sample data; empty returns no fixtures; error deliberately fails each load, so Retry repeats that configured failure rather than simulating recovery. The repository also accepts an injected fixture list, including an empty list. Screens contain no error-simulation controls. Current manual verification covers the default six-product display and repeated reloads; empty/error scenarios are available but have not yet been launched manually. Automated tests remain deferred.

## Implemented theme foundation

`design_system/theme/app_tokens.dart` defines immutable ThemeExtension tokens for the agreed palettes, semantic rating colors, 8px base spacing, and 12px/default and 8px/small radii. Its copyWith and lerp cover every token. `app_theme.dart` derives cached Material ThemeData and control defaults from these tokens; Views access them through context.tokens.

The app-level `app/theme/theme_cubit.dart` owns ThemeMode, initially system, and exposes setMode/toggle actions. ThemeCubit uses Flutter appearance enums but has no BuildContext or global platform lookup. The catalog reads it from BlocProvider when the switch is pressed, supplying the current MediaQuery platform brightness; its icon/tooltip still follow the effective theme. Toggle resolves the current Cubit selection, so repeated actions do not depend on a possibly animating theme brightness. The router only constructs the screen and forwards no theme callback.

ProductListTestApp provides ThemeCubit and CatalogCubit above a BlocBuilder that passes the selected mode to MaterialApp.router. The providers retain ownership/automatic closure and remain outside the appearance rebuild boundary. Router and repository remain initState-owned. Toggling selects explicit light/dark mode for this session; setMode can restore system mode, but no return-to-system selector or persistence is exposed yet. Appearance changes do not invoke catalog loading. The sample list has a stable PageStorageKey for scroll retention.

Manual browser verification after the ThemeCubit refinement observed the system-dark initial appearance and repeated light/dark switches, including consecutive clicks, with the same catalog URL, six products, CatalogCubit identity, loaded-state identity, and scroll position. A temporary entrypoint outside the project logged BlocObserver lifecycle/state events: ThemeCubit emitted system-to-light and alternating explicit modes, while CatalogCubit added no creation, close, or load/state transitions. That diagnostic source is not part of the shipped app. Formatting, static analysis, a production web release build, and an external diagnostic build passed. Live OS preference changes and return-to-system selection were not exercised. Automated theme regression tests remain final-stage work.

The specified palette is retained. Dark filled buttons use a dark foreground on the blue accent for readable contrast. TODO during reusable-component work: avoid small dim text on the light surfaceVariant pairing (approximately 4.34:1), validate every component/state pairing, and consolidate sample card styling into the eventual ProductCard. The external architect review tracks these and final regression checks. Required reusable components and real API behavior remain unimplemented.

## 1. Scope and constraints

Build a Flutter client consuming the public DummyJSON Products API over HTTPS, with base URL `https://dummyjson.com` ([API reference](https://dummyjson.com/docs/products)). There is no application backend, authentication, checkout, or payment flow. The mandatory scope is catalog browsing, title search, a single category filter, infinite scrolling, product details/deep links, a themed component library, and phone/tablet layouts.

Android and web are the local delivery/verification baseline. Retain portable Flutter code and iOS scaffolding; native iOS build/run signoff requires a Mac with Xcode and remains explicitly pending until performed. Other generated desktop runners are scaffold support rather than verified product targets. When networking is introduced, declare Android Internet permission in the main manifest and verify browser CORS against the actual serving origin alongside web route fallback.

The verified development baseline is Flutter 3.47.8 with Dart 3.13.7. The root package requires Dart ^3.13.7, and the current lockfile records a dependency floor of Flutter >=3.47.0. Both constraints must be satisfied; the dependency floor alone does not establish that Flutter 3.47.0 is a verified supported app version. Record the verified SDK pair in final setup documentation. Supporting another reviewer SDK requires a separate compatibility check and, if necessary, dependency resolution; editing the lockfile alone does not establish compatibility.

Keep the design proportionate to the assessment's 3-4 hour scope. Offline data persistence, a component showcase, advanced animations, additional state-management frameworks, and a separate use-case layer are optional/deferred.

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
- **RequestControl:** a small pure-Dart per-operation cancellation signal. The owning Cubit cancels it on replacement/disposal; the remote implementation links it to an effective operation scope and Dio cancellation. Each catalog, category, and detail operation has an independent control, and one logical catalog batch shares one scope across every raw page. A supplied control is used for one operation only; an omitted control still gets internal deadline enforcement. The cancellation signal is implemented for the offline sample; HTTP adaptation and remote deadlines remain planned.
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

Create catalog/category Cubits at catalog-session scope. Start their loads independently. Catalog moves initial -> loading -> loaded, empty, or error. Category failure shows an inline retry while product browsing remains available.

### Search and category changes

The search component owns one 300ms timer. Enter cancels the timer and submits immediately; clear commits immediately. Suppress duplicate effective queries. Selecting a category applies it to the latest committed query; any pending debounced text subsequently applies with the current category.

On an effective filter change, increment the catalog generation, cancel the old operation, capture the new immutable query, clear products/cursor, reset scroll after layout safely, and load from skip=0. A success or failure can update state only if its captured generation still matches and the Cubit remains open. Cancellation is an optimization; generation checks remain the correctness guarantee.

### Pagination and overlapping requests

When remaining scroll content drops below approximately 320 logical pixels, request the next batch. Keep current products, set isLoadingMore, and capture query/cursor/generation. Merge results by ID, retain server order, then update nextSkip/hasMore and clear pagination busy/failure state. Pagination uses the current generation; it does not start a new result set.

A new filter invalidates any pending old page. After page layout, recheck whether the viewport needs more content, including cases where only the raw cursor advanced. Automatic filling stops on failure or exhaustion; errors require explicit retry rather than an automatic retry loop.

### Detail selection and responsive navigation

At available safe-area width >=768 logical pixels, use a persistent catalog panel around 380px wide and a detail panel. `/products` shows a selection prompt; selecting an item updates `/products/:id` and the panel. Below the breakpoint, push details and retain the catalog behind them. Use the same measured breakpoint for layout and Back visibility.

Parse a positive integer ID before requesting detail. Fetch detail independently of the current catalog, using a detail-specific generation/control. Keep the route's ID when catalog filters change, even if that product leaves the visible results; filtering does not silently navigate away. Back restores the catalog; a cold detail entry has a catalog fallback. Resizing preserves the route, catalog query, products, and scroll rather than creating a new feature session.

Unknown routes/invalid IDs get a friendly recovery action. A product 404 gets a product-not-found message and a way back to the catalog. Clean web paths require Flutter's path URL strategy plus server fallback to index.html; verify a real HTTP-hosted reload when navigation is completed. Widget-level route checks alone do not verify hosting behavior.

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

Build list/grid items lazily and retain only fetched metadata for the active query; do not preload the whole catalog. Use thumbnails for cards and lazy gallery pages, with decode dimensions appropriate to the display size where supported. Encapsulate image loading in a reusable widget; verify a compatible caching package when introduced. Native image disk caching and Flutter memory caching are distinct from persistent offline web caching, which is not promised.

ThemeExtension holds the agreed colors, spacing, radii and semantic rating colors, with copyWith/lerp. Material ColorScheme and reusable controls derive from the same tokens. Components accept display values and callbacks, support light/dark and standard/compact variants, and do not know repositories. Ratings include numeric/semantic labels, so meaning does not depend on color alone. Keep tap feedback, keyboard focus, image semantics, readable contrast, short-height layouts and larger text in the acceptance checks.

Measure scrolling with 100+ products on a representative device during final verification. Lazy builders and caching are implementation choices, not proof of zero dropped frames.

## 8. Acceptance criteria and delivery decisions

These are full-product acceptance checks, not a claim that the sample completes them. The offline sample has passed analysis, a web build, and default-scenario manual display/reload checks. Automated tests are deferred to the final verification stage at the developer's request. During implementation use source review, manual checks, formatting, analysis, and appropriate builds.

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
| Tests and handoff | Final stage adds model/state unit tests, widget tests for at least two components, and routing/regression coverage; README/history reflect actual decisions and results. |

The separate architect review should resolve contract contradictions before feature implementation and keep later improvements in a prioritized TODO list. The theme foundation is complete; the next code checkpoint is the required reusable components. The developer handles all staging, commits, and pushes; this document does not authorize expanding implementation scope.
