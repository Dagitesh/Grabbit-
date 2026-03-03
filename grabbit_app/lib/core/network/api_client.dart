import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../services/secure_storage_service.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  late final Dio _dio;
  Dio get dio => _dio;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorageService().getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  void _onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed != null) {
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $refreshed';
        try {
          final response = await _dio.fetch(opts);
          return handler.resolve(response);
        } catch (_) {}
      }
    }
    handler.next(err);
  }

  Future<String?> _tryRefreshToken() async {
    final refresh = await SecureStorageService().getRefreshToken();
    if (refresh == null || refresh.isEmpty) return null;
    try {
      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refresh},
      );
      final access = response.data['accessToken'] as String?;
      if (access != null) {
        await SecureStorageService().setAccessToken(access);
        final newRefresh = response.data['refreshToken'] as String?;
        if (newRefresh != null) {
          await SecureStorageService().setRefreshToken(newRefresh);
        }
        return access;
      }
    } catch (_) {}
    return null;
  }
}
