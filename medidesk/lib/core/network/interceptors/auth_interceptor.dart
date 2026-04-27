import 'package:dio/dio.dart';
import '../../network/api_endpoints.dart';
import '../../storage/secure_storage_service.dart';
import '../../error/app_exception.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, {this.onSessionExpired});

  final SecureStorageService _storage;

  /// Called when the refresh token is also expired/invalid.
  /// Typically wired to clear `isAuthenticatedProvider` so the router
  /// redirects the user back to the login screen.
  final void Function()? onSessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Attempt refresh
      final refreshed = await _tryRefresh(err.requestOptions);
      if (refreshed != null) {
        handler.resolve(refreshed);
        return;
      }
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const UnauthorizedException(),
          type: DioExceptionType.badResponse,
          response: err.response,
        ),
      );
      return;
    }
    handler.next(err);
  }

  Future<Response<dynamic>?> _tryRefresh(
    RequestOptions original,
  ) async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: original.baseUrl,
          connectTimeout: const Duration(seconds: 10),
        ),
      );
      final resp = await dio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh': refreshToken},
      );
      final newAccess = resp.data['access'] as String?;
      if (newAccess == null) return null;

      await _storage.saveTokens(
        accessToken: newAccess,
        refreshToken: refreshToken,
      );

      // Retry original request with new token
      original.headers['Authorization'] = 'Bearer $newAccess';
      return await dio.fetch(original);
    } catch (_) {
      await _storage.clearTokens();
      // Notify the app layer so it can clear isAuthenticatedProvider and
      // let the router redirect back to /login.
      onSessionExpired?.call();
      return null;
    }
  }
}
