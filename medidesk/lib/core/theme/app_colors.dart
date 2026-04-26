import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary — fresh green
  static const primary = Color(0xFF1AA37A);
  static const primaryLight = Color(0xFFE9F7F0);
  static const primaryDark = Color(0xFF138163);
  static const primarySoft = Color(0xFFDCF5EC);

  // Secondary — teal-blue
  static const secondary = Color(0xFF3D7C8A);

  // Semantic
  static const error = Color(0xFFDC4A4A);
  static const warning = Color(0xFFE9A23B);
  static const success = Color(0xFF1AA37A);
  static const info = Color(0xFF3D7C8A);

  // Soft semantic backgrounds
  static const warningSoft = Color(0xFFFDF1D8);
  static const dangerSoft = Color(0xFFFDE2E2);

  // Sync status
  static const syncPending = Color(0xFFE9A23B);
  static const syncSynced = Color(0xFF1AA37A);
  static const syncFailed = Color(0xFFDC4A4A);

  // Appointment status chips
  static const statusScheduled = Color(0xFF3D7C8A);
  static const statusConfirmed = Color(0xFF1AA37A);
  static const statusInQueue = Color(0xFFE9A23B);
  static const statusInProgress = Color(0xFF7B5EA7);
  static const statusCompleted = Color(0xFF1AA37A);
  static const statusCancelled = Color(0xFF6F8077);
  static const statusNoShow = Color(0xFFDC4A4A);

  // Invoice status
  static const invoiceDraft = Color(0xFF6F8077);
  static const invoiceIssued = Color(0xFF3D7C8A);
  static const invoicePaid = Color(0xFF1AA37A);
  static const invoicePartiallyPaid = Color(0xFFE9A23B);
  static const invoiceCancelled = Color(0xFFDC4A4A);

  // Test approval
  static const approvalPending = Color(0xFFE9A23B);
  static const approvalApproved = Color(0xFF1AA37A);
  static const approvalRejected = Color(0xFFDC4A4A);

  // Surfaces & ink
  static const background = Color(0xFFEEF5EF);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF7FAF6);
  static const cardBackground = Color(0xFFFFFFFF);
  static const ink = Color(0xFF0E1F17);
  static const ink2 = Color(0xFF3A4A42);
  static const muted = Color(0xFF6F8077);
  static const line = Color(0xFFE2ECE4);
  static const line2 = Color(0xFFCFDDD2);

  // Offline banner
  static const offlineBanner = Color(0xFF0E3A2C);

  // Dark card gradient
  static const darkCardStart = Color(0xFF0E3A2C);
  static const darkCardEnd = Color(0xFF1A6E54);
}
