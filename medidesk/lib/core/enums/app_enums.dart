/// All application-wide enumerations.
///
/// String values match the API contract exactly.
/// Drift tables store enums as TEXT using the enum's [name] property.
// ignore_for_file: constant_identifier_names
library;

// ── User roles ────────────────────────────────────────────────────────────

enum UserRole {
  super_admin,
  admin,
  doctor,
  assistant_doctor,
  receptionist,
  assistant,
  trainee;

  bool get isDoctor => this == doctor || this == assistant_doctor;
  bool get isReceptionist => this == receptionist;
  bool get isAdmin => this == admin || this == super_admin;

  String get displayName => switch (this) {
        super_admin => 'Super Admin',
        admin => 'Admin',
        doctor => 'Doctor',
        assistant_doctor => 'Assistant Doctor',
        receptionist => 'Receptionist',
        assistant => 'Assistant',
        trainee => 'Trainee',
      };
}

// ── Patient ───────────────────────────────────────────────────────────────

enum Gender {
  M,
  F,
  O;

  String get displayName => switch (this) {
        M => 'Male',
        F => 'Female',
        O => 'Other',
      };
}

// ── Appointment ───────────────────────────────────────────────────────────

enum AppointmentType {
  new_visit,
  follow_up,
  walk_in;

  String get displayName => switch (this) {
        new_visit => 'New Visit',
        follow_up => 'Follow-up',
        walk_in => 'Walk-in',
      };

  /// API value — matches server's appointment_type field
  String get apiValue => switch (this) {
        new_visit => 'new',
        follow_up => 'follow_up',
        walk_in => 'walk_in',
      };
}

enum AppointmentStatus {
  scheduled,
  confirmed,
  in_queue,
  in_progress,
  completed,
  cancelled,
  no_show;

  String get displayName => switch (this) {
        scheduled => 'Scheduled',
        confirmed => 'Confirmed',
        in_queue => 'In Queue',
        in_progress => 'In Progress',
        completed => 'Completed',
        cancelled => 'Cancelled',
        no_show => 'No Show',
      };

  bool get isActive =>
      this == confirmed || this == in_queue || this == in_progress;

  /// Allowed next transition from the queue screen
  AppointmentStatus? get nextQueueStatus => switch (this) {
        confirmed => in_queue,
        in_queue => in_progress,
        in_progress => completed,
        _ => null,
      };
}

// ── Prescription ──────────────────────────────────────────────────────────

enum PrescriptionStatus {
  draft,
  active,
  approved;

  String get displayName => switch (this) {
        draft => 'Draft',
        active => 'Active',
        approved => 'Approved',
      };
}

// ── Medicine ──────────────────────────────────────────────────────────────

enum MedicineForm {
  tablet,
  capsule,
  syrup,
  injection,
  cream,
  drops,
  inhaler,
  powder_for_suspension,
  solution,
  gel,
  ointment,
  suppository,
  patch,
  spray,
  lotion,
  powder,
  granules,
  other;

  String get displayName => switch (this) {
        tablet => 'Tablet',
        capsule => 'Capsule',
        syrup => 'Syrup',
        injection => 'Injection',
        cream => 'Cream',
        drops => 'Drops',
        inhaler => 'Inhaler',
        powder_for_suspension => 'Powder for Suspension',
        solution => 'Solution',
        gel => 'Gel',
        ointment => 'Ointment',
        suppository => 'Suppository',
        patch => 'Patch',
        spray => 'Spray',
        lotion => 'Lotion',
        powder => 'Powder',
        granules => 'Granules',
        other => 'Other',
      };
}

enum MedicineRoute {
  oral,
  iv,
  topical;

  String get displayName => switch (this) {
        oral => 'Oral',
        iv => 'IV',
        topical => 'Topical',
      };
}

// ── Test Orders ───────────────────────────────────────────────────────────

enum TestApprovalStatus {
  pending,
  approved,
  rejected;

  String get displayName => switch (this) {
        pending => 'Pending',
        approved => 'Approved',
        rejected => 'Rejected',
      };
}

// ── Reports ───────────────────────────────────────────────────────────────

enum ReportCategory {
  blood_test,
  imaging,
  biopsy,
  other;

  String get displayName => switch (this) {
        blood_test => 'Blood Test',
        imaging => 'Imaging',
        biopsy => 'Biopsy',
        other => 'Other',
      };
}

// ── Billing ───────────────────────────────────────────────────────────────

enum InvoiceStatus {
  draft,
  issued,
  paid,
  partially_paid,
  cancelled;

  String get displayName => switch (this) {
        draft => 'Draft',
        issued => 'Issued',
        paid => 'Paid',
        partially_paid => 'Partially Paid',
        cancelled => 'Cancelled',
      };
}

enum PaymentMethod {
  cash,
  bkash,
  nagad,
  card;

  String get displayName => switch (this) {
        cash => 'Cash',
        bkash => 'bKash',
        nagad => 'Nagad',
        card => 'Card',
      };

  bool get requiresTransactionRef =>
      this == bkash || this == nagad || this == card;
}

// ── Sync ──────────────────────────────────────────────────────────────────

enum SyncStatus {
  pending,
  processing,
  synced,
  failed;

  String get displayName => switch (this) {
        pending    => 'Pending',
        processing => 'Syncing',
        synced     => 'Synced',
        failed     => 'Failed',
      };
}

// ── Helpers ───────────────────────────────────────────────────────────────

extension EnumByNameOrNull<T extends Enum> on Iterable<T> {
  T? byNameOrNull(String name) {
    for (final e in this) {
      if (e.name == name) return e;
    }
    return null;
  }
}
