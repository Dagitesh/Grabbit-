import 'package:flutter/foundation.dart';
import '../../data/models/user_model.dart';
import '../../services/auth_api_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import 'package:grabbit_app/core/api/api_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  AuthProvider() {
    _checkAuth();
  }

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  AuthStatus get status => _status;
  UserModel? get user => _user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  final _api = AuthApiService();
  final _storage = SecureStorageService();
  final _apiService = ApiService();

  Future<void> _checkAuth() async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      _status = AuthStatus.authenticated;
      _user = UserModel(
        id: '',
        fullName: '',
        email: await _storage.getUserEmail() ?? '',
        role: 'CUSTOMER',
        isVerified: true,
      );
      notifyListeners();
      try {
        final data = await _apiService.getMe();
        _user = UserModel.fromJson(data);
      } catch (_) {
        // Keep default user if /api/me fails
      }
      notifyListeners();
    } else {
      _status = AuthStatus.unauthenticated;
      _user = null;
      notifyListeners();
    }
  }

  Future<void> setAuthFromLogin(UserModel user, String accessToken, String refreshToken) async {
    await _storage.setAccessToken(accessToken);
    await _storage.setRefreshToken(refreshToken);
    await _storage.setUserEmail(user.email);
    _user = user;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required String subcityId,
  }) async {
    return _api.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      phone: phone,
      subcityId: subcityId,
    );
  }

  Future<void> login({required String email, required String password}) async {
    final res = await _api.login(email: email, password: password);
    await setAuthFromLogin(res.user, res.accessToken, res.refreshToken);
  }

  Future<Map<String, dynamic>> verifyOtp({required String email, required String otp}) async {
    return _api.verifyOtp(email: email, otp: otp);
  }

  Future<void> logout() async {
    await _storage.clearAll();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Fetch current user from GET /api/me (e.g. for Profile screen).
  Future<void> fetchUser() async {
    if (_status != AuthStatus.authenticated) return;
    try {
      final data = await _apiService.getMe();
      _user = UserModel.fromJson(data);
      notifyListeners();
    } catch (_) {
      // Keep existing _user on failure
    }
  }
}
