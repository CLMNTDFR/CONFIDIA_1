import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiConfig {
  static const _storageKey = 'api_base_url';
  static const _envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String> resolveBaseUrl() async {
    if (_envUrl.isNotEmpty) return _envUrl;

    final stored = await _storage.read(key: _storageKey);
    if (stored != null && stored.isNotEmpty) return stored;

    if (kIsWeb) return 'http://localhost:8000/api/v1';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }

  static Future<void> saveBaseUrl(String hostOrUrl) async {
    final normalized = normalizeUrl(hostOrUrl);
    if (normalized.isEmpty) {
      await _storage.delete(key: _storageKey);
      return;
    }
    await _storage.write(key: _storageKey, value: normalized);
  }

  static Future<String?> readStoredHost() async {
    final url = await _storage.read(key: _storageKey);
    if (url == null || url.isEmpty) return null;
    return hostFromApiUrl(url);
  }

  static String normalizeUrl(String input) {
    var value = input.trim();
    if (value.isEmpty) return '';

    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'http://$value';
    }

    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return '';

    final path = uri.path.endsWith('/api/v1')
        ? uri.path
        : '${uri.path.replaceAll(RegExp(r'/+$'), '')}/api/v1';

    return uri.replace(path: path).toString();
  }

  static String hostFromApiUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.host}$port';
  }
}
