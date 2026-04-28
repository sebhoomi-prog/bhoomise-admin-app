// Admin API request/response models matching Postman collection.

int _readInt(dynamic v, [int defaultValue = 0]) {
  if (v == null) return defaultValue;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? defaultValue;
}

int? _readIntOpt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

/// Laravel JSON columns may decode as [List] or (legacy) as [Map].
List<int> _readIntList(dynamic v) {
  if (v == null) return [];
  if (v is List) {
    return v.map((e) => _readInt(e)).toList();
  }
  if (v is Map) {
    return v.values.map((e) => _readInt(e)).toList();
  }
  return [];
}

List<Map<String, dynamic>> _readMapList(dynamic v) {
  if (v == null) return [];
  if (v is List) {
    final out = <Map<String, dynamic>>[];
    for (final e in v) {
      if (e is Map<String, dynamic>) {
        out.add(e);
      } else if (e is Map) {
        out.add(Map<String, dynamic>.from(e));
      }
    }
    return out;
  }
  return [];
}

class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.data,
    this.message,
  });

  final bool success;
  final T? data;
  final String? message;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? dataParser,
  ) {
    return ApiResponse(
      success: json['success'] == true,
      data: json['data'] != null && dataParser != null
          ? dataParser(json['data'])
          : json['data'] as T?,
      message: json['message']?.toString(),
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.variants = const [],
    this.published = false,
  });

  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<ProductVariant> variants;
  final bool published;

  factory Product.fromJson(Map<String, dynamic> json) {
    var variants = _readMapList(json['variants'])
        .map(ProductVariant.fromJson)
        .toList();
    if (variants.isEmpty) {
      final synthesized = ProductVariant.fromJson(json);
      if (synthesized.id.isNotEmpty) {
        variants = [synthesized];
      }
    }

    return Product(
      id: (json['id'] ?? json['product_id'] ?? '').toString(),
      name: (json['name'] ?? json['product_name'] ?? json['display_name'] ?? '')
          .toString(),
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      variants: variants,
      published: json['published'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        if (imageUrl != null) 'image_url': imageUrl,
        'variants': variants.map((v) => v.toJson()).toList(),
        'published': published,
      };
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.label,
    required this.totalGrams,
    required this.priceMinor,
    this.stock = 0,
    this.lowStockThreshold = 5,
  });

  final String id;
  final String label;
  final int totalGrams;
  final int priceMinor;
  final int stock;
  final int lowStockThreshold;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    final priceMinorRaw = json['priceMinor'] ?? json['price_minor'];
    final priceMinor = priceMinorRaw != null
        ? _readInt(priceMinorRaw)
        : (_readInt(json['price']) * 100);

    return ProductVariant(
      id: (json['id'] ?? json['variant_id'] ?? json['product_id'] ?? '')
          .toString(),
      label: (json['label'] ?? json['unit'] ?? '').toString(),
      totalGrams: _readInt(json['totalGrams'] ?? json['total_grams']),
      priceMinor: priceMinor,
      stock: _readInt(json['stock'] ?? json['inventory']),
      lowStockThreshold: _readInt(
        json['lowStockThreshold'] ?? json['low_stock_threshold'],
        5,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'totalGrams': totalGrams,
        'priceMinor': priceMinor,
        'stock': stock,
        'lowStockThreshold': lowStockThreshold,
      };
}

class Coupon {
  const Coupon({
    required this.code,
    this.percentOff = 0,
    this.active = true,
    this.maxRedemptions,
    this.eligiblePackGrams = const [],
    this.minPackGramsAnyLine,
    this.expiresAt,
    this.usageCount = 0,
  });

  final String code;
  final int percentOff;
  final bool active;
  final int? maxRedemptions;
  final List<int> eligiblePackGrams;
  final int? minPackGramsAnyLine;
  final DateTime? expiresAt;
  final int usageCount;

  factory Coupon.fromJson(Map<String, dynamic> json) {
    DateTime? expires;
    final expiresRaw = json['expiresAt'] ?? json['expires_at'];
    if (expiresRaw != null) {
      if (expiresRaw is String) {
        expires = DateTime.tryParse(expiresRaw);
      }
    }
    
    return Coupon(
      code: (json['code'] ?? '').toString(),
      percentOff: _readInt(json['percentOff'] ?? json['percent_off']),
      active: json['active'] == true,
      maxRedemptions: _readIntOpt(json['maxRedemptions'] ?? json['max_redemptions']),
      eligiblePackGrams:
          _readIntList(json['eligiblePackGrams'] ?? json['eligible_pack_grams']),
      minPackGramsAnyLine: _readIntOpt(
        json['minPackGramsAnyLine'] ?? json['min_pack_grams_any_line'],
      ),
      expiresAt: expires,
      usageCount: _readInt(json['usageCount'] ?? json['usage_count']),
    );
  }

  Map<String, dynamic> toJson() => {
        'percentOff': percentOff,
        'active': active,
        if (maxRedemptions != null) 'maxRedemptions': maxRedemptions,
        if (eligiblePackGrams.isNotEmpty) 'eligiblePackGrams': eligiblePackGrams,
        if (minPackGramsAnyLine != null)
          'minPackGramsAnyLine': minPackGramsAnyLine,
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      };
}

