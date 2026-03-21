import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../data/models/auth_response_model.dart';
import '../data/models/user_model.dart';

String _errorMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['message'] != null) {
    return data['message'].toString();
  }
  // User-friendly message for connection/network errors
  switch (e.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Cannot reach server. Check your connection and that the backend is running.';
    case DioExceptionType.unknown:
      final msg = e.message ?? '';
      if (msg.contains('XMLHttpRequest') || msg.contains('network')) {
        return 'Cannot reach server. Check your connection and that the backend is running.';
      }
      break;
    default:
      break;
  }
  return e.message ?? 'Something went wrong';
}

class AuthApiService {
  AuthApiService._();
  static final AuthApiService _instance = AuthApiService._();
  factory AuthApiService() => _instance;

  final _dio = ApiClient().dio;

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required String subcityId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'phone': phone,
          'subcity_id': subcityId,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.verifyOtp,
        data: {'email': email, 'otpCode': otp},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_errorMessage(e));
    }
  }
}
