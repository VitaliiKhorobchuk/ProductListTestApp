import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/components/product_image.dart';
import '../../../../design_system/theme/app_tokens.dart';

/// Displays presentation-ready image candidates without repeating URL rules.
///
/// Product canonicalizes image order; ProductPresentation chooses fallbacks.
/// ProductImage owns image
/// validation, loading, and failure. An empty list becomes one placeholder slot.
class ProductGallery extends StatefulWidget {
  const ProductGallery({
    super.key,
    required this.productId,
    required this.productTitle,
    required this.images,
  });

  final int productId;
  final String productTitle;
  final List<String> images;

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  static const _maximumImageHeight = 440.0;
  static const _viewportHeightFraction = .45;
  static const _imageAspectRatio = 1.25;
  static const _pageDuration = Duration(milliseconds: 220);

  PageController _controller = PageController(keepPage: false);
  int _index = 0;

  List<String?> get _sources =>
      widget.images.isEmpty ? const [null] : widget.images;

  @override
  void didUpdateWidget(covariant ProductGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId ||
        !listEquals(oldWidget.images, widget.images)) {
      final previousController = _controller;
      _controller = PageController(keepPage: false);
      _index = 0;
      // PageView detaches from the old controller during the following build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        previousController.dispose();
      });
    }
  }

  void _showPage(int page) {
    if (!_controller.hasClients || page < 0 || page >= _sources.length) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(page);
      return;
    }
    unawaited(
      _controller.animateToPage(
        page,
        duration: _pageDuration,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final sources = _sources;
    final controller = _controller;
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight = math.min(
          constraints.maxWidth / _imageAspectRatio,
          math.min(
            _maximumImageHeight,
            MediaQuery.sizeOf(context).height * _viewportHeightFraction,
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: tokens.border),
                borderRadius: BorderRadius.circular(tokens.radius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(tokens.radius),
                child: SizedBox(
                  height: imageHeight,
                  child: PageView.builder(
                    controller: controller,
                    itemCount: sources.length,
                    physics: sources.length == 1
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    onPageChanged: (page) {
                      // Ignore a finishing animation from a replaced source set.
                      if (!mounted || !identical(controller, _controller)) {
                        return;
                      }
                      if (page != _index) setState(() => _index = page);
                    },
                    itemBuilder: (context, index) => ProductImage(
                      imageUrl: sources[index],
                      semanticLabel: widget.images.isEmpty
                          ? widget.productTitle
                          : '${widget.productTitle}, image ${index + 1} of ${sources.length}',
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: tokens.spaceSm),
            if (sources.length > 1)
              Row(
                children: [
                  IconButton.outlined(
                    tooltip: 'Previous image',
                    onPressed: _index > 0 ? () => _showPage(_index - 1) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  SizedBox(width: tokens.spaceSm),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        'Image ${_index + 1} of ${sources.length}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  SizedBox(width: tokens.spaceSm),
                  IconButton.outlined(
                    tooltip: 'Next image',
                    onPressed: _index < sources.length - 1
                        ? () => _showPage(_index + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              )
            else
              Text(
                widget.images.isEmpty ? 'No product images' : 'Image 1 of 1',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: tokens.onSurfaceDim),
              ),
          ],
        );
      },
    );
  }
}
