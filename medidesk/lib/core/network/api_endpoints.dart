abstract final class ApiEndpoints {
  // ── Auth ──────────────────────────────────────────────────────────────
  static const String login           = '/auth/login/';
  static const String refreshToken    = '/auth/refresh/';
  static const String logout          = '/auth/logout/';
  static const String me              = '/auth/me/';
  static const String changePassword  = '/auth/change-password/';

  // ── Users ─────────────────────────────────────────────────────────────
  static const String users           = '/users/';
  static const String doctors         = '/users/doctors/';
  static String userDetail(String id) => '/users/$id/';

  // ── Chambers ──────────────────────────────────────────────────────────
  static const String chambers            = '/chambers/';
  static String chamberDetail(String id)  => '/chambers/$id/';

  // ── Patients ──────────────────────────────────────────────────────────
  static const String patients             = '/patients/';
  static const String patientSearch        = '/patients/search/';
  static const String patientNoteCreate    = '/patient-notes/';
  static String patientDetail(String id)   => '/patients/$id/';
  static String patientHistory(String id)  => '/patients/$id/history/';
  static String patientNotes(String id)    => '/patients/$id/notes/';

  // ── Appointments ──────────────────────────────────────────────────────
  static const String appointments          = '/appointments/';
  static const String appointmentQueue      = '/appointments/queue/';
  static const String appointmentStream     = '/appointments/queue/stream/';
  static const String walkIn                = '/appointments/walk-in/';
  static String appointmentDetail(String id)   => '/appointments/$id/';
  static String appointmentCheckIn(String id)  => '/appointments/$id/check-in/';
  static String appointmentStatus(String id)   => '/appointments/$id/status/';

  // ── Consultations ─────────────────────────────────────────────────────
  static const String consultations              = '/consultations/';
  static String consultationDetail(String id)    => '/consultations/$id/';
  static String consultationComplete(String id)  => '/consultations/$id/complete/';
  static String consultationVitals(String id)    => '/consultations/$id/vitals/';
  static String consultationTestOrders(String id)=> '/consultations/$id/test-orders/';

  // ── Prescriptions ─────────────────────────────────────────────────────
  static const String prescriptions                    = '/prescriptions/';
  static const String prescriptionItems                = '/prescription-items/';
  static const String pendingPrescriptions             = '/prescriptions/pending/';
  static String prescriptionDetail(String id)          => '/prescriptions/$id/';
  static String prescriptionApprove(String id)         => '/prescriptions/$id/approve/';
  static String prescriptionPdf(String id)             => '/prescriptions/$id/pdf/';
  static String prescriptionSend(String id)            => '/prescriptions/$id/send/';
  static String prescriptionByConsultation(String cId) => '/prescriptions/consultation/$cId/';

  // ── Billing ───────────────────────────────────────────────────────────
  static const String invoices            = '/invoices/';
  static const String invoiceItems        = '/invoice-items/';
  static const String payments            = '/payments/';
  static const String incomeReport        = '/income-report/';
  static String invoiceDetail(String id)  => '/invoices/$id/';
  static String invoicePdf(String id)     => '/invoices/$id/pdf/';

  // ── Test Orders ───────────────────────────────────────────────────────
  static const String testOrders            = '/test-orders/';
  static const String myTestOrders          = '/test-orders/mine/';
  static const String pendingTestOrders     = '/test-orders/pending/';
  static String testOrderDetail(String id)  => '/test-orders/$id/';

  // ── Reports ───────────────────────────────────────────────────────────
  static const String reports             = '/reports/';
  static String reportDetail(String id)   => '/reports/$id/';
  static String reportFile(String id)     => '/reports/$id/file/';

  // ── Medicines ─────────────────────────────────────────────────────────
  static const String medicineSearch   = '/medicines/search/';
  static const String generics         = '/medicines/generics/';
  static const String brands           = '/medicines/brands/';
  static const String manufacturers    = '/medicines/manufacturers/';
  static String genericDetail(String id)       => '/medicines/generics/$id/';
  static String brandDetail(String id)         => '/medicines/brands/$id/';
  static String manufacturerDetail(String id)  => '/medicines/manufacturers/$id/';

  // ── Doctors ───────────────────────────────────────────────────────────
  static const String specialities          = '/specialities/';
  static const String doctorProfiles        = '/doctors/profiles/';
  static String specialityDetail(String id)     => '/specialities/$id/';
  static String doctorProfileDetail(String id)  => '/doctors/profiles/$id/';

  // ── Dashboard & Audit ─────────────────────────────────────────────────
  static const String dashboard  = '/dashboard/';
  static const String auditLogs  = '/audit-logs/';
}