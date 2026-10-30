# ProductListTestApp system design

This is the design baseline for the product-catalog assessment. The implemented foundation now includes startup, centralized routing, and one working offline MVVM catalog slice: immutable models, a repository contract and fixture-backed implementation, CatalogCubit/state, app-level injection, a state-rendering View, and token-based light/dark themes with an app-level switch. The remaining full-product behaviors below are the target design, not a claim that networking or every screen/action is complete. The [implementation plan](implementation-plan.md) defines the delivery sequence.

## Implemented MVVM architecture example

The sample demonstrates the complete dependency path with six offline products:

`CatalogScreen -> CatalogCubit -> ProductsRepository -> SampleProductsRepository -> sample_product_data`

Results flow back as immutable ProductPage/Product values, then CatalogState, then BlocBuilder output. The View sends load/retry actions and renders initial/loading/loaded/empty/error states. It does not read fixture data or construct a repository.

| Responsibility | Implemented files |
| --- | --- |
| Model | `features/catalog/models/product.dart`, `category.dart`, `catalog_query.dart`, `product_page.dart` |
| Defensive API mapping | `features/catalog/data/product_parser.dart`, `raw_product_page.dart` |
| Data contract and sample source | `features/catalog/data/products_repository.dart`, `sample_products_repository.dart`, `sample_product_data.dart` |
| ViewModel and state | `features/catalog/presentation/cubit/catalog_cubit.dart`, `catalog_state.dart` |
| View | `features/catalog/presentation/screens/catalog_screen.dart`, `design_system/components/product_card.dart`, `rating_badge.dart`, `product_image.dart` |
| Composition | `app/app.dart` injects a repository and lets BlocProvider create/close the Cubit above the router. |
| Shared request/failure types | `core/request_control.dart`, `core/catalog_failure.dart` |

Paths above are relative to lib/. CatalogCubit imports the pure-Dart bloc package; catalog Flutter integration is confined to app/View code through flutter_bloc. The app-level ThemeCubit is separate from the catalog feature and uses Flutter appearance enums. Equatable supplies value comparisons. The app accepts a repository override at startup. The default binding uses SampleProductsRepository; the later remote implementation can replace it without changing the View's data source knowledge.

The sample repository implements product pages, categories, and single-product lookup from fixtures. It simulates broad source search before local title/category filtering and retains raw cursor semantics, but the View currently exposes only initial load and reload. `remoteTotal` is a simulated source count, not observed server metadata. The fixtures are trusted in-memory model values. Defensive decoded-JSON mapping is now implemented separately at the data boundary, as described below; JSON-text/transport errors, HTTP integration, Dio cancellation mapping, and remote operation deadlines remain later work. The sample's 500ms delay is cancellable and cleans up its timer/listener.

Manual scenario commands from the configured project terminal:

```powershell
flutter run -d chrome
flutter run -d chrome --dart-define=SAMPLE_CATALOG=empty
flutter run -d chrome --dart-define=SAMPLE_CATALOG=error
```

Stop and relaunch to switch compile-time scenarios. The default is loaded sample data; empty returns no fixtures; error deliberately fails each load, so Retry repeats that configured failure rather than simulating recovery. The repository also accepts an injected fixture list, including an empty list. Screens contain no error-simulation controls. Manual verification originally covered the default six-product display and repeated reloads. The ErrorState/EmptyState checkpoint also exercised the empty/error scenarios through the same repository injection, including another failed Retry in the configured error mode. Automated tests remain deferred.

## Implemented theme foundation

`design_system/theme/app_tokens.dart` defines immutable ThemeExtension tokens for the agreed palettes, semantic rating colors, 8px base spacing, and 12px/default and 8px/small radii. Its copyWith and lerp cover every token. `app_theme.dart` derives cached Material ThemeData and control defaults from these tokens; Views access them through context.tokens.

The app-level `app/theme/theme_cubit.dart` owns ThemeMode, initially system, and exposes setMode/toggle actions. ThemeCubit uses Flutter appearance enums but has no BuildContext or global platform lookup. The catalog reads it from BlocProvider when the switch is pressed, supplying the current MediaQuery platform brightness; its icon/tooltip still follow the effective theme. Toggle resolves the current Cubit selection, so repeated actions do not depend on a possibly animating theme brightness. The router only constructs the screen and forwards no theme callback.

