import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:grabbit_app/core/api/vendor_api_service.dart';
import 'package:grabbit_app/features/vendor/dashboard/data/vendor_dashboard_model.dart';

class VendorDashboardProvider with ChangeNotifier {
  VendorDashboardProvider() {
    load();
  }

  final _api = VendorApiService();

  VendorDashboardModel? _dashboard;
  bool _loading = true;
  String? _error;

  VendorDashboardModel? get dashboard => _dashboard;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getDashboard();
      _dashboard = VendorDashboardModel.fromJson(data);
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to load dashboard';
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
