import 'package:freezed_annotation/freezed_annotation.dart';

part 'consultation_models.freezed.dart';
part 'consultation_models.g.dart';

@freezed
class Consultation with _$Consultation {
  const factory Consultation({
    required String id,
    required String appointmentId,
    required String patientId,
    required String doctorId,
    required String chiefComplaints,
    @Default('') String clinicalFindings,
    @Default('') String diagnosis,
    @Default('') String notes,
    int? bpSystolic,
    int? bpDiastolic,
    int? pulse,
    double? temperature,
    double? weight,
    double? height,
    int? spo2,
    @Default(true) bool isDraft,
    required String createdAt,
    String? completedAt,
    required int lastModified,
    String? serverId,
    @Default('pending') String syncStatus,
    @Default(false) bool isDeleted,
    String? deletedAt,
  }) = _Consultation;

  factory Consultation.fromJson(Map<String, dynamic> json) =>
      _$ConsultationFromJson(json);
}

@freezed
class Vitals with _$Vitals {
  const factory Vitals({
    int? bpSystolic,
    int? bpDiastolic,
    int? pulse,
    double? temperature,
    double? weight,
    double? height,
    int? spo2,
  }) = _Vitals;

  factory Vitals.fromJson(Map<String, dynamic> json) => _$VitalsFromJson(json);
}

@freezed
class StartConsultationRequest with _$StartConsultationRequest {
  const factory StartConsultationRequest({
    required String appointmentId,
    required String patientId,
    required String doctorId,
    required String chiefComplaints,
  }) = _StartConsultationRequest;

  factory StartConsultationRequest.fromJson(Map<String, dynamic> json) =>
      _$StartConsultationRequestFromJson(json);
}

@freezed
class UpdateConsultationRequest with _$UpdateConsultationRequest {
  const factory UpdateConsultationRequest({
    required String localId,
    String? chiefComplaints,
    String? clinicalFindings,
    String? diagnosis,
    String? notes,
  }) = _UpdateConsultationRequest;

  factory UpdateConsultationRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateConsultationRequestFromJson(json);
}

@freezed
class UpdateVitalsRequest with _$UpdateVitalsRequest {
  const factory UpdateVitalsRequest({
    required String localId,
    int? bpSystolic,
    int? bpDiastolic,
    int? pulse,
    double? temperature,
    double? weight,
    double? height,
    int? spo2,
  }) = _UpdateVitalsRequest;

  factory UpdateVitalsRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateVitalsRequestFromJson(json);
}

@freezed
class CompleteConsultationRequest with _$CompleteConsultationRequest {
  const factory CompleteConsultationRequest({
    required String localId,
    required String diagnosis,
    @Default('') String clinicalFindings,
    @Default('') String notes,
    int? bpSystolic,
    int? bpDiastolic,
    int? pulse,
    double? temperature,
    double? weight,
    double? height,
    int? spo2,
  }) = _CompleteConsultationRequest;

  factory CompleteConsultationRequest.fromJson(Map<String, dynamic> json) =>
      _$CompleteConsultationRequestFromJson(json);
}
