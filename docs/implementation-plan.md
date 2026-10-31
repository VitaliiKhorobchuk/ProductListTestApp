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
  core/                      # Shared pure policies, failures and cancellation
  design_system/
    theme/
    components/
  features/catalog/
    models/
    data/
    presentation/
      cubit/
      screens/
      widgets/
  debug/component_showcase/   # Development-only previews and asset constants
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

The app now uses remote data with all required components/screens and the compact ten-test baseline. The temporary sample catalog/repository is retired. One debug showcase image remains beside its preview code; tests use small local doubles. Current technical contracts live in system-design.md; chronology remains in the external AI overview and Git history.

Keep checkpoints runnable and verify relevant tests, static analysis, builds and manual flows. The developer handles staging, commits and pushes.

## Enhancement A - debug component showcase

Showcase implementation lives under lib/debug/. A catalog app-bar button opens /debug/components only when kDebugMode is true; component detail routes live below that path. Non-debug builds register neither the button nor the showcase routes. The index lists currently implemented design-system components and their named examples; ProductSearchField and CategoryChip are registered.

Detail pages render real components with visual-state examples, optional-action feedback, light/dark switching through the existing ThemeCubit, width presets, and system/100%/150%/200% text settings. Examples are separate from catalog fixtures and repository/Cubit logic. They use bundled images and deterministic fallbacks/loading, with no API calls. A debug-only pending asset bundle holds a ProductImage load for inspection and evicts its pending cache entry on disposal. ProductImage's first-frame loading feedback is shared production behaviour, not a debug switch.

The showcase now contains eight components and 73 named examples, including 11 ProductSearchField examples and eight CategoryChip examples. Formatting/analysis, debug/release web builds, and manual navigation/settings/action/loading/release-exclusion checks passed. Continue mandatory component/API work after this increment. Automated showcase/routing regression checks and constants/localization cleanup remain final-stage work; the showcase is a manual development tool, not test coverage.

## Possible future improvements

- [ ] Review wide-desktop master-detail proportions. The current fixed 380px catalog becomes visually narrow in large browser windows, while the remaining detail pane centers content capped at 720px and leaves large empty margins. Consider a separate desktop breakpoint with a proportionally wider, bounded catalog and an image/information layout using two columns when space allows. Keep the existing tablet proportions, centralized layout policy, route-owned selection, state retention, keyboard access, and large-text behavior. Exact desktop dimensions and acceptance checks remain undecided. This is a recorded visual issue/optional improvement; implementation is deferred rather than automatically included in final cleanup.


- Consider a domain/use-case layer between Cubits and repository contracts when workflows become complex, are reused by multiple Cubits, or combine data from multiple repositories. This remains compatible with MVVM and is optional after mandatory requirements, not an automatic final-cleanup task. A possible GetCatalogProductsUseCase should encapsulate meaningful application policy/orchestration. If query orchestration moves, preserve coordinated title/category filtering, continued raw-page scanning, cursor progress, overfill retention, atomic batches, and one operation deadline. The pure title/category predicate already lives in CatalogQuery.matches. A separate use-case layer remains deferred.

- Reconsider read-only search input only when a concrete flow needs a visible, selectable query that cannot be edited (for example, a locked saved search). It is intentionally absent from the current component API and showcase; enabled/disabled behavior remains supported.

## Final cleanup progress

### Constants and shared rules (implemented)

- SafeInteger owns the shared native/web integer ceiling, range checks and integral JSON-number parsing. The parser, API, repository and catalog page checks reuse it; each boundary retains its existing failure type/message. Product-ID domain validation remains in product_id_validation.dart, with no new detail-UI/Cubit ID check.
- CatalogPagination owns the default batch size. ProductsApiConfig and ProductsEndpoints own request timeouts, the overall operation budget, headers and HTTP paths. Transport paths remain separate from application routes.
- CatalogQuery.matches owns the final title/category match after the broader server search.
- ProductRating owns rating bounds and raw-value color thresholds; DiagnosticLevel names the existing logging severities. Pricing and descriptive fallback helpers remain reused.
- AppTokens now owns accent foreground and normal/emphasized border widths plus shared focus/hover overlays. These preserve the existing colors, dimensions and opacity values, including copyWith/lerp support for configurable tokens.
- Meaningful icon sizes, text line limits, component/preview dimensions and debounce defaults have contextual names. ShowcaseAssets groups the real preview image and intentionally missing image path inside debug/component_showcase/.
- Removed replaced private validation helpers and the repeated matching predicate. Full analysis reports no unused declarations. The app repository-injection seam remains for tests; simple index arithmetic, explicit sample values and API schema keys stay local.

Historical constants-checkpoint verification: formatting, full analysis, release web and Android debug builds passed. Print-only external inspection covered numeric/rating boundaries, parser fallbacks, encoded endpoints, defaults, sample filtering and live20+20 pagination/Red-Groceries matching. Browser smoke checks and Pixel7Pro/Android17 manual launch, native typing/Enter, combined red/Beauty filtering, detail, Android Back and light/dark appearance were checked. External QA notes distinguish these observations from deferred automated coverage. No tests, dependencies, README, staging or commits changed.

### Retired sample data and structure review (implemented)

Removed the unused sample catalog/categories, SampleProductsRepository and SAMPLE_CATALOG scenarios. The app/test import graph did not reference them. Removed four unused thumbnails; moved the retained image/constants under the showcase. App repository injection and local test doubles remain.

ImageUrls centralizes remote image URL syntax; ThemeToggleButton shares app theme-switch chrome. Per-Cubit operation handling and cross-boundary validation remain explicit where contracts differ. No import cycles or UI imports in the data/model/Cubit layers were found. The existing feature-based layout is retained.

The asset manifest now names only the showcase directory. Cupertino Icons remains: removing it triggered a framework missing-font warning, so lack of a direct application reference was not enough to establish that it was unused. System-design.md is consolidated around current contracts; repeated checkpoint snapshots/stale sample instructions are removed from technical docs. Localization, deeper regression and recorded desktop/rating improvements remain pending.

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
