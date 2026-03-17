import 'package:flutter/foundation.dart';
import 'package:grabbit_app/core/api/api_service.dart';

class AdminPendingVendorsProvider with ChangeNotifier {
  AdminPendingVendorsProvider() {
    load();
  }

  final _api = ApiService();

  List<Map<String, dynamic>> _vendors = [];
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> get vendors => _vendors;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await _api.getAdminPendingVendors();
      _vendors = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _error = e.toString();
      _vendors = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> approve(String userId) async {
    try {
      await _api.adminApproveVendor(userId);
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> reject(String userId) async {
    try {
      await _api.adminRejectVendor(userId);
      await load();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
