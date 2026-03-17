import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  ApiConstants._();

  /// Web: use localhost. Android emulator: 10.0.2.2. Override with --dart-define=API_BASE_URL=...
  static String get baseUrl {
    const fromEnv = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:3000';
    return 'http://10.0.2.2:3000'; // Android emulator
  }

  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String refreshToken = '/api/auth/refresh-token';

  static const String deals = '/api/deals';
  static String dealById(String id) => '/api/deals/$id';
  static const String orders = '/api/orders';
  static String orderById(String id) => '/api/orders/$id';
  static String cancelOrder(String id) => '/api/orders/$id/cancel';
  static const String usersMe = '/api/me';

  static const String upload = '/api/upload';
  static const String vendorProfile = '/api/vendor/profile';
  static const String vendorDashboard = '/api/vendor/dashboard';
  static const String vendorDeals = '/api/vendor/deals';
  static const String vendorOrders = '/api/vendor/orders';

  static const String categories = '/api/admin/categories';
  static String categoryById(String id) => '/api/admin/categories/$id';
  static const String appConfig = '/api/admin/app-config';
  static const String adminDashboard = '/api/admin/dashboard';
  static const String adminVendorsPending = '/api/admin/vendors/pending';
  static String adminVendorApprove(String userId) => '/api/admin/vendors/$userId/approve';
  static String adminVendorReject(String userId) => '/api/admin/vendors/$userId/reject';
}
