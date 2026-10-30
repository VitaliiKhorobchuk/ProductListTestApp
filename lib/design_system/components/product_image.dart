import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    if (input != null && input.startsWith('assets/')) {
      _source = input;
      return;
    }
    final uri = input == null || input.isEmpty ? null : Uri.tryParse(input);
    _source =
        uri != null &&
            (uri.scheme == 'https' || uri.scheme == 'http') &&
            uri.host.isNotEmpty
        ? uri.toString()
        : null;
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
              image: source.startsWith('assets/')
                  ? AssetImage(source)
                  : NetworkImage(source),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              semanticLabel: widget.semanticLabel,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Semantics(
                  label: 'Loading ${widget.semanticLabel}',
                  child: Center(
                    child: SizedBox.square(
                      dimension: tokens.spaceXl,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                _warnOnce('image request failed');
                return _fallback(context, 'Image unavailable');
              },
            ),
    );
  }

  Widget _fallback(BuildContext context, String label) {
    return Semantics(
      label: '$label for ${widget.semanticLabel}',
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 32,
          color: context.tokens.onSurface,
        ),
      ),
    );
  }
}
