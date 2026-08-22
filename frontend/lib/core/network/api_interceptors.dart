// Network layer - API interceptors for auth, errors, logging
// lib/core/network/api_interceptors.dart

import 'package:dio/dio.dart';
import '../di/injector.dart';
import '../storage/secure_storage.dart';

class ApiInterceptors extends Interceptor {
  final SecureStorage _secureStorage = getIt<SecureStorage>();
  bool _isRefreshing = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Add auth token if available
    final token = await _secureStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 - try to refresh token
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        // TODO: Implement token refresh logic
        // final refreshed = await _refreshToken();
        // if (refreshed) {
        //   return handler.resolve(await _retryRequest(err.requestOptions));
        // }
      } finally {
        _isRefreshing = false;
      }
    }
    return handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    return handler.next(response);
  }

  // Future<bool> _refreshToken() async { ... }
  // Future<Response> _retryRequest(RequestOptions options) async { ... }
}