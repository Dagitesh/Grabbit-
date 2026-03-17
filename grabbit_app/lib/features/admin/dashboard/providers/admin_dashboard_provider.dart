import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:grabbit_app/core/api/api_service.dart';

class AdminDashboardStats {
  AdminDashboardStats({
    required this.totalUsers,
    required this.totalVendors,
    required this.pendingVendors,
    required this.totalDeals,
    required this.totalOrders,
    required this.completedOrders,
    this.revenue,
  });

  final int totalUsers;
  final int totalVendors;
  final int pendingVendors;
  final int totalDeals;
  final int totalOrders;
  final int completedOrders;
  final double? revenue;

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      totalVendors: (json['totalVendors'] as num?)?.toInt() ?? 0,
      pendingVendors: (json['pendingVendors'] as num?)?.toInt() ?? 0,
      totalDeals: (json['totalDeals'] as num?)?.toInt() ?? 0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      completedOrders: (json['completedOrders'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble(),
    );
  }
}

class AdminDashboardProvider with ChangeNotifier {
  AdminDashboardProvider() {
    load();
  }

  final _api = ApiService();

  AdminDashboardStats? _stats;
  bool _loading = false;
  String? _error;

  AdminDashboardStats? get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getAdminDashboard();
      _stats = AdminDashboardStats.fromJson(data);
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
