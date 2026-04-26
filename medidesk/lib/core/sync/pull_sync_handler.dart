import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../network/api_endpoints.dart';
import '../storage/preferences_service.dart';
import 'conflict_resolver.dart';

class PullSyncHandler {
  const PullSyncHandler({
    required Dio dio,
    required AppDatabase db,
    required PreferencesService prefs,
  })  : _dio = dio,
        _db = db,
        _prefs = prefs;

  final Dio _dio;
  final AppDatabase _db;
  final PreferencesService _prefs;

  Future<void> pullSync() async {
    final lastMs = _prefs.getLastSyncTimestamp();
    final isoTs = lastMs != null
        ? DateTime.fromMillisecondsSinceEpoch(lastMs).toUtc().toIso8601String()
        : null;

    await Future.wait([
      _pullPatients(isoTs),
      _pullAppointments(isoTs),
      _pullConsultations(isoTs),
      _pullPrescriptions(isoTs),
      _pullTestOrders(isoTs),
      _pullInvoices(isoTs),
    ]);

    await _prefs.setLastSyncTimestamp(DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _pullPaginated(
    String path,
    String? updatedAfter,
    Future<void> Function(List<Map<String, dynamic>>) upsert,
  ) async {
    final params = <String, dynamic>{'limit': 500};
    if (updatedAfter != null) params['updated_after'] = updatedAfter;
    String? nextUrl = path;

    while (nextUrl != null) {
      final resp = await _dio.get<Map<String, dynamic>>(
        nextUrl,
        queryParameters: nextUrl == path ? params : null,
      );
      final data = resp.data!;
      final results = (data['results'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      if (results.isNotEmpty) await upsert(results);
      nextUrl = data['next'] as String?;
    }
  }

  Future<void> _pullPatients(String? after) async {
    await _pullPaginated(ApiEndpoints.patients, after, (rows) async {
      final companions = rows.map((m) {
        return PatientsCompanion.insert(
          id: m['local_id'] as String? ?? m['id'] as String,
          patientId: Value(m['patient_id'] as String?),
          fullName: m['full_name'] as String,
          phone: m['phone'] as String,
          gender: m['gender'] as String,
          address: m['address'] as String,
          dateOfBirth: Value(m['date_of_birth'] as String?),
          email: Value(m['email'] as String?),
          nationalId: Value(m['national_id'] as String?),
          ageYears: Value(m['age_years'] as int?),
          allergies: Value(jsonEncode(m['allergies'] ?? [])),
          chronicDiseases: Value(jsonEncode(m['chronic_diseases'] ?? [])),
          familyHistory: Value(m['family_history'] as String? ?? ''),
          isActive: Value(((m['is_active'] as bool?) ?? true) ? 1 : 0),
          createdAt: m['created_at'] as String,
          updatedAt: m['updated_at'] as String,
          lastModified: m['last_modified'] as int,
          serverId: Value(m['id'] as String),
          syncStatus: const Value('synced'),
          isDeleted: Value(((m['is_deleted'] as bool?) ?? false) ? 1 : 0),
          deletedAt: Value(m['deleted_at'] as String?),
        );
      }).toList();

      // Apply conflict resolution: only upsert if server is newer
      for (final companion in companions) {
        final localId = companion.serverId.value;
        if (localId == null) continue;
        final existing = await _db.patientDao.getByServerId(localId);
        if (existing == null ||
            serverWins(existing.lastModified, companion.lastModified.value)) {
          await _db.patientDao.upsertAll([companion]);
        }
      }
    });
  }

  Future<void> _pullAppointments(String? after) async {
    await _pullPaginated(ApiEndpoints.appointments, after, (rows) async {
      final companions = rows.map((m) => AppointmentsCompanion.insert(
            id: m['local_id'] as String? ?? m['id'] as String,
            patientId: m['patient_id'] as String,
            doctorId: m['doctor_id'] as String,
            chamberId: Value(m['chamber_id'] as String?),
            scheduledAt: m['scheduled_at'] as String,
            appointmentType: m['appointment_type'] as String,
            status: Value(m['status'] as String),
            tokenNumber: Value(m['token_number'] as int?),
            notes: Value(m['notes'] as String? ?? ''),
            createdById: Value(m['created_by_id'] as String?),
            createdAt: m['created_at'] as String,
            updatedAt: m['updated_at'] as String,
            lastModified: m['last_modified'] as int,
            serverId: Value(m['id'] as String),
            syncStatus: const Value('synced'),
            isDeleted: Value(((m['is_deleted'] as bool?) ?? false) ? 1 : 0),
            deletedAt: Value(m['deleted_at'] as String?),
          )).toList();
      await _db.appointmentDao.upsertAll(companions);
    });
  }

  Future<void> _pullConsultations(String? after) async {
    await _pullPaginated(ApiEndpoints.consultations, after, (rows) async {
      final companions = rows.map((m) => ConsultationsCompanion.insert(
            id: m['local_id'] as String? ?? m['id'] as String,
            appointmentId: m['appointment_id'] as String,
            patientId: m['patient_id'] as String,
            doctorId: m['doctor_id'] as String,
            chiefComplaints: m['chief_complaints'] as String,
            clinicalFindings: Value(m['clinical_findings'] as String? ?? ''),
            diagnosis: Value(m['diagnosis'] as String? ?? ''),
            notes: Value(m['notes'] as String? ?? ''),
            bpSystolic: Value(m['bp_systolic'] as int?),
            bpDiastolic: Value(m['bp_diastolic'] as int?),
            pulse: Value(m['pulse'] as int?),
            temperature: Value(m['temperature'] as double?),
            weight: Value(m['weight'] as double?),
            height: Value(m['height'] as double?),
            spo2: Value(m['spo2'] as int?),
            isDraft: Value(((m['is_draft'] as bool?) ?? true) ? 1 : 0),
            createdAt: m['created_at'] as String,
            completedAt: Value(m['completed_at'] as String?),
            lastModified: m['last_modified'] as int,
            serverId: Value(m['id'] as String),
            syncStatus: const Value('synced'),
            isDeleted: Value(((m['is_deleted'] as bool?) ?? false) ? 1 : 0),
            deletedAt: Value(m['deleted_at'] as String?),
          )).toList();
      await _db.consultationDao.upsertAll(companions);
    });
  }

  Future<void> _pullPrescriptions(String? after) async {
    await _pullPaginated(ApiEndpoints.prescriptions, after, (rows) async {
      final companions = rows.map((m) => PrescriptionsCompanion.insert(
            id: m['local_id'] as String? ?? m['id'] as String,
            consultationId: m['consultation_id'] as String,
            patientId: m['patient_id'] as String,
            prescribedById: m['prescribed_by_id'] as String,
            approvedById: Value(m['approved_by_id'] as String?),
            status: Value(m['status'] as String? ?? 'draft'),
            followUpDate: Value(m['follow_up_date'] as String?),
            pdfPath: Value(m['pdf_path'] as String? ?? ''),
            createdAt: m['created_at'] as String,
            lastModified: m['last_modified'] as int,
            serverId: Value(m['id'] as String),
            syncStatus: const Value('synced'),
            isDeleted: Value(((m['is_deleted'] as bool?) ?? false) ? 1 : 0),
            deletedAt: Value(m['deleted_at'] as String?),
          )).toList();
      await _db.prescriptionDao.upsertAllPrescriptions(companions);
    });
  }

  Future<void> _pullTestOrders(String? after) async {
    await _pullPaginated(ApiEndpoints.testOrders, after, (rows) async {
      final companions = rows.map((m) => TestOrdersCompanion.insert(
            id: m['local_id'] as String? ?? m['id'] as String,
            consultationId: m['consultation_id'] as String,
            patientId: m['patient_id'] as String,
            testName: m['test_name'] as String,
            labName: Value(m['lab_name'] as String? ?? ''),
            notes: Value(m['notes'] as String? ?? ''),
            orderedById: Value(m['ordered_by_id'] as String?),
            orderedAt: m['ordered_at'] as String,
            isCompleted: Value(((m['is_completed'] as bool?) ?? false) ? 1 : 0),
            completedAt: Value(m['completed_at'] as String?),
            approvalStatus: Value(m['approval_status'] as String? ?? 'approved'),
            lastModified: m['last_modified'] as int,
            serverId: Value(m['id'] as String),
            syncStatus: const Value('synced'),
            isDeleted: Value(((m['is_deleted'] as bool?) ?? false) ? 1 : 0),
            deletedAt: Value(m['deleted_at'] as String?),
          )).toList();
      await _db.testOrderDao.upsertAll(companions);
    });
  }

  Future<void> _pullInvoices(String? after) async {
    await _pullPaginated(ApiEndpoints.invoices, after, (rows) async {
      final companions = rows.map((m) => InvoicesCompanion.insert(
            id: m['local_id'] as String? ?? m['id'] as String,
            invoiceNumber: Value(m['invoice_number'] as String?),
            patientId: m['patient_id'] as String,
            consultationId: Value(m['consultation_id'] as String?),
            discountPercent: Value((m['discount_percent'] as num?)?.toDouble() ?? 0.0),
            status: Value(m['status'] as String? ?? 'draft'),
            createdById: Value(m['created_by_id'] as String?),
            createdAt: m['created_at'] as String,
            lastModified: m['last_modified'] as int,
            serverId: Value(m['id'] as String),
            syncStatus: const Value('synced'),
            isDeleted: Value(((m['is_deleted'] as bool?) ?? false) ? 1 : 0),
            deletedAt: Value(m['deleted_at'] as String?),
          )).toList();
      await _db.invoiceDao.upsertAllInvoices(companions);
    });
  }
}
