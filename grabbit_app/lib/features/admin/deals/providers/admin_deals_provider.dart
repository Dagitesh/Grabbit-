import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:grabbit_app/core/api/api_service.dart';

class DealModerationReason {
  const DealModerationReason({required this.code, required this.label});
  final String code;
  final String label;

  factory DealModerationReason.fromJson(Map<String, dynamic> json) {
    return DealModerationReason(
      code: json['code'] as String,
      label: json['label'] as String,
    );
  }
}

class AdminDealsProvider with ChangeNotifier {
  AdminDealsProvider() {
    _bootstrap();
  }

  final _api = ApiService();

  List<DealModerationReason> _reasons = [];
  List<Map<String, dynamic>> _deals = [];
  bool _loading = false;
  String? _error;
  bool _includeRemoved = false;
  int _page = 1;
  final int _limit = 20;
  int _totalPages = 1;

  List<DealModerationReason> get reasons => List.unmodifiable(_reasons);
  List<Map<String, dynamic>> get deals => List.unmodifiable(_deals);
  bool get loading => _loading;
  String? get error => _error;
  bool get includeRemoved => _includeRemoved;
  int get page => _page;
  int get totalPages => _totalPages;
  bool get hasNextPage => _page < _totalPages;
  bool get hasPrevPage => _page > 1;

  Future<void> _bootstrap() async {
    await Future.wait([loadReasons(), loadDeals(refresh: true)]);
  }

  Future<void> loadReasons() async {
    try {
      final list = await _api.getAdminDealModerationReasons();
      _reasons = list.map((e) => DealModerationReason.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to load reasons';
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  void setIncludeRemoved(bool value) {
    if (_includeRemoved == value) return;
    _includeRemoved = value;
    notifyListeners();
    loadDeals(refresh: true);
  }

  Future<void> loadDeals({bool refresh = false}) async {
    if (refresh) _page = 1;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getAdminDeals(
        page: _page,
        limit: _limit,
        includeRemoved: _includeRemoved,
      );
      final raw = data['deals'];
      if (raw is List) {
        _deals = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        _deals = [];
      }
      _totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to load deals';
      _deals = [];
    } catch (e) {
      _error = e.toString();
      _deals = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> nextPage() async {
    if (_page >= _totalPages) return;
    _page++;
    await loadDeals(refresh: false);
  }

  Future<void> prevPage() async {
    if (_page <= 1) return;
    _page--;
    await loadDeals(refresh: false);
  }

  Future<String?> removeDeal(String dealId, String reasonCode) async {
    try {
      await _api.adminRemoveDeal(dealId, reasonCode);
      await loadDeals(refresh: false);
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message ?? 'Remove failed';
    } catch (e) {
      return e.toString();
    }
  }
}
