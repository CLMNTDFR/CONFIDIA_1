import 'package:dio/dio.dart';

String apiErrorMessage(Object error, {String fallback = 'Une erreur est survenue'}) {
  if (error is! DioException) return fallback;
  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return 'Impossible de joindre le serveur. Vérifiez que le backend est démarré.';
  }
  final data = error.response?.data;
  if (data is Map && data['detail'] is String) {
    return data['detail'] as String;
  }
  if (data is Map && data['detail'] is List) {
    final parts = <String>[];
    for (final item in data['detail'] as List) {
      if (item is Map && item['msg'] != null) {
        var msg = item['msg'].toString();
        const prefix = 'Value error, ';
        if (msg.startsWith(prefix)) msg = msg.substring(prefix.length);
        parts.add(msg);
      }
    }
    if (parts.isNotEmpty) return parts.join('\n');
  }
  return error.response?.statusMessage ?? fallback;
}
