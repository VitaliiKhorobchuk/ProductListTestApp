import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/components/product_image.dart';

const _assetPath = 'assets/images/sample_products/red_lipstick.webp';

/// Keeps the real ProductImage pending without a server, timer, or API request.
class LoadingImagePreview extends StatefulWidget {
  const LoadingImagePreview({super.key});

  @override
  State<LoadingImagePreview> createState() => _LoadingImagePreviewState();
}

class _LoadingImagePreviewState extends State<LoadingImagePreview> {
  final _bundle = _PendingImageBundle();

  @override
  void dispose() {
    // Pending providers must not remain in the shared image cache after leaving.
    unawaited(AssetImage(_assetPath, bundle: _bundle).evict());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DefaultAssetBundle(
    bundle: _bundle,
    child: const ProductImage(
      imageUrl: _assetPath,
      semanticLabel: 'Preview image held in loading state',
    ),
  );
}

class _PendingImageBundle extends CachingAssetBundle {
  final _pending = Completer<ByteData>();

  @override
  Future<ByteData> load(String key) {
    if (key == _assetPath) return _pending.future;
    return rootBundle.load(key);
  }
}
