import 'package:freezed_annotation/freezed_annotation.dart';

part 'patient_model.freezed.dart';
part 'patient_model.g.dart';

@freezed
class Patient with _$Patient {
  const factory Patient({
    required String id,
    String? patientId,
    required String fullName,
    required String phone,
    required String gender,
    required String address,
    String? dateOfBirth,
    String? email,
    String? nationalId,
    int? ageYears,
    @Default([]) List<String> allergies,
    @Default([]) List<String> chronicDiseases,
    @Default('') String familyHistory,
    @Default(true) bool isActive,
    required String createdAt,
    required String updatedAt,
    required int lastModified,
    String? serverId,
    @Default('pending') String syncStatus,
    @Default(false) bool isDeleted,
    String? deletedAt,
  }) = _Patient;

  factory Patient.fromJson(Map<String, dynamic> json) =>
      _$PatientFromJson(json);
}

@freezed
class PatientNote with _$PatientNote {
  const factory PatientNote({
    required String id,
    required String patientId,
    required String content,
    String? createdById,
    required String createdAt,
    required int lastModified,
    String? serverId,
    @Default('pending') String syncStatus,
    @Default(false) bool isDeleted,
    String? deletedAt,
  }) = _PatientNote;

  factory PatientNote.fromJson(Map<String, dynamic> json) =>
      _$PatientNoteFromJson(json);
}

@freezed
class CreatePatientRequest with _$CreatePatientRequest {
  const factory CreatePatientRequest({
    required String fullName,
    required String phone,
    required String gender,
    required String address,
    String? dateOfBirth,
    String? email,
    String? nationalId,
    int? ageYears,
    @Default([]) List<String> allergies,
    @Default([]) List<String> chronicDiseases,
    @Default('') String familyHistory,
  }) = _CreatePatientRequest;

  factory CreatePatientRequest.fromJson(Map<String, dynamic> json) =>
      _$CreatePatientRequestFromJson(json);
}

@freezed
class UpdatePatientRequest with _$UpdatePatientRequest {
  const factory UpdatePatientRequest({
    required String localId,
    required String fullName,
    required String phone,
    required String gender,
    required String address,
    String? dateOfBirth,
    String? email,
    String? nationalId,
    int? ageYears,
    @Default([]) List<String> allergies,
    @Default([]) List<String> chronicDiseases,
    @Default('') String familyHistory,
  }) = _UpdatePatientRequest;

  factory UpdatePatientRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdatePatientRequestFromJson(json);
}
