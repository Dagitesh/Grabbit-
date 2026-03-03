import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';
import '../../features/auth/presentation/screens/login_screen.dart'; // relative to lib

/// Handle API errors: 401 → clear storage & navigate to login; 5xx → SnackBar.
Future<void> handleApiError(BuildContext? context, dynamic e, {VoidCallback? onLogout}) async {
  if (e is! DioException) return;
  final status = e.response?.statusCode;
  if (status == 401) {
    await SecureStorageService().clearAll();
    if (context != null && context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
    onLogout?.call();
  } else if (status != null && status >= 500 && context != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.response?.data?['message'] ?? 'Server error. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

String apiErrorMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['message'] != null) return data['message'].toString();
  if (e.response?.statusCode == 401) return 'Session expired. Please log in again.';
  if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
    return 'Server error. Please try again.';
  }
  return e.message ?? 'Something went wrong';
}
