import 'package:freezed_annotation/freezed_annotation.dart';

part 'prescription_models.freezed.dart';
part 'prescription_models.g.dart';

@freezed
class Prescription with _$Prescription {
  const factory Prescription({
    required String id,
    required String consultationId,
    required String patientId,
    required String prescribedById,
    String? approvedById,
    @Default('draft') String status,
    String? followUpDate,
    @Default('') String pdfPath,
    required String createdAt,
    required int lastModified,
    String? serverId,
    @Default('pending') String syncStatus,
    @Default(false) bool isDeleted,
    String? deletedAt,
  }) = _Prescription;

  factory Prescription.fromJson(Map<String, dynamic> json) =>
      _$PrescriptionFromJson(json);
}

@freezed
class PrescriptionItem with _$PrescriptionItem {
  const factory PrescriptionItem({
    required String id,
    required String prescriptionId,
    required String medicineId,
    required String medicineName,
    required String morning,
    required String afternoon,
    required String evening,
    required int durationDays,
    @Default('oral') String route,
    @Default('') String instructions,
    required int lastModified,
    String? serverId,
    @Default('pending') String syncStatus,
    @Default(false) bool isDeleted,
    String? deletedAt,
  }) = _PrescriptionItem;

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) =>
      _$PrescriptionItemFromJson(json);
}

/// Input DTO for a single drug item when creating or editing a prescription.
@freezed
class PrescriptionItemInput with _$PrescriptionItemInput {
  const factory PrescriptionItemInput({
    required String medicineId,
    required String medicineName,
    @Default('0') String morning,
    @Default('0') String afternoon,
    @Default('0') String evening,
    required int durationDays,
    @Default('oral') String route,
    @Default('') String instructions,
  }) = _PrescriptionItemInput;

  factory PrescriptionItemInput.fromJson(Map<String, dynamic> json) =>
      _$PrescriptionItemInputFromJson(json);
}

@freezed
class CreatePrescriptionRequest with _$CreatePrescriptionRequest {
  const factory CreatePrescriptionRequest({
    required String consultationId,
    required String patientId,
    required String prescribedById,
    @Default([]) List<PrescriptionItemInput> items,
    String? followUpDate,
  }) = _CreatePrescriptionRequest;

  factory CreatePrescriptionRequest.fromJson(Map<String, dynamic> json) =>
      _$CreatePrescriptionRequestFromJson(json);
}

@freezed
class UpdatePrescriptionRequest with _$UpdatePrescriptionRequest {
  const factory UpdatePrescriptionRequest({
    required String localId,
    required List<PrescriptionItemInput> items,
    String? followUpDate,
  }) = _UpdatePrescriptionRequest;

  factory UpdatePrescriptionRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdatePrescriptionRequestFromJson(json);
}
