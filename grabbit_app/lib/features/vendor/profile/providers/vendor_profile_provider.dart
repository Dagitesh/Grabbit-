import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:grabbit_app/core/api/vendor_api_service.dart';
import 'package:grabbit_app/features/vendor/profile/data/vendor_profile_model.dart';

class VendorProfileProvider with ChangeNotifier {
  VendorProfileProvider() {
    load();
  }

  final _api = VendorApiService();

  VendorProfileModel? _profile;
  bool _loading = true;
  String? _error;
  bool _saving = false;

  VendorProfileModel? get profile => _profile;
  bool get loading => _loading;
  String? get error => _error;
  bool get saving => _saving;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getProfile();
      _profile = VendorProfileModel.fromJson(data);
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to load profile';
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String businessName,
    String? businessDescription,
    required String phone,
    String? location,
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.updateProfile(
        businessName: businessName,
        businessDescription: businessDescription,
        phone: phone,
        location: location,
      );
      _profile = VendorProfileModel.fromJson(data);
      _saving = false;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message']?.toString() ?? e.message ?? 'Failed to update profile';
      _saving = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _saving = false;
      notifyListeners();
      return false;
    }
  }
}
