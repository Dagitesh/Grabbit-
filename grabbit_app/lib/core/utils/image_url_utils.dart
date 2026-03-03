import '../constants/api_constants.dart';

/// Converts a backend image URL to one the app can load.
/// Use this when displaying deal images so that URLs returned by the server
/// (e.g. http://localhost:3000/uploads/...) are loaded using the app's
/// configured base URL (e.g. http://10.0.2.2:3000 for Android emulator).
String resolveImageUrl(String url) {
  if (url.isEmpty) return url;
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasAbsolutePath) return url;
  final path = uri.path;
  if (path.isEmpty) return url;
  final base = ApiConstants.baseUrl.replaceFirst(RegExp(r'/$'), '');
  return '$base$path';
}

List<String> resolveImageUrls(List<String>? urls) {
  if (urls == null || urls.isEmpty) return [];
  return urls.map(resolveImageUrl).toList();
}
