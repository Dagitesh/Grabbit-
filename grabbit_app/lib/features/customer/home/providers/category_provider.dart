import 'package:flutter/foundation.dart';
import 'package:grabbit_app/core/api/api_service.dart';
import 'package:grabbit_app/core/models/category_model.dart';

class CategoryProvider with ChangeNotifier {
  CategoryProvider() {
    loadCategories();
  }

  final _api = ApiService();

  List<CategoryModel> _categories = [];
  bool _loading = false;
  String? _error;

  List<CategoryModel> get categories => _categories;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadCategories() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await _api.getCategories();
      _categories = list
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
      _categories = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
