import 'package:dio/dio.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import '../storage/secure_storage_service.dart';

class DioClient {
  DioClient._();

  static Dio create({
    required String baseUrl,
    required SecureStorageService storage,
    /// Optional callback invoked when the refresh token is expired/invalid.
    /// Wire this to `isAuthenticatedProvider` so the router redirects to /login.
    void Function()? onSessionExpired,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(storage, onSessionExpired: onSessionExpired),
      ErrorInterceptor(),
      LoggingInterceptor(),
    ]);

    return dio;
  }
}
