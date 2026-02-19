import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  // Use 127.0.0.1 for Web/iOS Simulator, 10.0.2.2 for Android Emulator
  // Since user said "running on Chrome", 127.0.0.1 is correct.
  static const String baseUrl = 'https://plivacki-klub-cms-app.onrender.com';

  final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiClient()
    : _dio = Dio(BaseOptions(baseUrl: baseUrl)),
      _storage = const FlutterSecureStorage() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add Bearer Token if available
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Handle 401 Unauthorized (Logout flow could trigger here)
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<void> setToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'access_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }
}
