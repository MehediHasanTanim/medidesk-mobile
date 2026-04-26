import 'package:dio/dio.dart';
import '../../error/error_handler.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Convert DioException to AppException and re-throw as DioException.error
    final appException = mapDioException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: appException,
        type: err.type,
        response: err.response,
        message: appException.message,
      ),
    );
  }
}