class Store {
  const Store({
    required this.id,
    required this.name,
    this.city,
    this.active = true,
    this.storePhotoUrl,
  });

  final String id;
  final String name;
  final String? city;
  final bool active;
  final String? storePhotoUrl;

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      city: json['city']?.toString(),
      active: json['active'] == true,
      storePhotoUrl: json['storePhotoUrl']?.toString() ??
          json['store_photo_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (city != null) 'city': city,
        'active': active,
        if (storePhotoUrl != null) 'storePhotoUrl': storePhotoUrl,
      };
}

class StoreInventoryItem {
  const StoreInventoryItem({
    required this.productId,
    required this.variantId,
    required this.productName,
    required this.label,
    required this.stock,
  });

  final String productId;
  final String variantId;
  final String productName;
  final String label;
  final int stock;

  String get inventoryKey => '${productId}_$variantId';

  factory StoreInventoryItem.fromJson(Map<String, dynamic> json) {
    return StoreInventoryItem(
      productId: (json['productId'] ?? json['product_id'] ?? '').toString(),
      variantId: (json['variantId'] ?? json['variant_id'] ?? '').toString(),
      productName:
          (json['productName'] ?? json['product_name'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      stock: _readInt(json['stock']),
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'variantId': variantId,
        'productName': productName,
        'label': label,
        'stock': stock,
      };
}

class Order {
  const Order({
    required this.id,
    this.customerUserId,
    required this.type,
    required this.status,
    this.storeId,
    this.storeName,
    this.totalLabel,
    this.items = const [],
  });

  final String id;
  final int? customerUserId;
  final String type;
  final String status;
  final String? storeId;
  final String? storeName;
  final String? totalLabel;
  final List<OrderItem> items;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: (json['id'] ?? '').toString(),
      customerUserId:
          _readIntOpt(json['customerUserId'] ?? json['customer_user_id']),
      type: (json['type'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      storeId: json['storeId']?.toString() ?? json['store_id']?.toString(),
      storeName:
          json['storeName']?.toString() ?? json['store_name']?.toString(),
      totalLabel:
          json['totalLabel']?.toString() ?? json['total_label']?.toString(),
      items: _readMapList(json['items']).map(OrderItem.fromJson).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (customerUserId != null) 'customerUserId': customerUserId,
        'type': type,
        'status': status,
        if (storeId != null) 'storeId': storeId,
        if (storeName != null) 'storeName': storeName,
        if (totalLabel != null) 'totalLabel': totalLabel,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.variantId,
    required this.quantity,
    this.priceMinor,
  });

  final String productId;
  final String variantId;
  final int quantity;
  final int? priceMinor;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: (json['productId'] ?? json['product_id'] ?? '').toString(),
      variantId: (json['variantId'] ?? json['variant_id'] ?? '').toString(),
      quantity: _readInt(json['quantity']),
      priceMinor: _readIntOpt(json['priceMinor'] ?? json['price_minor']),
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'variantId': variantId,
        'quantity': quantity,
        if (priceMinor != null) 'priceMinor': priceMinor,
      };
}

class ListingSubmission {
  const ListingSubmission({
    required this.id,
    required this.storeId,
    required this.title,
    this.varietyLabel,
    this.description,
    this.priceMinor,
    this.stock,
    this.packTotalGrams,
    this.packagingKind,
    this.approvalStatus,
  });

  final String id;
  final String storeId;
  final String title;
  final String? varietyLabel;
  final String? description;
  final int? priceMinor;
  final int? stock;
  final int? packTotalGrams;
  final String? packagingKind;
  final String? approvalStatus;

  factory ListingSubmission.fromJson(Map<String, dynamic> json) {
    return ListingSubmission(
      id: (json['id'] ?? '').toString(),
      storeId: (json['storeId'] ?? json['store_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      varietyLabel:
          json['varietyLabel']?.toString() ?? json['variety_label']?.toString(),
      description: json['description']?.toString(),
      priceMinor: _readIntOpt(json['priceMinor'] ?? json['price_minor']),
      stock: _readIntOpt(json['stock']),
      packTotalGrams:
          _readIntOpt(json['packTotalGrams'] ?? json['pack_total_grams']),
      packagingKind:
          json['packagingKind']?.toString() ?? json['packaging_kind']?.toString(),
      approvalStatus: json['approvalStatus']?.toString() ??
          json['approval_status']?.toString(),
    );
  }
}

class User {
  const User({
    required this.id,
    required this.phone,
    this.name,
    this.role,
  });

  final int id;
  final String phone;
  final String? name;
  final String? role;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _readInt(json['id']),
      phone: (json['phone'] ?? '').toString(),
      name: json['name']?.toString(),
      role: json['role']?.toString(),
    );
  }
}

class AdminPhone {
  const AdminPhone({required this.phone});

  final String phone;

  factory AdminPhone.fromJson(Map<String, dynamic> json) {
    return AdminPhone(phone: (json['phone'] ?? '').toString());
  }
}
