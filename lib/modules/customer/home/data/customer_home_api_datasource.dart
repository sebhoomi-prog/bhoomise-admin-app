import 'dart:async';

import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/network/network_exceptions.dart';
import 'customer_home_defaults.dart';
import 'models/customer_home_api_model.dart';
import '../domain/customer_home_category.dart';

class CustomerHomeApiDataSource {
  CustomerHomeApiDataSource(this._apiClient);

  final ApiClient _apiClient;
  bool _appDocsEndpointMissing = false;

  Stream<List<CustomerHomeCategory>> watchCategories({
    Duration interval = const Duration(seconds: 30),
  }) async* {
    yield await fetchCategoriesOnce();
    yield* Stream<void>.periodic(interval).asyncMap((_) => fetchCategoriesOnce());
  }

  Future<List<CustomerHomeCategory>> fetchCategoriesOnce() async {
    if (_appDocsEndpointMissing) {
      return defaultCustomerHomeCategories();
    }
    try {
      final response = await _apiClient.get(
        ApiEndpoints.appDocs,
        queryParameters: const {'key': 'customer_home'},
      );
      final parsed = CustomerHomeApiModel.fromApi(response.data).categories;
      return parsed.isEmpty ? defaultCustomerHomeCategories() : parsed;
    } on NetworkException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('route') && msg.contains('could not be found')) {
        _appDocsEndpointMissing = true;
      }
      return defaultCustomerHomeCategories();
    } on Object {
      return defaultCustomerHomeCategories();
    }
  }

  Future<void> saveCategories(List<CustomerHomeCategory> categories) async {
    await _apiClient.post(
      ApiEndpoints.appDocs,
      data: {
        'key': 'customer_home',
        'categories': categories.map((e) => e.toFirestoreMap()).toList(),
      },
    );
  }
}

