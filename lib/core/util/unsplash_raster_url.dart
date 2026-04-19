/// Unsplash URLs use `auto=format` by default, which may serve AVIF/WebP. Android's
/// [ImageDecoder] can throw `DecodeException` / `unimplemented` for AVIF on some devices.
///
/// Use this for any [NetworkImage] / [Image.network] loading Unsplash raster URLs.
String unsplashAsJpeg(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host != 'images.unsplash.com') return url;
  final q = Map<String, String>.from(uri.queryParameters);
  q.remove('auto');
  q['fm'] = 'jpg';
  return uri.replace(queryParameters: q).toString();
}
