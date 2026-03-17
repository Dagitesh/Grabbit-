import 'package:flutter/foundation.dart';
import 'package:grabbit_app/core/api/api_service.dart';
import 'package:grabbit_app/core/models/category_model.dart';

class AdminCategoriesProvider with ChangeNotifier {
  AdminCategoriesProvider() {
    load();
  }

  final _api = ApiService();

  List<CategoryModel> _categories = [];
  bool _loading = false;
  String? _error;

  List<CategoryModel> get categories => _categories;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await _api.getCategories();
      _categories = list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
      _categories = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> create({required String name, String? icon}) async {
    await _api.adminCreateCategory(name: name, icon: icon);
    await load();
  }

  Future<void> update(String id, {String? name, String? icon}) async {
    await _api.adminUpdateCategory(id, name: name, icon: icon);
    await load();
  }

  Future<void> delete(String id) async {
    await _api.adminDeleteCategory(id);
    await load();
  }
}
