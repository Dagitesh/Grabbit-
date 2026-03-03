import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:grabbit_app/core/api/api_service.dart';
import 'package:grabbit_app/features/customer/orders/data/order_model.dart';

class OrderProvider with ChangeNotifier {
  OrderProvider() {
    loadOrders();
  }

  final _api = ApiService();

  List<OrderModel> _orders = [];
  bool _loading = false;
  String? _error;
  bool _creating = false;

  List<OrderModel> get orders => _orders;
  bool get loading => _loading;
  String? get error => _error;
  bool get creating => _creating;

  Future<void> loadOrders() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _api.getOrders();
      _orders = list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to load orders';
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Returns created order id or null on failure. Sets _creating and _error.
  Future<String?> createOrder({required String dealId, int quantity = 1}) async {
    _creating = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.createOrder(dealId: dealId, quantity: quantity);
      _creating = false;
      await loadOrders();
      notifyListeners();
      return data['id'] as String? ?? data['order_id'] as String?;
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to create order';
      _creating = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      _creating = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancelOrder(String orderId) async {
    _error = null;
    notifyListeners();
    try {
      await _api.cancelOrder(orderId);
      await loadOrders();
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to cancel order';
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
