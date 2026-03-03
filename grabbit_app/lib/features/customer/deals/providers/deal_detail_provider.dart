import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:grabbit_app/core/api/api_service.dart';
import 'package:grabbit_app/features/customer/home/data/deal_model.dart';

class DealDetailProvider with ChangeNotifier {
  DealDetailProvider(this.dealId);

  final String dealId;
  final _api = ApiService();

  DealModel? _deal;
  bool _loading = true;
  String? _error;

  DealModel? get deal => _deal;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getDeal(dealId);
      _deal = DealModel.fromJson(data);
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to load deal';
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
