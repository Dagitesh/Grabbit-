import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import 'api_service.dart';

/// Vendor-specific API: profile, dashboard, vendor deals, vendor orders.
/// Deals CRUD use ApiService (POST/PUT /api/deals).
class VendorApiService {
  VendorApiService._();
  static final VendorApiService _instance = VendorApiService._();
  factory VendorApiService() => _instance;

  Dio get _dio => ApiClient().dio;
  ApiService get _api => ApiService();

  /// GET /api/vendor/profile
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get(ApiConstants.vendorProfile);
    return response.data as Map<String, dynamic>;
  }

  /// PUT /api/vendor/profile
  Future<Map<String, dynamic>> updateProfile({
    required String businessName,
    String? businessDescription,
    required String phone,
    String? location,
    String? tin,
  }) async {
    final data = <String, dynamic>{
      'business_name': businessName,
      'business_description': businessDescription,
      'phone': phone,
      'location': location,
    };
    if (tin != null) data['tin'] = tin;
    final response = await _dio.put(ApiConstants.vendorProfile, data: data);
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/vendor/dashboard
  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _dio.get(ApiConstants.vendorDashboard);
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/vendor/deals
  Future<List<dynamic>> getVendorDeals() async {
    final response = await _dio.get(ApiConstants.vendorDeals);
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data['deals'] is List) return data['deals'] as List;
    return [];
  }

  /// GET /api/vendor/orders
  Future<List<dynamic>> getVendorOrders() async {
    final response = await _dio.get(ApiConstants.vendorOrders);
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data['orders'] is List) return data['orders'] as List;
    return [];
  }

  /// POST /api/upload
  Future<String?> uploadFile(XFile xFile) async {
    final bytes = await xFile.readAsBytes();
    final name = xFile.name.isNotEmpty ? xFile.name : 'image.jpg';
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: name),
    });
    final response = await _dio.post(ApiConstants.upload, data: formData);
    final data = response.data;
    if (data is Map && data['url'] != null) return data['url'] as String;
    return null;
  }

  /// POST /api/deals (requires subcity_id + category_id)
  Future<Map<String, dynamic>> createDeal({
    required String title,
    String? description,
    required String subcityId,
    required String categoryId,
    String? location,
    String? category,
    required double originalPrice,
    required double discountedPrice,
    required int quantityAvailable,
    required DateTime expiryDate,
    List<String>? images,
    String? locationId,
    int? totalQuantity,
    DateTime? startTime,
    DateTime? expiryTime,
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'description': description,
      'subcity_id': subcityId,
      'category_id': categoryId,
      'location': location,
      'category': category,
      'original_price': originalPrice,
      'discounted_price': discountedPrice,
      'quantity_available': quantityAvailable,
      'expiry_date': expiryDate.toIso8601String(),
    };
    if (images != null && images.isNotEmpty) data['images'] = images;
    if (locationId != null) data['location_id'] = locationId;
    if (totalQuantity != null) data['total_quantity'] = totalQuantity;
    if (startTime != null) data['start_time'] = startTime.toIso8601String();
    if (expiryTime != null) data['expiry_time'] = expiryTime.toIso8601String();
    final response = await _dio.post(ApiConstants.deals, data: data);
    return response.data as Map<String, dynamic>;
  }

  /// PUT /api/deals/:id
  Future<Map<String, dynamic>> updateDeal(
    String id, {
    String? title,
    String? description,
    String? subcityId,
    String? categoryId,
    String? location,
    String? category,
    double? originalPrice,
    double? discountedPrice,
    int? quantityAvailable,
    DateTime? expiryDate,
    DateTime? expiryTime,
    DateTime? startTime,
    int? totalQuantity,
    String? locationId,
    bool? isActive,
    List<String>? images,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (subcityId != null) data['subcity_id'] = subcityId;
    if (categoryId != null) data['category_id'] = categoryId;
    if (location != null) data['location'] = location;
    if (category != null) data['category'] = category;
    if (originalPrice != null) data['original_price'] = originalPrice;
    if (discountedPrice != null) data['discounted_price'] = discountedPrice;
    if (quantityAvailable != null) data['quantity_available'] = quantityAvailable;
    if (expiryDate != null) data['expiry_date'] = expiryDate.toIso8601String();
    if (expiryTime != null) data['expiry_time'] = expiryTime.toIso8601String();
    if (startTime != null) data['start_time'] = startTime.toIso8601String();
    if (totalQuantity != null) data['total_quantity'] = totalQuantity;
    if (locationId != null) data['location_id'] = locationId;
    if (isActive != null) data['is_active'] = isActive;
    if (images != null) data['images'] = images;
    final response = await _dio.put(ApiConstants.dealById(id), data: data);
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/deals/:id (for edit pre-fill)
  Future<Map<String, dynamic>> getDeal(String id) async {
    return _api.getDeal(id);
  }
}
