# Code and structure review

This review covers retired sample data, duplication, source reachability, import boundaries, asset/dependency ownership and documentation accuracy. It was performed by the coordinating assistant, without an independent agent review.

## Resolved findings

| Finding | Change |
| --- | --- |
| The app/tests did not reach the sample catalog or SampleProductsRepository. | Removed sample_product_data.dart, sample_products_repository.dart and their scenario/environment support. Kept the app's caller-owned repository override and local test stub. |
| A global fixtures folder and five bundled thumbnails outlived the catalog sample. | Removed four unused images. Moved the one image still used by the showcase to assets/images/showcase/ and replaced global sample asset constants with debug/component_showcase/showcase_assets.dart. |
| Catalog and showcase repeated theme-button presentation/callbacks. | Added app/widgets/theme_toggle_button.dart; both locations reuse it. |
| API parsing and image rendering repeated HTTP(S) URL normalization. | Added core/image_urls.dart. ProductImage still separately permits bundled assets; ProductParser still accepts remote URLs only. |
| Technical docs mixed current instructions with historical sample-only checkpoints. | Consolidated system-design.md around current contracts and trimmed repeated checkpoint snapshots in implementation-plan.md. Development history stays in the external AI overview and Git history. |

The retained showcase image has the same Git blob hash as the original. The declared asset directory changes in pubspec.yaml; package versions remain unchanged. An attempted Cupertino Icons removal produced a framework missing-font warning, so the package was restored. A direct app-reference scan alone cannot establish that an adaptive framework asset is unused.

## Structure and duplication decisions

- A conservative import/export graph from main and test roots found no unreachable Dart files after cleanup and no import cycles.
- Catalog models/data/Cubits have no Flutter UI, Flutter Bloc, GoRouter or debug imports. Models and the repository contract remain transport-independent; the remote implementation owns Dio integration.
- Design-system components do not import feature repositories or app navigation. App-level composition/navigation/adaptive helpers remain in app/; the feature-based folders and mirrored test folders remain suitable.
- Similar Cubit generation/control checks are retained: initial/pagination replacement, category coalescing and detail requests have different lifetimes and cleanup. A generic base Cubit would hide those differences.
- ErrorState and EmptyState remain small semantic APIs over StateMessage. Their repeated constructor contract is intentional; their layout is already shared.
- Parser, repository and Cubit page guards protect different boundaries. Shared facts stay in existing helpers without deleting contract checks or adding new product-ID checks to UI.
- ProductCardLayout/CatalogRowsSliver, pricing, labels, rating rules, safe integers and request defaults already have shared owners. No empty domain/use-case layer or unrelated folder reshuffle was introduced.

The reachability/duplicate-block inspection is a source audit, not a proof about every public member, conditional build path or runtime behavior.

## Remaining follow-ups

- English localization: interface text, error mapping, accessibility/plurals/currency presentation and model/presentation text boundaries.
- Rating precision: a raw rating such as 3.999 can display 4.0 while using the raw amber threshold. Choose and test a consistent display/color policy later.
- Wide-desktop proportions: the existing fixed 380px list and centered 720px detail content remain the previously deferred visual improvement.
- Test scope: ten assessment-baseline tests do not exhaustively cover category/detail Cubits, request races/deadlines, API/repository failures or adaptive lifetimes. Expand only where justified.
- Final native/accessibility/performance/platform and README/history verification remains planned; this review does not certify those areas.

## Validation

All ten existing tests pass, static analysis reports no issues, and formatting passes. The final release web build passes with the Cupertino font restored. Scoped browser checks cover live remote catalog/detail, the shared theme control and the relocated showcase image; observations are recorded in the external AI overview.

No new tests or dependencies were added. No staging, commits or pushes were performed. README remains for final delivery.