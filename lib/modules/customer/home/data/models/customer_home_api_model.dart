import '../../domain/customer_home_category.dart';

class CustomerHomeApiModel {
  const CustomerHomeApiModel({required this.categories});

  final List<CustomerHomeCategory> categories;

  factory CustomerHomeApiModel.fromApi(dynamic body) {
    final items = _extractCategories(body);
    final parsed = <CustomerHomeCategory>[];
    for (final item in items) {
      final c = CustomerHomeCategory.tryParse(item);
      if (c != null) parsed.add(c);
    }
    parsed.sort((a, b) => a.order.compareTo(b.order));
    return CustomerHomeApiModel(categories: parsed);
  }

  static List<dynamic> _extractCategories(dynamic body) {
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final data = map['data'];
      if (data is Map) {
        if (data['categories'] is List) {
          return data['categories'] as List<dynamic>;
        }
        final app = data['app'];
        if (app is Map && app['categories'] is List) {
          return app['categories'] as List<dynamic>;
        }
      }
      if (map['categories'] is List) {
        return map['categories'] as List<dynamic>;
      }
    }
    return const [];
  }
}

