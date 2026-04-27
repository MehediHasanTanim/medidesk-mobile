import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/lookup_tables.dart';
import 'tables/patient_tables.dart';
import 'tables/appointment_tables.dart';
import 'tables/consultation_tables.dart';
import 'tables/prescription_tables.dart';
import 'tables/test_order_tables.dart';
import 'tables/billing_tables.dart';
import 'tables/sync_queue_table.dart';

import 'daos/chamber_dao.dart';
import 'daos/user_dao.dart';
import 'daos/speciality_dao.dart';
import 'daos/doctor_profile_dao.dart';
import 'daos/patient_dao.dart';
import 'daos/appointment_dao.dart';
import 'daos/consultation_dao.dart';
import 'daos/prescription_dao.dart';
import 'daos/medicine_dao.dart';
import 'daos/test_order_dao.dart';
import 'daos/invoice_dao.dart';
import 'daos/sync_queue_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    // Lookup
    Chambers,
    Users,
    Specialities,
    DoctorProfiles,
    GenericMedicines,
    BrandMedicines,
    // Mutable
    Patients,
    PatientNotes,
    Appointments,
    Consultations,
    Prescriptions,
    PrescriptionItems,
    TestOrders,
    Invoices,
    InvoiceItems,
    Payments,
    // Sync
    SyncQueue,
  ],
  daos: [
    ChamberDao,
    UserDao,
    SpecialityDao,
    DoctorProfileDao,
    PatientDao,
    AppointmentDao,
    ConsultationDao,
    PrescriptionDao,
    MedicineDao,
    TestOrderDao,
    InvoiceDao,
    SyncQueueDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Future migrations go here
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');

          // Performance indexes for mutable tables
          if (details.wasCreated) {
            await _createIndexes();
          }
        },
      );

  Future<void> _createIndexes() async {
    // Patients
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_patients_full_name ON patients(full_name)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_patients_phone ON patients(phone)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_patients_patient_id ON patients(patient_id)');

    // Patient notes
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_patient_notes_patient ON patient_notes(patient_id, created_at)');

    // Appointments
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_appointments_date_status ON appointments(scheduled_at, status)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_appointments_patient ON appointments(patient_id, scheduled_at)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_appointments_doctor ON appointments(doctor_id, scheduled_at)');

    // Consultations
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_consultations_patient ON consultations(patient_id, created_at)');

    // Prescriptions
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_prescriptions_patient ON prescriptions(patient_id)');

    // Prescription items
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_prescription_items_prescription ON prescription_items(prescription_id)');

    // Test orders
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_test_orders_patient ON test_orders(patient_id)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_test_orders_ordered_at ON test_orders(ordered_at)');

    // Invoices
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_invoices_date_status ON invoices(created_at, status)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_invoices_patient ON invoices(patient_id)');

    // Sync queue
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue(status, next_retry_at, created_at)');

    // Sync-status sweep indexes (for SyncQueueProcessor pending-check)
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_patients_sync ON patients(sync_status) WHERE is_deleted = 0');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_appointments_sync ON appointments(sync_status) WHERE is_deleted = 0');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_consultations_sync ON consultations(sync_status) WHERE is_deleted = 0');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_prescriptions_sync ON prescriptions(sync_status) WHERE is_deleted = 0');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_test_orders_sync ON test_orders(sync_status) WHERE is_deleted = 0');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_invoices_sync ON invoices(sync_status) WHERE is_deleted = 0');

    // Compound indexes for FK-heavy queries
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_appt_chamber_date ON appointments(chamber_id, scheduled_at, status)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice ON invoice_items(invoice_id)');
    await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_payments_invoice ON payments(invoice_id)');
  }

  /// Wipe all data — called on logout.
  Future<void> wipeAll() async {
    await transaction(() async {
      await delete(payments).go();
      await delete(invoiceItems).go();
      await delete(invoices).go();
      await delete(testOrders).go();
      await delete(prescriptionItems).go();
      await delete(prescriptions).go();
      await delete(consultations).go();
      await delete(appointments).go();
      await delete(patientNotes).go();
      await delete(patients).go();
      await delete(syncQueue).go();
      await delete(brandMedicines).go();
      await delete(genericMedicines).go();
      await delete(doctorProfiles).go();
      await delete(specialities).go();
      await delete(users).go();
      await delete(chambers).go();
    });
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'medidesk_db');
}
