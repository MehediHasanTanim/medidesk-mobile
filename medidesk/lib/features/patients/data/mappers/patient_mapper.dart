import 'dart:convert';

import 'package:drift/drift.dart';

// app_database.dart parts in app_database.g.dart, which contains
// PatientsCompanion, PatientRow, PatientNoteRow, PatientNotesCompanion.
import '../../../../core/database/app_database.dart';
import '../models/patient_model.dart';

abstract final class PatientMapper {
  // ── Row → Domain model ────────────────────────────────────────────────

  static Patient fromRow(PatientRow row) => Patient(
        id: row.id,
        patientId: row.patientId,
        fullName: row.fullName,
        phone: row.phone,
        gender: row.gender,
        address: row.address,
        dateOfBirth: row.dateOfBirth,
        email: row.email,
        nationalId: row.nationalId,
        ageYears: row.ageYears,
        allergies: _parseJsonList(row.allergies),
        chronicDiseases: _parseJsonList(row.chronicDiseases),
        familyHistory: row.familyHistory,
        isActive: row.isActive == 1,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        lastModified: row.lastModified,
        serverId: row.serverId,
        syncStatus: row.syncStatus,
        isDeleted: row.isDeleted == 1,
        deletedAt: row.deletedAt,
      );

  static PatientNote noteFromRow(PatientNoteRow row) => PatientNote(
        id: row.id,
        patientId: row.patientId,
        content: row.content,
        createdById: row.createdById,
        createdAt: row.createdAt,
        lastModified: row.lastModified,
        serverId: row.serverId,
        syncStatus: row.syncStatus,
        isDeleted: row.isDeleted == 1,
        deletedAt: row.deletedAt,
      );

  // ── Domain request → Drift companion ─────────────────────────────────

  static PatientsCompanion toCreateCompanion(
    String localId,
    CreatePatientRequest req,
  ) {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return PatientsCompanion.insert(
      id: localId,
      fullName: req.fullName,
      phone: req.phone,
      gender: req.gender,
      address: req.address,
      dateOfBirth: Value(req.dateOfBirth),
      email: Value(req.email),
      nationalId: Value(req.nationalId),
      ageYears: Value(req.ageYears),
      allergies: Value(jsonEncode(req.allergies)),
      chronicDiseases: Value(jsonEncode(req.chronicDiseases)),
      familyHistory: Value(req.familyHistory),
      isActive: const Value(1),
      createdAt: nowIso,
      updatedAt: nowIso,
      lastModified: nowMs,
      syncStatus: const Value('pending'),
      isDeleted: const Value(0),
    );
  }

  static PatientsCompanion toUpdateCompanion(UpdatePatientRequest req) {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return PatientsCompanion(
      id: Value(req.localId),
      fullName: Value(req.fullName),
      phone: Value(req.phone),
      gender: Value(req.gender),
      address: Value(req.address),
      dateOfBirth: Value(req.dateOfBirth),
      email: Value(req.email),
      nationalId: Value(req.nationalId),
      ageYears: Value(req.ageYears),
      allergies: Value(jsonEncode(req.allergies)),
      chronicDiseases: Value(jsonEncode(req.chronicDiseases)),
      familyHistory: Value(req.familyHistory),
      updatedAt: Value(nowIso),
      lastModified: Value(nowMs),
      syncStatus: const Value('pending'),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  static List<String> _parseJsonList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return List<String>.from(decoded);
    } catch (_) {}
    return [];
  }
}
