import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';

/// Central API service. Uses ApiClient (Dio + JWT). Handles 401/500 in UI layer.
class ApiService {
  ApiService._();
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;

  Dio get _dio => ApiClient().dio;

  /// GET /api/deals?page=&limit=&search=&location=&category=&minPrice=&maxPrice=&active=
  Future<Map<String, dynamic>> getDeals({
    int page = 1,
    int limit = 10,
    String? search,
    String? location,
    String? category,
    double? minPrice,
    double? maxPrice,
    bool? active,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (location != null && location.isNotEmpty) 'location': location,
      if (category != null && category.isNotEmpty) 'category': category,
      if (minPrice != null) 'minPrice': minPrice.toString(),
      if (maxPrice != null) 'maxPrice': maxPrice.toString(),
      if (active != null) 'active': active.toString(),
    };
    final response = await _dio.get(ApiConstants.deals, queryParameters: query);
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/deals/:id
  Future<Map<String, dynamic>> getDeal(String id) async {
    final response = await _dio.get(ApiConstants.dealById(id));
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/orders
  Future<List<dynamic>> getOrders() async {
    final response = await _dio.get(ApiConstants.orders);
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data['orders'] is List) return data['orders'] as List;
    return [];
  }

  /// POST /api/orders  body: { deal_id, quantity? }
  Future<Map<String, dynamic>> createOrder({required String dealId, int quantity = 1}) async {
    final response = await _dio.post(
      ApiConstants.orders,
      data: {'deal_id': dealId, 'quantity': quantity},
    );
    return response.data as Map<String, dynamic>;
  }

  /// PATCH /api/orders/:id/cancel
  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    final response = await _dio.patch(ApiConstants.cancelOrder(orderId));
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/me
  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get(ApiConstants.usersMe);
    return response.data as Map<String, dynamic>;
  }
}