ProductListTestApp provides ThemeCubit and CatalogCubit above a BlocBuilder that passes the selected mode to MaterialApp.router. The providers retain ownership/automatic closure and remain outside the appearance rebuild boundary. Router and repository remain initState-owned. Toggling selects explicit light/dark mode for this session; setMode can restore system mode, but no return-to-system selector or persistence is exposed yet. Appearance changes do not invoke catalog loading. The sample list has a stable PageStorageKey for scroll retention.

Manual browser verification after the ThemeCubit refinement observed the system-dark initial appearance and repeated light/dark switches, including consecutive clicks, with the same catalog URL, six products, CatalogCubit identity, loaded-state identity, and scroll position. A temporary entrypoint outside the project logged BlocObserver lifecycle/state events: ThemeCubit emitted system-to-light and alternating explicit modes, while CatalogCubit added no creation, close, or load/state transitions. That diagnostic source is not part of the shipped app. Formatting, static analysis, a production web release build, and an external diagnostic build passed. Live OS preference changes and return-to-system selection were not exercised. Automated theme regression tests remain final-stage work.

The specified palette is retained. Dark filled buttons use a dark foreground on the blue accent for readable contrast. ProductCard now inherits shared CardTheme decoration, resolving the earlier sample-style duplication. Continue avoiding small dim text on the light surfaceVariant pairing (approximately 4.34:1) and validate each new component/state pairing. The external architect review tracks these and final regression checks. RatingBadge and ProductCard are implemented below; CategoryChip is implemented below; real API/search integration remains later work; the reusable ProductSearchField is described below. ErrorState/EmptyState are described below.

## Implemented RatingBadge and ProductCard

`design_system/components/rating_badge.dart` displays a star, a numeric rating, and an optional nonnegative review count. Thresholds use the valid raw rating: green at >=4, amber at >=3 and <4, red below 3. Null, non-finite, or values outside 0..5 use a neutral Not rated state, distinct from zero. The semantic label includes the rating out of 5 and review count; color is supplementary.

`product_card.dart` provides ProductCardVariant.standard (horizontal list summary when space permits) and compact (vertical image/content card). Both accept display values and an optional onTap, with no Product model, Cubit, repository, or navigation dependency. The card inherits shared CardTheme decoration. Width/text constraints can stack the standard variant; content has natural height with bounded title/metadata lines and wrapping price/rating content. An onTap callback enables InkWell feedback and keyboard activation; absent callbacks produce noninteractive cards. The sample has no detail navigation yet and supplies no fake tap action.

Product now includes an optional reviewCount in its immutable data and Equatable values. CatalogScreen forwards it through ProductCard to RatingBadge; the offline fixtures provide illustrative counts, including zero for the unrated side table. Missing or negative counts remain hidden by the badge. The implemented API parser uses the API rating directly, without recalculating it from individual reviews. Derive reviewCount from reviews.length only when reviews is a list; an empty list means zero, while a missing, null, or malformed reviews value means an unknown/null count that the badge hides. This counts returned reviews and does not assert a separately guaranteed total rating/review count. These sample counts are not claims about live API reviews.

Price contract: price is the already-calculated current/displayed USD amount; originalPrice is optional. CatalogScreen passes Product.discountedPrice and Product.price respectively, so discounts are not applied twice. A valid original price is struck through only when strictly greater than a finite nonnegative current price. The discount label is a rounded percentage derived from those two amounts, an intentional display-value API choice instead of accepting raw discountPercentage. Invalid current amounts display Price unavailable and suppress the original price/discount. Blank titles/categories have readable fallbacks; brand is optional. Baseline formatting uses two decimal places and USD, without locale grouping.

`product_image.dart` accepts HTTP(S) URLs or bundled paths beginning with assets/ and encapsulates image loading, loading feedback, and missing/invalid/failed-image placeholders in a stable image slot. Missing/failed-source diagnostics are debug-only and guarded once per input lifecycle, scheduled after the frame. Images use Flutter's shared memory cache; persistent disk caching/offline web behavior is not claimed ([Image.network](https://api.flutter.dev/flutter/widgets/Image/Image.network.html), [ImageCache](https://api.flutter.dev/flutter/painting/ImageCache-class.html)). Cross-origin/CDN behavior and representative-device decode sizing remain later integration checks.

