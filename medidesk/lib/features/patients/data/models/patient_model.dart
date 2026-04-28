import 'package:freezed_annotation/freezed_annotation.dart';

part 'patient_model.freezed.dart';
part 'patient_model.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// §6.4  Patient History — online-only response from GET /patients/{id}/history/
//
// Plain Dart classes (no @freezed) — these are never stored in Drift, only
// displayed from a live API response on the detail screen's "Visits" tab.
// ─────────────────────────────────────────────────────────────────────────────

/// Full clinical history returned by GET /patients/{serverId}/history/.
class PatientHistory {
  const PatientHistory({
    required this.patientId,
    required this.consultations,
    required this.appointments,
    required this.prescriptions,
    required this.testOrders,
  });

  final String patientId;
  final List<HistoryConsultationSummary> consultations;
  final List<HistoryAppointmentSummary> appointments;
  final List<HistoryPrescriptionSummary> prescriptions;
  final List<HistoryTestOrderSummary> testOrders;

  factory PatientHistory.fromJson(Map<String, dynamic> json) => PatientHistory(
        patientId: json['patient_id'] as String? ?? '',
        consultations: _parseList(
          json['consultations'],
          HistoryConsultationSummary.fromJson,
        ),
        appointments: _parseList(
          json['appointments'],
          HistoryAppointmentSummary.fromJson,
        ),
        prescriptions: _parseList(
          json['prescriptions'],
          HistoryPrescriptionSummary.fromJson,
        ),
        testOrders: _parseList(
          json['test_orders'],
          HistoryTestOrderSummary.fromJson,
        ),
      );

  static List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null) return const [];
    return (raw as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
  }
}

/// One consultation entry in the patient's history.
class HistoryConsultationSummary {
  const HistoryConsultationSummary({
    required this.id,
    required this.createdAt,
    required this.chiefComplaints,
    required this.diagnosis,
    required this.isDraft,
    required this.doctorName,
  });

  final String id;
  final String createdAt;
  final String chiefComplaints;
  final String diagnosis;
  final bool isDraft;
  final String doctorName;

  factory HistoryConsultationSummary.fromJson(Map<String, dynamic> json) =>
      HistoryConsultationSummary(
        id: json['id'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        chiefComplaints: json['chief_complaints'] as String? ?? '',
        diagnosis: json['diagnosis'] as String? ?? '',
        isDraft: json['is_draft'] as bool? ?? false,
        doctorName: json['doctor_name'] as String? ?? '',
      );
}

/// One appointment entry in the patient's history.
class HistoryAppointmentSummary {
  const HistoryAppointmentSummary({
    required this.id,
    required this.scheduledAt,
    required this.status,
    required this.appointmentType,
    this.tokenNumber,
  });

  final String id;
  final String scheduledAt;
  final String status;
  final String appointmentType;
  final int? tokenNumber;

  factory HistoryAppointmentSummary.fromJson(Map<String, dynamic> json) =>
      HistoryAppointmentSummary(
        id: json['id'] as String? ?? '',
        scheduledAt: json['scheduled_at'] as String? ?? '',
        status: json['status'] as String? ?? '',
        appointmentType: json['appointment_type'] as String? ?? '',
        tokenNumber: json['token_number'] as int?,
      );
}

/// One prescription entry in the patient's history.
class HistoryPrescriptionSummary {
  const HistoryPrescriptionSummary({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.itemCount,
    this.followUpDate,
  });

  final String id;
  final String createdAt;
  final String status;

  /// Number of drug items on the prescription.
  final int itemCount;
  final String? followUpDate;

  factory HistoryPrescriptionSummary.fromJson(Map<String, dynamic> json) =>
      HistoryPrescriptionSummary(
        id: json['id'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        status: json['status'] as String? ?? '',
        // Backend may include item_count directly or embed the items list.
        itemCount: json['item_count'] as int? ??
            (json['items'] as List?)?.length ??
            0,
        followUpDate: json['follow_up_date'] as String?,
      );
}

/// One test order entry in the patient's history.
class HistoryTestOrderSummary {
  const HistoryTestOrderSummary({
    required this.id,
    required this.testName,
    required this.orderedAt,
    required this.isCompleted,
    this.labName,
  });

  final String id;
  final String testName;
  final String orderedAt;
  final bool isCompleted;
  final String? labName;

  factory HistoryTestOrderSummary.fromJson(Map<String, dynamic> json) =>
      HistoryTestOrderSummary(
        id: json['id'] as String? ?? '',
        testName: json['test_name'] as String? ?? '',
        orderedAt: json['ordered_at'] as String? ?? '',
        isCompleted: json['is_completed'] as bool? ?? false,
        labName: json['lab_name'] as String?,
      );
}

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
