/// Parses human-readable retail pack labels into **grams** (Blinkit-style SKUs).
///
/// Supports: `200 g`, `200g`, `500 gm`, `1 kg`, `2kg`, `10 kg`, etc.
int? parsePackGrams(String raw) {
  final s = raw.trim().toLowerCase().replaceAll(',', '');
  if (s.isEmpty) return null;

  final kg = RegExp(r'(\d+(?:\.\d+)?)\s*kg\b').firstMatch(s);
  if (kg != null) {
    final v = double.tryParse(kg.group(1)!);
    if (v != null && v > 0) return (v * 1000).round();
  }

  final g = RegExp(r'(\d+)\s*(?:g|gm|gram|grams)\b').firstMatch(s);
  if (g != null) {
    final v = int.tryParse(g.group(1)!);
    if (v != null && v > 0) return v;
  }

  return null;
}
