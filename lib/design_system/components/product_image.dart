import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/image_urls.dart';
import '../theme/app_tokens.dart';

/// An image slot with the same layout while loading, missing, or unavailable.
/// Accepts HTTP(S) URLs or bundled assets/ paths. Both use Flutter's image cache;
/// persistent network-image disk caching is separate.
class ProductImage extends StatefulWidget {
  const ProductImage({super.key, this.imageUrl, required this.semanticLabel});

  /// A remote URL or a bundled asset path beginning with assets/.
  final String? imageUrl;
  final String semanticLabel;

  @override
  State<ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<ProductImage> {
  static const _assetPrefix = 'assets/';
  static const _loadingStrokeWidth = 2.0;
  static const _fallbackIconSize = 32.0;
  String? _source;
  bool _warningScheduled = false;

  @override
  void initState() {
    super.initState();
    _updateSource();
  }

  @override
  void didUpdateWidget(covariant ProductImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) _updateSource();
  }

  void _updateSource() {
    _warningScheduled = false;
    final input = widget.imageUrl?.trim();
    if (input != null && input.startsWith(_assetPrefix)) {
      _source = input;
      return;
    }
    _source = ImageUrls.remote(input);
    if (_source == null) _warnOnce('missing or unsupported image URL');
  }

  // Warnings run after the frame, once for the current input on this image slot.
  // Failed requests never log from build on every subsequent rebuild.
  void _warnOnce(String reason) {
    if (_warningScheduled) return;
    _warningScheduled = true;
    final label = widget.semanticLabel;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode) debugPrint('ProductImage: $reason ($label).');
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final source = _source;
    return ColoredBox(
      color: tokens.surfaceVariant,
      child: source == null
          ? _fallback(context, 'Image unavailable')
          : Image(
              image: source.startsWith(_assetPrefix)
                  ? AssetImage(source)
                  : NetworkImage(source),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              semanticLabel: widget.semanticLabel,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                return frame == null ? _loading(context) : child;
              },
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _loading(context);
              },
              errorBuilder: (context, error, stackTrace) {
                _warnOnce('image request failed');
                return _fallback(context, 'Image unavailable');
              },
            ),
    );
  }

  Widget _loading(BuildContext context) {
    return Semantics(
      label: 'Loading ${widget.semanticLabel}',
      child: Center(
        child: SizedBox.square(
          dimension: context.tokens.spaceXl,
          child: const CircularProgressIndicator(
            strokeWidth: _loadingStrokeWidth,
          ),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context, String label) {
    return Semantics(
      label: '$label for ${widget.semanticLabel}',
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: _fallbackIconSize,
          color: context.tokens.onSurface,
        ),
      ),
    );
  }
}
