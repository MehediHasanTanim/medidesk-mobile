import 'package:freezed_annotation/freezed_annotation.dart';

part 'appointment_model.freezed.dart';
part 'appointment_model.g.dart';

@freezed
class Appointment with _$Appointment {
  const factory Appointment({
    required String id,
    required String patientId,
    required String doctorId,
    String? chamberId,
    required String scheduledAt,
    required String appointmentType,
    @Default('scheduled') String status,
    int? tokenNumber,
    @Default('') String notes,
    String? createdById,
    required String createdAt,
    required String updatedAt,
    required int lastModified,
    String? serverId,
    @Default('pending') String syncStatus,
    @Default(false) bool isDeleted,
    String? deletedAt,
  }) = _Appointment;

  factory Appointment.fromJson(Map<String, dynamic> json) =>
      _$AppointmentFromJson(json);
}

@freezed
class CreateAppointmentRequest with _$CreateAppointmentRequest {
  const factory CreateAppointmentRequest({
    required String patientId,
    required String doctorId,
    String? chamberId,
    required String scheduledAt,
    required String appointmentType,
    @Default('') String notes,
  }) = _CreateAppointmentRequest;

  factory CreateAppointmentRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateAppointmentRequestFromJson(json);
}

@freezed
class UpdateAppointmentRequest with _$UpdateAppointmentRequest {
  const factory UpdateAppointmentRequest({
    required String localId,
    String? chamberId,
    required String scheduledAt,
    required String appointmentType,
    @Default('') String notes,
  }) = _UpdateAppointmentRequest;

  factory UpdateAppointmentRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateAppointmentRequestFromJson(json);
}

@freezed
class WalkInRequest with _$WalkInRequest {
  const factory WalkInRequest({
    required String patientId,
    required String doctorId,
    String? chamberId,
    @Default('') String notes,
  }) = _WalkInRequest;

  factory WalkInRequest.fromJson(Map<String, dynamic> json) =>
      _$WalkInRequestFromJson(json);
}

/// A single entry in the live queue as returned by
/// `GET /appointments/queue/` and the SSE stream.
@freezed
class QueueItem with _$QueueItem {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory QueueItem({
    required String id,
    required String patientId,
    String? patientName,
    required String status,
    int? tokenNumber,
    required String scheduledAt,
    required String appointmentType,
    String? chamberId,
    @Default('') String notes,
  }) = _QueueItem;

  factory QueueItem.fromJson(Map<String, dynamic> json) =>
      _$QueueItemFromJson(json);
}

/// Response from `POST /appointments/{id}/check-in/`.
@freezed
class CheckInResponse with _$CheckInResponse {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory CheckInResponse({
    required int tokenNumber,
    required String status,
  }) = _CheckInResponse;

  factory CheckInResponse.fromJson(Map<String, dynamic> json) =>
      _$CheckInResponseFromJson(json);
}
