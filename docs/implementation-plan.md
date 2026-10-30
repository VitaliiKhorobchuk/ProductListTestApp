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

Create folders as their first implementation files are added. A separate use-case layer is unnecessary for the initial scope.

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
4. **Models and API:** extend the sample models with defensive JSON parsing/validation; implement ProductsApi and RemoteProductsRepository against the existing contract, including remote cancellation/deadlines and endpoint verification. Preserve the API rating and derive optional reviewCount from the reviews list according to the policy above.
5. **Cubits:** extend the catalog ViewModel with query/pagination behavior and introduce category/detail Cubits with manual behavior checks.
6. **Catalog screen:** replace the sample repository binding with real API data and compose the required design-system components while retaining state rendering.
7. **Search, filters, and pagination:** debouncing, title/category intersection, raw cursor handling, stale-response protection, and manual edge-case checks.
8. **Details and navigation:** gallery, complete product information, direct links, Back behavior, and retained catalog state; extend the centralized routing established in step 1.
9. **Tablet layout:** adaptive master-detail behavior, selection prompt, resizing, and safe-area checks.
10. **Final verification and handoff:** add and run the required model-validation and state-management unit tests, widget tests for at least two design-system components, and routing/regression tests. Complete formatting, static analysis, target-platform builds, accessibility/layout checks, performance checks with 100+ products, and documentation.

The architecture checkpoint is a runnable offline MVVM example with a catalog route, injected repository, Cubit/state, sample products, clean analysis, manual reload verification, and an architect review. The theme checkpoint now builds on it without changing the data layers. RatingBadge/ProductCard are the first completed component increment, with clean formatting/analysis, builds, UI/design and architecture review, and manual variants/themes, phone-width, large-text, fallback, keyboard, and scroll checks. ErrorState/EmptyState extraction is complete with clean formatting/analysis, production/preview builds, UI/design and architecture reviews, and manual empty/error/retry, inline, narrow/short, large-text, and keyboard checks. ProductSearchField and CategoryChip complete the required reusable-component implementation checkpoint. Models and remote API integration are next; catalog filtering, pagination, and full-product acceptance remain later stages.

Describe the overall folder structure in this plan and create each folder when its first real file is added. Each increment should leave the app runnable and be checked through review, static analysis, and appropriate manual/build checks. Automated tests are deferred to final verification. Keep changes small enough to review and explain. The user handles all staging, commits, and pushes.

## Enhancement A - debug component showcase

Showcase implementation lives under lib/debug/. A catalog app-bar button opens /debug/components only when kDebugMode is true; component detail routes live below that path. Non-debug builds register neither the button nor the showcase routes. The index lists currently implemented design-system components and their named examples; ProductSearchField and CategoryChip are registered.

Detail pages render real components with visual-state examples, optional-action feedback, light/dark switching through the existing ThemeCubit, width presets, and system/100%/150%/200% text settings. Examples are separate from catalog fixtures and repository/Cubit logic. They use bundled images and deterministic fallbacks/loading, with no API calls. A debug-only pending asset bundle holds a ProductImage load for inspection and evicts its pending cache entry on disposal. ProductImage's first-frame loading feedback is shared production behaviour, not a debug switch.

The showcase now contains eight components and 73 named examples, including 11 ProductSearchField examples and eight CategoryChip examples. Formatting/analysis, debug/release web builds, and manual navigation/settings/action/loading/release-exclusion checks passed. Continue mandatory component/API work after this increment. Automated showcase/routing regression checks and constants/localization cleanup remain final-stage work; the showcase is a manual development tool, not test coverage.

## Possible future improvements

- Reconsider read-only search input only when a concrete flow needs a visible, selectable query that cannot be edited (for example, a locked saved search). It is intentionally absent from the current component API and showcase; enabled/disabled behavior remains supported.

## Deferred final cleanup review

Before final verification/handoff, review the implemented code for magic numbers and hardcoded user-facing strings. This work is intentionally deferred; no constants/localization refactor is part of the current component increment.

- Extract meaningful layout dimensions, breakpoints, text-scale limits, icon sizes, opacity values, rating thresholds, percentage/formatting rules, pagination defaults, and sample delays into named constants. Group them by responsibility (theme, component layout, product rules, catalog configuration) rather than creating one unrelated global constants file.
- Keep existing theme tokens as the design-value source of truth. Distinguish configurable rules from obvious loop/index arithmetic and sample product data.
- Move app-owned visible text, tooltips, fallback/error messages, accessibility labels, plural forms, and number/currency presentation into localization resources using Flutter's localization workflow. Establish English resources first; additional translations require an explicit language decision.
- Keep models/repositories/Cubits independent of Flutter localization. Map typed failure kinds to localized messages in presentation; do not expose diagnostic messages directly as UI text.
- Keep route identifiers, asset paths, developer diagnostics, and API/sample product content separate from translatable interface copy. Group technical constants where their context warrants it.
- Review remaining literals after extraction, update architecture/AI documentation, and perform the final-stage formatting, analysis, builds, manual checks, and required automated regression coverage.

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
