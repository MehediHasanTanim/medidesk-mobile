import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

// app_database.dart parts in the generated file which contains
// PatientsCompanion, PatientNotesCompanion, SyncQueueCompanion, etc.
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';
import '../mappers/patient_mapper.dart';
import '../models/patient_model.dart';

// ── Interface ─────────────────────────────────────────────────────────────

abstract class IPatientRepository {
  Stream<List<Patient>> watchAll({String? searchQuery});
  Future<Patient?> getById(String localId);
  Future<void> createPatient(CreatePatientRequest req);
  Future<void> updatePatient(UpdatePatientRequest req);
  Future<void> deletePatient(String localId);
  Stream<List<PatientNote>> watchNotes(String patientLocalId);
  Future<void> addNote(String patientLocalId, String content, String? userId);
}

// ── Implementation ────────────────────────────────────────────────────────

class PatientRepository implements IPatientRepository {
  PatientRepository({
    required AppDatabase db,
    required SyncService syncService,
  })  : _db = db,
        _syncService = syncService;

  final AppDatabase _db;
  final SyncService _syncService;
  final _uuid = const Uuid();

  // ── Read ──────────────────────────────────────────────────────────────

  @override
  Stream<List<Patient>> watchAll({String? searchQuery}) =>
      _db.patientDao
          .watchAll(searchQuery: searchQuery)
          .map((rows) => rows.map(PatientMapper.fromRow).toList());

  @override
  Future<Patient?> getById(String localId) async {
    final row = await _db.patientDao.getById(localId);
    return row == null ? null : PatientMapper.fromRow(row);
  }

  @override
  Stream<List<PatientNote>> watchNotes(String patientLocalId) =>
      _db.patientDao
          .watchByPatient(patientLocalId)
          .map((rows) => rows.map(PatientMapper.noteFromRow).toList());

  // ── Mutations ─────────────────────────────────────────────────────────

  @override
  Future<void> createPatient(CreatePatientRequest req) async {
    final localId = _uuid.v4();
    final companion = PatientMapper.toCreateCompanion(localId, req);

    // 1. Write to Drift immediately (optimistic)
    await _db.patientDao.insertPatient(companion);

    // 2. Enqueue for sync
    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'patient',
      operation: 'CREATE',
      localId: localId,
      payloadJson: jsonEncode(_createRequestToJson(req)),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    // 3. Trigger push if online (non-blocking)
    unawaited(_syncService.pushSync());
  }

  @override
  Future<void> updatePatient(UpdatePatientRequest req) async {
    final companion = PatientMapper.toUpdateCompanion(req);
    await _db.patientDao.updatePatient(companion);

    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'patient',
      operation: 'UPDATE',
      localId: req.localId,
      payloadJson: jsonEncode(_updateRequestToJson(req)),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    unawaited(_syncService.pushSync());
  }

  @override
  Future<void> deletePatient(String localId) async {
    await _db.patientDao.softDelete(localId);

    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'patient',
      operation: 'DELETE',
      localId: localId,
      payloadJson: jsonEncode({'local_id': localId}),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    unawaited(_syncService.pushSync());
  }

  @override
  Future<void> addNote(
    String patientLocalId,
    String content,
    String? userId,
  ) async {
    final localId = _uuid.v4();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final nowIso = DateTime.now().toUtc().toIso8601String();

    await _db.patientDao.insertNote(
      PatientNotesCompanion.insert(
        id: localId,
        patientId: patientLocalId,
        content: content,
        createdById: Value(userId),
        createdAt: nowIso,
        lastModified: nowMs,
      ),
    );

    await _db.syncQueueDao.enqueue(SyncQueueCompanion.insert(
      id: _uuid.v4(),
      entityType: 'patient_note',
      operation: 'CREATE',
      localId: localId,
      payloadJson: jsonEncode({
        'patient_id': patientLocalId,
        'content': content,
        'local_id': localId,
      }),
      createdAt: nowMs,
    ));

    unawaited(_syncService.pushSync());
  }

  // ── JSON serialisation helpers ────────────────────────────────────────

  Map<String, dynamic> _createRequestToJson(CreatePatientRequest req) => {
        'full_name': req.fullName,
        'phone': req.phone,
        'gender': req.gender,
        'address': req.address,
        if (req.dateOfBirth != null) 'date_of_birth': req.dateOfBirth,
        if (req.email != null) 'email': req.email,
        if (req.nationalId != null) 'national_id': req.nationalId,
        if (req.ageYears != null) 'age_years': req.ageYears,
        'allergies': req.allergies,
        'chronic_diseases': req.chronicDiseases,
        'family_history': req.familyHistory,
      };

  Map<String, dynamic> _updateRequestToJson(UpdatePatientRequest req) => {
        'full_name': req.fullName,
        'phone': req.phone,
        'gender': req.gender,
        'address': req.address,
        if (req.dateOfBirth != null) 'date_of_birth': req.dateOfBirth,
        if (req.email != null) 'email': req.email,
        if (req.nationalId != null) 'national_id': req.nationalId,
        if (req.ageYears != null) 'age_years': req.ageYears,
        'allergies': req.allergies,
        'chronic_diseases': req.chronicDiseases,
        'family_history': req.familyHistory,
      };
}
