import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[HTTP] --> ${options.method} ${options.uri}\n'
        '  Headers: ${options.headers}\n'
        '  Data: ${options.data}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[HTTP] <-- ${response.statusCode} ${response.requestOptions.uri}\n'
        '  Data: ${response.data.toString().substring(0, response.data.toString().length.clamp(0, 500))}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[HTTP] ERROR ${err.response?.statusCode} ${err.requestOptions.uri}\n'
        '  ${err.message}',
      );
    }
    handler.next(err);
  }
}