Five sample products use bundled WebP thumbnails under assets/images/sample_products/, declared in pubspec.yaml. Wooden Side Table deliberately has no thumbnail, so its unavailable state remains visible. These files load through AssetImage with no runtime image request; remote sources still use NetworkImage. Bundled images are separate from persistent caching of remote content. Source thumbnails: [Red Lipstick](https://cdn.dummyjson.com/product-images/beauty/red-lipstick/thumbnail.webp), [Red Onions](https://cdn.dummyjson.com/product-images/groceries/red-onions/thumbnail.webp), [Eggs](https://cdn.dummyjson.com/product-images/groceries/eggs/thumbnail.webp), [headphones](https://cdn.dummyjson.com/product-images/mobile-accessories/apple-airpods-max-silver/thumbnail.webp), and [lamp](https://cdn.dummyjson.com/product-images/home-decoration/table-lamp/thumbnail.webp). These are visual fixtures; their IDs/prices remain the local example data, not imported API records.
CatalogScreen maps models to component values and owns the local list/grid selection. Compact rows are built lazily with one to four columns based on width/text scale, without a fixed grid height. Separate PageStorageKeys retain each view's scroll offset. Cubit/repository/query behavior is unchanged. The temporary SampleProductTile has been removed, and six offline fixtures include green/amber/red/unknown examples; this is demonstration data, not API output. CategoryChip is implemented below; shared error/empty presentation is implemented below.

Component verification: formatting and analysis passed, along with a production web release build and an external release-preview build. Manual browser checks covered both variants/themes at desktop width, a 320px phone width, long text, and 200% text scaling. The external preview showed a loaded local HTTP image; missing, unsupported, and failed-image fallbacks; ratings at 4, 3, 2.99, and 0; neutral null/non-finite/out-of-range ratings; review-count semantics; missing/negative and zero prices; suppressed inconsistent original prices; and a full discount. Tab focus was visible, Enter invoked the supplied callback, and pointer activation invoked it again. No layout faults or Flutter error diagnostics were observed. List/grid changes restored separate scroll positions; theme/layout switching retained the catalog URL, six products, CatalogCubit identity, and loaded-state identity without another load. These are browser observations, not native-device or automated-test signoff. Loading-transition capture, actual CDN/CORS, decode/cache performance, and native verification remain later checks. The temporary external preview source is removed after use.

UI/design and architecture reviews found no blockers. TODOs: define rating-rounding behavior near color thresholds, review release warning policy, verify CDN/CORS and cache/decode behavior during API integration, and add required component/unit/regression tests during final verification. Native builds/device performance and the remaining component library remain pending.

## Implemented ErrorState and EmptyState

`design_system/components/error_state.dart` and `empty_state.dart` are presentation-only wrappers over `state_message.dart`. Both accept required title/message strings, an optional icon, paired actionLabel/onAction, and inline=false by default. ErrorState uses the error color/default cloud-off icon; EmptyState uses the primary color/default inventory icon. Callers own all wording and actions. Missing actions produce no button; debug assertions catch incomplete/blank action configuration, while release mode safely omits unusable actions.

StateMessage owns shared padding, bounded text width, title-heading semantics, decorative-icon exclusion, and the inherited FilledButton styling. It paints the normal surface to preserve the intended contrast for dim message text. Full-area mode centers within bounded available height; inline mode uses natural content height. A scroll container keeps content/actions reachable when available height is short, and unbounded-height parents avoid an infinite minimum-height constraint. Titles/messages/button labels wrap with text scaling.

CatalogScreen now renders EmptyState for an empty result and ErrorState for a failure. The private _CatalogMessage is removed. The catalog still supplies its existing messages and Retry -> CatalogCubit.retry callback; components import no feature models, Cubits, repositories, or routing. Loaded products, images, list/grid selection, and theme ownership are unaffected. The configured sample error scenario still fails on each Retry; this demonstrates another load attempt rather than simulated recovery. Constants/localization cleanup and automated tests remain deliberately deferred.

Message-component verification: formatting/static analysis passed, as did a production web release build and an external debug-preview build. Manual browser inspection exercised the actual app with injected empty/error sample scenarios. ErrorState exposed the supplied title, message and Retry button; pointer activation produced loading -> error on the same CatalogCubit. EmptyState had heading/message semantics and no action, and rendered in dark/light appearances. The component preview exercised light full-area/error and dark inline/empty presentation at 320x360 and 200% text, long copy/button wrapping, scrolling to the action, visible Tab focus and Enter activation, custom icon/action copy, and action omission. Inline/error presentation without an action was also inspected. Surrounding inline content stayed reachable, with no warning/error-level preview console diagnostics. The viewport was restored and the external preview source removed afterward; no automated tests were added or run.

UI/design and independent architecture reviews found no blockers. Final-stage TODOs include the full/unbounded and inline/tight-bounded runtime matrix, screen-reader state-change announcements, and regression coverage for actions/scrolling/layout. Constants/localization cleanup remains deferred. Read-only mode was removed because the current catalog has no use case; reconsider it only for a concrete requirement such as a locked saved search. The README and dependency files are unchanged. ProductSearchField and CategoryChip are now implemented separately.

## Debug component showcase (Enhancement A)

All gallery registration, examples, navigation controls, preview settings, and deterministic image-loading fixtures live in lib/debug/, with component-specific files under debug/component_showcase/. The production catalog imports only the entry button, conditionally rendered with kDebugMode. Central routing conditionally includes createDebugRoutes; that factory also returns no routes outside debug mode. The entry is /debug/components, with nested component-ID pages and a friendly unknown-component recovery page. Existing app-scoped dependencies remain above routing, and push/back navigation retains the catalog page.

The registry currently includes CategoryChip, ProductSearchField, ProductCard, RatingBadge, ProductImage, ErrorState, EmptyState, and their shared StateMessage layout. Named examples cover standard/compact cards, pricing/discount/field fallbacks and callbacks, rating colors/boundaries/invalid values/review counts, loaded/loading/missing/unsupported/failed images, and full-area/inline messages with/without actions and long/custom copy. Preview controls cap width to available space and apply optional text scaling inside examples; default text follows the system. Theme changes use the existing ThemeCubit and affect the app consistently. Preview actions show feedback and do not call repositories or change catalog data.

LoadingImagePreview uses a private DefaultAssetBundle to keep the real ProductImage pending without a timer or server; disposal evicts the pending AssetImage key from Flutter's cache. Missing-image examples intentionally exercise real fallbacks. ProductImage now shows its existing spinner before the first image frame as well as during byte-progress events, making initial loading visible and reproducible. No new dependency or asset set is introduced. Showcase code never becomes a dependency of reusable design-system widgets. Constants/localization cleanup remains deferred, including debug copy.

Showcase verification: formatting and analysis passed, along with debug and release web builds. The initial registry contained six components and 54 named examples; the search-field increment expands it to seven components and 65 examples. Manual debug-browser checks covered index/detail navigation, all registered component pages, the loaded/pending/fallback image states, both card variants, width and 200% text controls, light/dark switching, phone-width message examples, keyboard activation of preview actions, unknown-component recovery, and return to the loaded catalog with its prior scroll position. The intended missing-asset example emits an expected 404 warning; no unexpected runtime error was observed. The release catalog has no showcase button, and a direct release /debug/components entry reached the not-found page. The temporary browser viewport override was reset. Profile exclusion follows the same kDebugMode guards but was not separately built/run. Final-stage regression coverage should include route gating, registry coverage as components are added, preview lifecycle/cache eviction, and retained catalog state. No automated tests were added or run.

## Implemented ProductSearchField

`design_system/components/product_search_field.dart` is a reusable input, independent of catalog models, Cubits, repositories, and routing. It accepts onChanged, optional onSubmitted, hint/clear copy, an enabled flag, a nonnegative debounce duration (300ms default), optional controller/focusNode, and an initialValue seed when no external controller is supplied. It preserves raw whitespace/case. The ViewModel's effective-query equality remains responsible for normalized duplicate suppression during the later catalog integration.

Callback contract: user typing calls onChanged after the debounce. Clear cancels pending work, empties the field, restores input focus, and calls onChanged('') immediately. Enter cancels pending typing and calls only onSubmitted when supplied, otherwise onChanged; it never calls both for one submission. Initial values and programmatic text replacements do not search. Controller selection-only changes preserve pending typing. Composition is held until IME commit, including a composition-only completion with unchanged text.

The component disposes only controllers/focus nodes it creates, detaches listeners from external objects, and preserves the value if an external controller is removed. Pending work is cancelled on clear, submit, disposal, controller/focus replacement, editability changes, duration changes, and programmatic text replacement. Timer delivery checks mounted/editability/current text/composition and uses the current callback. The clear action is hidden for empty or disabled fields. Native field/editing semantics remain available; a populated field retains its search-purpose label. Styling inherits the existing input theme.

`debug/component_showcase/search_field_examples.dart` registers 11 examples: empty/populated, focus-on-request, disabled with/without text, long text/custom copy, Enter fallback, internal controller ownership, and an interaction/lifecycle sandbox. Preview State owns external controllers/focus nodes and event history; focused examples keep alive through lazy scrolling. Sandbox controls can remove/disable the input, change delay/submission mode, or replace controller text while preserving the event log. This is manual inspection support, not automated test coverage. The component is not connected to catalog queries or the API in this increment; CategoryChip is implemented below; catalog query integration remains planned. Constants/localization cleanup remains deferred. Read-only mode was removed because the current catalog has no use case; reconsider it only for a concrete requirement such as a locked saved search.

Verification: formatting and static analysis passed, along with debug and release web builds. Manual browser checks confirmed delayed typing, exclusive Enter submission and its onChanged fallback, immediate clear without a stale callback, no initial callback, preserved search/clear accessibility names, and cancellation when disabled, removed, or changed programmatically. Narrow 160px previews and 200% text were inspected in both theme presentations; a debug dropdown label was refined to ellipsize while retaining its full accessible text. UI/design and architect source reviews found no blockers. Native IME/platform keyboards, controller/focus replacement, and selection-only timer behavior remain final-verification checks. No automated tests were added or run.
## Implemented CategoryChip

`design_system/components/category_chip.dart` is a stateless, controlled wrapper around Flutter ChoiceChip. Its API accepts label, selected, and nullable onSelected; a null callback disables interaction without discarding the selected state. The chip forwards the proposed selected boolean without storing category identity or applying selection policy. The feature parent will map displayed category names to stable slugs and own the single-category/All products rule. No category Cubit, repository access, or catalog filtering is introduced here.

The component uses existing AppTokens and ColorScheme: enabled selection uses primary/onPrimary, unselected uses surface/onSurface, and disabled states use surfaceVariant/onSurface. Native selection/disabled semantics, keyboard/tap behavior, and padded tap targets are retained. A state-resolved border exposes keyboard focus. A decorative fixed-size selected check replaces RawChip's height-dependent checkmark, and explicitly replaced text defaults plus a bounded label width allow natural wrapping without a fixed height. Normal selected state remains distinguishable by its check as well as its color.

`debug/component_showcase/category_chip_examples.dart` adds eight examples: selected/unselected, disabled selected/unselected, long labels in both selection states, an unbroken label, and an interactive single-selection group. Fixed examples log proposed values without changing the supplied state. The group owns selection using stable enum identity, starts with All products, keeps the active chip selected on a repeated tap, and includes an unavailable option. Group keepalive retains this small demonstration while scrolling; it never requests catalog data. The registry now contains eight components and 73 examples. Constants/localization extraction and automated tests remain deferred to their final stages.

Verification: formatting and static analysis passed, with debug and production web builds. Manual browser checks covered fixed-state true/false callback proposals, pointer/Enter/Space activation, visible keyboard focus, disabled click suppression and Tab skipping, group category switching/re-tapping/All products, and checked/disabled accessibility values. Selection survived appearance, preview-width/text-size changes, scrolling, and a phone-width resize. Both themes, 160px component width, 320px viewport, 200% text, long and unbroken labels were inspected without layout errors; preview warning/error logs were empty. UI/design and independent architect reviews found no blockers. A screenshot was saved externally and the temporary viewport override reset. Native-device/assistive technology/RTL checks, automated tests, wrapping rechecks after Flutter SDK upgrades, and later category-slug/Cubit integration remain TODOs. No dependencies, README, tests, staging, or commits changed.

## Implemented defensive model parsing

`features/catalog/data/product_parser.dart` maps already-decoded `Object?` API values into the existing immutable Product/Category models. Keeping mapping at the data boundary avoids JSON, logging, or transport dependencies in trusted fixture constructors and domain values. Its entry points are parseProduct, parseCategory, parseCategories, and parseProductPage(expectedSkip, requestedLimit). It does not decode JSON text, fetch HTTP, filter titles/categories, or deduplicate products. The running app still uses SampleProductsRepository.

Product shape and a positive safe integer ID are required. Numeric strings, fractions, non-finite numbers, negative IDs, zero IDs, and integers above 9007199254740991 are rejected with CatalogFailure.invalidData; integral numeric values such as 1.0 are accepted. The same nonnegative safe-integer rule applies to stock and pagination metadata, with unknown stock represented by null. Metadata and cursor addition are checked before conversion/advancement for native/JavaScript consistency by source design.

Missing, blank, or wrongly typed descriptive fields use Untitled product, Unknown brand/category, and No description available. Finite nonnegative prices remain original API prices; invalid/missing prices become null. Invalid discounts become zero, invalid ratings become null, and valid zero values remain zero. Product.discountedPrice remains the shared calculation. The API rating is used directly; reviews lists contribute their length (including zero), while absent/null/wrongly typed reviews leave reviewCount null.

Image mapping accepts trimmed syntactically absolute HTTP(S) URLs with a nonempty host. Invalid thumbnails become null; invalid gallery entries are dropped and valid duplicates removed in first-seen order. API asset paths are rejected, while trusted offline fixtures continue to use bundled assets. URL syntax validation does not establish image availability, MIME type, decoding, or CORS. Those remain ProductImage/runtime integration concerns. Parsed gallery/category/product collections are copied as unmodifiable lists.

Category objects require a nonblank slug, trimmed without rewriting its identity. Missing names are humanized from the slug. Category lists preserve the first valid entry per slug and skip malformed entries; an empty list is valid, while a nonempty entirely malformed list fails invalidData. The parser consumes the object-based /products/categories shape, not the string-only category-list endpoint.

`data/raw_product_page.dart` represents one validated server envelope separately from the repository's domain ProductPage. It retains products, rawCount, skip, limit, and total; nextSkip is skip + rawCount and hasMore compares that offset with total. Parser checks require a products list, valid metadata, response skip matching the requested cursor, rawCount within both the reported/requested limits, safe cursor addition, and a nonempty page within the remaining total. Empty pages are accepted only at/beyond reported exhaustion (including response limit zero). No-progress pages with remaining data fail rather than becoming false empty results. A nonempty all-invalid page fails before repository filtering; a mixed page retains rawCount even when some records are skipped. Direct RawProductPage construction remains a trusted path; ProductParser is the validation boundary.

Diagnostics are emitted at parsing time through an optional onDiagnostic(message, level) callback or dart:developer by default. Invalid/missing prices use error level 1000; skipped records and invalid/missing thumbnails/gallery values use warning level 900. Messages identify context without dumping product/review payloads. Callers should provide nonthrowing diagnostic adapters. Cross-page totals, duplicate product IDs, overfill, filtering, atomic batches, transport failures, and request cancellation remain the remote repository/API checkpoint.

Verification: formatting and full static analysis passed; the existing app's production web build passed. Temporary native-Dart console inspection parsed a live product, a three-record page, and 24 categories, then printed deliberately imperfect inputs for manual assessment. Observations covered optional defaults, valid zeros, unsafe/string/fractional IDs, non-finite values, image filtering/deduplication, mixed-page raw advancement, duplicate preservation, all-invalid pages, malformed metadata, cursor mismatch/overflow, premature empty versus exhausted pages, category deduplication/fallbacks/failures, and safe diagnostics. The offline sample repository still returned six products. Data/state and independent architect reviews found no blockers. Temporary inspection sources/payloads were removed after use. No automated tests or browser/platform parser-runtime checks were performed; the parser is not wired into the running app yet. Final parsing/immutability/regression coverage remains planned, and JSON decoding/transport/detail-ID consistency are explicit next-integration tasks.

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

Build list/grid items lazily and retain only fetched metadata for the active query; do not preload the whole catalog. Use thumbnails for cards and lazy gallery pages, with decode dimensions appropriate to the display size where supported. ProductImage now encapsulates image loading with Flutter memory caching. Evaluate an additional caching package only if persistent native disk caching is introduced. Native image disk caching and Flutter memory caching are distinct from persistent offline web caching, which is not promised.

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

The separate architect review should resolve contract contradictions before feature implementation and keep later improvements in a prioritized TODO list. The theme foundation is complete; the required reusable-component implementation checkpoint is complete with RatingBadge, ProductCard, ProductSearchField, CategoryChip, ErrorState, and EmptyState. Final automated coverage and full catalog integration remain planned. The developer handles all staging, commits, and pushes; this document does not authorize expanding implementation scope.
