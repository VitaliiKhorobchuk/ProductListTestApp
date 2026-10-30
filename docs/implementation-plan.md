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

The required design-system components are ProductCard (standard and compact variants), a search input, CategoryChip, error/empty states, and RatingBadge. Offline persistence, a standalone component showcase, and advanced animations are optional enhancements after the mandatory behavior is complete and verified.

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

Add dependencies when implementation begins using them. Choose supporting image-caching and price-formatting packages during their component implementation and document platform-specific behavior.

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

## Implementation sequence

1. **App and MVVM architecture skeleton:** separate startup, app composition, and centralized routing. Implement one working offline catalog slice with immutable models, a repository contract/sample implementation, a pure-Dart Cubit/ViewModel and state, and a View displaying example products with reload and loading/empty/error states. Inject the repository/Cubit above routing. Completion: the sample runs, analysis is clean, and the architect reviews the complete layer boundaries. Automated tests remain deferred.
2. **Theme foundation:** introduce ThemeExtension tokens, light/dark ThemeData, and working theme switching within the app skeleton.
3. **Reusable components:** required component APIs and variants, image/price presentation, and manual component checks. Use the running app foundation to inspect components as they are added.
4. **Models and API:** extend the sample models with defensive JSON parsing/validation; implement ProductsApi and RemoteProductsRepository against the existing contract, including remote cancellation/deadlines and endpoint verification.
5. **Cubits:** extend the catalog ViewModel with query/pagination behavior and introduce category/detail Cubits with manual behavior checks.
6. **Catalog screen:** replace the sample repository binding with real API data and compose the required design-system components while retaining state rendering.
7. **Search, filters, and pagination:** debouncing, title/category intersection, raw cursor handling, stale-response protection, and manual edge-case checks.
8. **Details and navigation:** gallery, complete product information, direct links, Back behavior, and retained catalog state; extend the centralized routing established in step 1.
9. **Tablet layout:** adaptive master-detail behavior, selection prompt, resizing, and safe-area checks.
10. **Final verification and handoff:** add and run the required model-validation and state-management unit tests, widget tests for at least two design-system components, and routing/regression tests. Complete formatting, static analysis, target-platform builds, accessibility/layout checks, performance checks with 100+ products, and documentation.

The architecture checkpoint is a runnable offline MVVM example with a catalog route, injected repository, Cubit/state, sample products, clean analysis, manual reload verification, and an architect review. Suggested commit message: `feat: add MVVM catalog skeleton with sample data`.

Describe the overall folder structure in this plan and create each folder when its first real file is added. Each increment should leave the app runnable and be checked through review, static analysis, and appropriate manual/build checks. Automated tests are deferred to final verification. Keep changes small enough to review and explain. The user handles all staging, commits, and pushes.

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
