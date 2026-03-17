import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:grabbit_app/core/api/api_service.dart';

class AdminSettingsProvider with ChangeNotifier {
  AdminSettingsProvider() {
    load();
  }

  final _api = ApiService();

  final introUrlController = TextEditingController();
  String? _introImageUrl;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  String? get introImageUrl => _introImageUrl;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getAppConfig();
      _introImageUrl = data['intro_image_url'] as String?;
      introUrlController.text = _introImageUrl ?? '';
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> saveIntroImage() async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      await _api.adminUpdateAppConfig(introImageUrl: introUrlController.text.trim().isEmpty ? null : introUrlController.text.trim());
      _introImageUrl = introUrlController.text.trim().isEmpty ? null : introUrlController.text.trim();
    } catch (e) {
      _error = e.toString();
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
