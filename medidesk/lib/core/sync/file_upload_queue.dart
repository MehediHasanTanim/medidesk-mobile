import 'dart:io';
import 'package:dio/dio.dart';
import '../error/app_exception.dart';
import '../network/api_endpoints.dart';

/// Separate from SyncQueue — file uploads never block record sync.
class FileUploadQueue {
  FileUploadQueue({required Dio dio}) : _dio = dio;

  final Dio _dio;
  final List<_PendingUpload> _queue = [];
  bool _isProcessing = false;

  void enqueue({
    required String localPath,
    required String patientId,
    required String category,
    String? testOrderId,
    String? notes,
  }) {
    _queue.add(_PendingUpload(
      localPath: localPath,
      patientId: patientId,
      category: category,
      testOrderId: testOrderId,
      notes: notes,
    ));
    _processNext();
  }

  Future<void> _processNext() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    final upload = _queue.first;
    try {
      await _upload(upload);
      _queue.removeAt(0);
    } on FileUploadException {
      // Keep in queue for manual retry — don't auto-retry infinitely for files
      _queue.removeAt(0);
      _queue.add(upload.incrementRetry());
    } catch (_) {
      _queue.removeAt(0);
    } finally {
      _isProcessing = false;
      if (_queue.isNotEmpty) _processNext();
    }
  }

  Future<void> _upload(_PendingUpload upload) async {
    if (upload.retryCount >= 3) {
      throw FileUploadException(
        'Max retries exceeded',
        localPath: upload.localPath,
      );
    }

    final file = File(upload.localPath);
    if (!file.existsSync()) {
      throw FileUploadException(
        'File not found: ${upload.localPath}',
        localPath: upload.localPath,
      );
    }

    final formData = FormData.fromMap({
      'patient_id': upload.patientId,
      'category': upload.category,
      if (upload.testOrderId != null) 'test_order_id': upload.testOrderId,
      if (upload.notes != null) 'notes': upload.notes,
      'file': await MultipartFile.fromFile(
        upload.localPath,
        filename: file.uri.pathSegments.last,
      ),
    });

    await _dio.post<void>(
      ApiEndpoints.reportDocuments,
      data: formData,
    );
  }
}

class _PendingUpload {
  const _PendingUpload({
    required this.localPath,
    required this.patientId,
    required this.category,
    this.testOrderId,
    this.notes,
    this.retryCount = 0,
  });

  final String localPath;
  final String patientId;
  final String category;
  final String? testOrderId;
  final String? notes;
  final int retryCount;

  _PendingUpload incrementRetry() => _PendingUpload(
        localPath: localPath,
        patientId: patientId,
        category: category,
        testOrderId: testOrderId,
        notes: notes,
        retryCount: retryCount + 1,
      );
}
