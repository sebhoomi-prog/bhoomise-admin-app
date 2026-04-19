import '../../../../../core/util/pack_weight.dart';

class CartLine {
  const CartLine({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.variantLabel,
    required this.unitPriceMinor,
    required this.quantity,
    this.imageUrl,
    this.lineTag,
    this.variantGrams,
  });

  final String productId;
  final String variantId;
  final String productName;
  final String variantLabel;
  final int unitPriceMinor;
  final int quantity;
  final String? imageUrl;
  /// Uppercase badge (e.g. SPORE-GROWN). If null, UI may derive a demo tag.
  final String? lineTag;
  /// Pack size in grams; used for pack-targeted coupons. Parsed from [variantLabel] if null.
  final int? variantGrams;

  String get lineKey => '${productId}_$variantId';

  int get lineTotalMinor => unitPriceMinor * quantity;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'productId': productId,
        'variantId': variantId,
        'productName': productName,
        'variantLabel': variantLabel,
        'unitPriceMinor': unitPriceMinor,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'lineTag': lineTag,
        if (variantGrams != null) 'variantGrams': variantGrams,
      };

  factory CartLine.fromJson(Map<String, dynamic> m) {
    final label = m['variantLabel'] as String;
    return CartLine(
      productId: m['productId'] as String,
      variantId: m['variantId'] as String,
      productName: m['productName'] as String,
      variantLabel: label,
      unitPriceMinor: (m['unitPriceMinor'] as num).toInt(),
      quantity: (m['quantity'] as num).toInt(),
      imageUrl: m['imageUrl'] as String?,
      lineTag: m['lineTag'] as String?,
      variantGrams: (m['variantGrams'] as num?)?.toInt() ?? parsePackGrams(label),
    );
  }

  CartLine copyWith({
    int? quantity,
    String? imageUrl,
    String? lineTag,
    int? variantGrams,
  }) {
    return CartLine(
      productId: productId,
      variantId: variantId,
      productName: productName,
      variantLabel: variantLabel,
      unitPriceMinor: unitPriceMinor,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      lineTag: lineTag ?? this.lineTag,
      variantGrams: variantGrams ?? this.variantGrams,
    );
  }
}
