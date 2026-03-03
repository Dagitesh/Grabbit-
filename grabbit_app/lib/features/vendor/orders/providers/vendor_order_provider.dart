import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:grabbit_app/core/api/vendor_api_service.dart';
import 'package:grabbit_app/features/vendor/orders/data/vendor_order_model.dart';

class VendorOrderProvider with ChangeNotifier {
  VendorOrderProvider() {
    load();
  }

  final _api = VendorApiService();

  List<VendorOrderModel> _orders = [];
  bool _loading = true;
  String? _error;

  List<VendorOrderModel> get orders => _orders;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _api.getVendorOrders();
      _orders = list.map((e) => VendorOrderModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to load orders';
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
