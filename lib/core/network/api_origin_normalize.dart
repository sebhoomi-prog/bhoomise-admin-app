/// Normalizes configured API origin by trimming trailing slash only.
///
/// Do not strip `/api` because current production backend is hosted in an
/// `/api` directory and app endpoints already include `/api/...` constants.
String normalizeApiOriginForDio(String rawBaseUrl) {
  var s = rawBaseUrl.trim();
  if (s.isEmpty) return s;
  while (s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}
