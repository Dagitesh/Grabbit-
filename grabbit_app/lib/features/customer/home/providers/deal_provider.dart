import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:grabbit_app/core/api/api_service.dart';
import 'package:grabbit_app/features/customer/home/data/deal_model.dart';

class DealProvider with ChangeNotifier {
  DealProvider() {
    loadDeals();
  }

  final _api = ApiService();

  List<DealModel> _deals = [];
  int _page = 1;
  int _totalPages = 1;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  String? _search;
  String? _location;
  String? _category;
  double? _minPrice;
  double? _maxPrice;
  bool _activeOnly = true;

  List<DealModel> get deals => _deals;
  String? get selectedLocation => _location;
  String? get selectedCategory => _category;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  bool get canLoadMore => _page < _totalPages;
  int get totalPages => _totalPages;

  Future<void> loadDeals({bool refresh = true}) async {
    if (refresh) {
      _page = 1;
      _deals = [];
      _loading = true;
    } else {
      if (!canLoadMore || _loadingMore) return;
      _loadingMore = true;
    }
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getDeals(
        page: _page,
        limit: 10,
        search: _search,
        location: _location,
        category: _category,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        active: _activeOnly,
      );
      final items = (data['items'] as List? ?? data['data'] as List? ?? [])
          .map((e) => DealModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final meta = data['meta'] as Map<String, dynamic>?;
      _totalPages = (meta?['totalPages'] as num?)?.toInt() ?? 1;
      if (refresh) {
        _deals = items;
      } else {
        _deals = [..._deals, ...items];
      }
      _page++;
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to load deals';
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> setFilters({String? search, String? location, String? category, double? minPrice, double? maxPrice, bool? activeOnly}) async {
    _search = search;
    _location = location;
    _category = category;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    if (activeOnly != null) _activeOnly = activeOnly;
    await loadDeals(refresh: true);
  }

  void clearFilters() {
    _search = null;
    _location = null;
    _category = null;
    _minPrice = null;
    _maxPrice = null;
    _activeOnly = true;
  }
}
