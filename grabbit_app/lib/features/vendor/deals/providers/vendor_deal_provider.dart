import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:grabbit_app/core/api/vendor_api_service.dart';
import 'package:grabbit_app/features/customer/home/data/deal_model.dart';

class VendorDealProvider with ChangeNotifier {
  VendorDealProvider() {
    load();
  }

  final _api = VendorApiService();

  List<DealModel> _deals = [];
  bool _loading = true;
  String? _error;
  bool _saving = false;

  List<DealModel> get deals => _deals;
  bool get loading => _loading;
  String? get error => _error;
  bool get saving => _saving;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _api.getVendorDeals();
      _deals = list.map((e) => DealModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to load deals';
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<DealModel?> createDeal({
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
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.createDeal(
        title: title,
        description: description,
        subcityId: subcityId,
        categoryId: categoryId,
        location: location,
        category: category,
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
        quantityAvailable: quantityAvailable,
        expiryDate: expiryDate,
        images: images,
      );
      _saving = false;
      await load();
      notifyListeners();
      return DealModel.fromJson(data);
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to create deal';
      _saving = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      _saving = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateDeal(
    String id, {
    String? title,
    String? description,
    String? location,
    String? category,
    double? originalPrice,
    double? discountedPrice,
    int? quantityAvailable,
    DateTime? expiryDate,
    bool? isActive,
    List<String>? images,
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      await _api.updateDeal(
        id,
        title: title,
        description: description,
        location: location,
        category: category,
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
        quantityAvailable: quantityAvailable,
        expiryDate: expiryDate,
        isActive: isActive,
        images: images,
      );
      _saving = false;
      await load();
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to update deal';
      _saving = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _saving = false;
      notifyListeners();
      return false;
    }
  }
}
