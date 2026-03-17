import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';

/// Central API service. Uses ApiClient (Dio + JWT). Handles 401/500 in UI layer.
class ApiService {
  ApiService._();
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;

  Dio get _dio => ApiClient().dio;

  /// GET /api/deals?page=&limit=&search=&location=&category=&categoryId=&minPrice=&maxPrice=&active=
  Future<Map<String, dynamic>> getDeals({
    int page = 1,
    int limit = 10,
    String? search,
    String? location,
    String? category,
    String? categoryId,
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
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
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

  /// GET /api/admin/categories (public list for Explore)
  Future<List<dynamic>> getCategories() async {
    final response = await _dio.get(ApiConstants.categories);
    final data = response.data;
    if (data is List) return data;
    return [];
  }

  /// GET /api/admin/app-config (public intro image)
  Future<Map<String, dynamic>> getAppConfig() async {
    final response = await _dio.get(ApiConstants.appConfig);
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/admin/dashboard (admin only)
  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await _dio.get(ApiConstants.adminDashboard);
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/admin/vendors/pending (admin only)
  Future<List<dynamic>> getAdminPendingVendors() async {
    final response = await _dio.get(ApiConstants.adminVendorsPending);
    final data = response.data;
    if (data is List) return data;
    return [];
  }

  /// PATCH /api/admin/vendors/:userId/approve (admin only)
  Future<Map<String, dynamic>> adminApproveVendor(String userId) async {
    final response = await _dio.patch(ApiConstants.adminVendorApprove(userId));
    return response.data as Map<String, dynamic>;
  }

  /// PATCH /api/admin/vendors/:userId/reject (admin only)
  Future<Map<String, dynamic>> adminRejectVendor(String userId) async {
    final response = await _dio.patch(ApiConstants.adminVendorReject(userId));
    return response.data as Map<String, dynamic>;
  }

  /// POST /api/admin/categories (admin only)
  Future<Map<String, dynamic>> adminCreateCategory({required String name, String? icon}) async {
    final response = await _dio.post(ApiConstants.categories, data: {'name': name, 'icon': icon ?? 'category'});
    return response.data as Map<String, dynamic>;
  }

  /// PUT /api/admin/categories/:id (admin only)
  Future<Map<String, dynamic>> adminUpdateCategory(String id, {String? name, String? icon}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (icon != null) data['icon'] = icon;
    final response = await _dio.put(ApiConstants.categoryById(id), data: data);
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /api/admin/categories/:id (admin only)
  Future<void> adminDeleteCategory(String id) async {
    await _dio.delete(ApiConstants.categoryById(id));
  }

  /// PUT /api/admin/app-config (admin only)
  Future<Map<String, dynamic>> adminUpdateAppConfig({String? introImageUrl}) async {
    final response = await _dio.put(ApiConstants.appConfig, data: {'intro_image_url': introImageUrl});
    return response.data as Map<String, dynamic>;
  }
}
