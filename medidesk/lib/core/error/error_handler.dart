import 'package:dio/dio.dart';
import 'app_exception.dart';

AppException mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkException('No internet connection or server unreachable.');
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      if (status == 401) return const UnauthorizedException();
      final data = e.response?.data;
      String message = 'Server error (HTTP $status)';
      if (data is Map) {
        final detail = data['detail'] ?? data['message'] ?? data['error'];
        if (detail != null) message = detail.toString();
      }
      if (status == 422 || status == 400) {
        Map<String, List<String>>? fieldErrors;
        if (data is Map) {
          fieldErrors = {
            for (final entry in data.entries)
              if (entry.value is List)
                entry.key: List<String>.from(entry.value as List)
          };
        }
        return ValidationException(message, fieldErrors: fieldErrors);
      }
      return ServerException(message, statusCode: status);
    case DioExceptionType.cancel:
      return const NetworkException('Request cancelled.');
    default:
      return NetworkException(e.message ?? 'Unknown network error.');
  }
}
