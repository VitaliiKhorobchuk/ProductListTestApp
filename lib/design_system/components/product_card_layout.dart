import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

enum ProductCardVariant { standard, compact }

/// Shared geometry for real product cards and their decorative loading cards.
class ProductCardLayout extends StatelessWidget {
  const ProductCardLayout({
    super.key,
    required this.variant,
    required this.image,
    required this.content,
  });

  static const _stackedWidthThreshold = 300.0;
  static const _referenceTextSize = 14.0;
  static const _largeTextThreshold = 21.0;
  static const _imageWidth = 96.0;
  static const _imageHeight = 112.0;
  static const _stackedImageAspectRatio = 1.5;

  final ProductCardVariant variant;
  final Widget image;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            variant == ProductCardVariant.compact ||
            constraints.maxWidth < _stackedWidthThreshold ||
            MediaQuery.textScalerOf(context).scale(_referenceTextSize) >
                _largeTextThreshold;
        if (stacked) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.spaceMd,
                  tokens.spaceMd,
                  tokens.spaceMd,
                  0,
                ),
                child: AspectRatio(
                  aspectRatio: _stackedImageAspectRatio,
                  child: image,
                ),
              ),
              Padding(padding: EdgeInsets.all(tokens.spaceLg), child: content),
            ],
          );
        }
        return Padding(
          padding: EdgeInsets.all(tokens.spaceLg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: _imageWidth, height: _imageHeight, child: image),
              SizedBox(width: tokens.spaceLg),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }
}
