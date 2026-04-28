import 'package:freezed_annotation/freezed_annotation.dart';

part 'test_order_models.freezed.dart';
part 'test_order_models.g.dart';

@freezed
class TestOrder with _$TestOrder {
  const factory TestOrder({
    required String id,
    required String consultationId,
    required String patientId,
    required String testName,
    @Default('') String labName,
    @Default('') String notes,
    String? orderedById,
    required String orderedAt,
    @Default(false) bool isCompleted,
    String? completedAt,
    @Default('approved') String approvalStatus,
    required int lastModified,
    String? serverId,
    @Default('pending') String syncStatus,
    @Default(false) bool isDeleted,
    String? deletedAt,
  }) = _TestOrder;

  factory TestOrder.fromJson(Map<String, dynamic> json) =>
      _$TestOrderFromJson(json);
}

/// Input for a single test order line item within a bulk create request.
@freezed
class TestOrderInput with _$TestOrderInput {
  const factory TestOrderInput({
    required String localId,
    required String testName,
    @Default('') String labName,
    @Default('') String notes,
  }) = _TestOrderInput;

  factory TestOrderInput.fromJson(Map<String, dynamic> json) =>
      _$TestOrderInputFromJson(json);
}

/// §10.3 — Bulk create: POST /consultations/{cId}/test-orders/.
/// All orders for a consultation are sent in one payload.
@freezed
class BulkCreateTestOrderRequest with _$BulkCreateTestOrderRequest {
  const factory BulkCreateTestOrderRequest({
    /// Local ID of the parent consultation (used to resolve serverId before push).
    required String consultationLocalId,
    required String patientId,
    required List<TestOrderInput> orders,
  }) = _BulkCreateTestOrderRequest;

  factory BulkCreateTestOrderRequest.fromJson(Map<String, dynamic> json) =>
      _$BulkCreateTestOrderRequestFromJson(json);
}

/// Update a single test order: PATCH /test-orders/{id}/.
@freezed
class UpdateTestOrderRequest with _$UpdateTestOrderRequest {
  const factory UpdateTestOrderRequest({
    required String localId,
    String? testName,
    String? labName,
    String? notes,
    bool? isCompleted,
    String? completedAt,
  }) = _UpdateTestOrderRequest;

  factory UpdateTestOrderRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTestOrderRequestFromJson(json);
}

/// Online-only response shape from GET /test-orders/mine/ and
/// GET /test-orders/pending/.
class TestOrderSummary {
  const TestOrderSummary({
    required this.id,
    required this.testName,
    required this.patientName,
    required this.orderedAt,
    required this.isCompleted,
    this.labName,
    this.consultationId,
  });

  final String id;
  final String testName;
  final String patientName;
  final String orderedAt;
  final bool isCompleted;
  final String? labName;
  final String? consultationId;

  factory TestOrderSummary.fromJson(Map<String, dynamic> json) =>
      TestOrderSummary(
        id: json['id'] as String,
        testName: json['test_name'] as String,
        patientName: json['patient_name'] as String? ?? '',
        orderedAt: json['ordered_at'] as String,
        isCompleted: json['is_completed'] as bool? ?? false,
        labName: json['lab_name'] as String?,
        consultationId: json['consultation_id'] as String?,
      );
}
