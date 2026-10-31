/// Syntax normalization shared by API image mapping and network-image rendering.
abstract final class ImageUrls {
  /// Assets remain a separate, presentation-only source type.
  static String? remote(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
            uri.hasAuthority &&
            uri.host.isNotEmpty &&
            (uri.scheme == 'http' || uri.scheme == 'https')
        ? uri.toString()
        : null;
  }
}
