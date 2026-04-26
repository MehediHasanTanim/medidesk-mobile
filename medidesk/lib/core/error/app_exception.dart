sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkException extends AppException {
  const NetworkException(super.message);
}

final class ServerException extends AppException {
  const ServerException(super.message, {this.statusCode});
  final int? statusCode;
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException() : super('Session expired. Please log in again.');
}

final class ValidationException extends AppException {
  const ValidationException(super.message, {this.fieldErrors});
  final Map<String, List<String>>? fieldErrors;
}

final class SyncException extends AppException {
  const SyncException(
    super.message, {
    required this.entityType,
    required this.localId,
  });
  final String entityType;
  final String localId;
}

final class FileUploadException extends AppException {
  const FileUploadException(super.message, {required this.localPath});
  final String localPath;
}

final class CacheException extends AppException {
  const CacheException(super.message);
}

final class AuthException extends AppException {
  const AuthException(super.message);
}
