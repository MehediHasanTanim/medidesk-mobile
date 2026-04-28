import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/providers/infrastructure_providers.dart';
import '../../../../shared/providers/sync_status_provider.dart';
import '../../data/models/appointment_model.dart';
import '../../data/repositories/appointment_repository.dart';

part 'appointment_providers.g.dart';

// ── Repository ────────────────────────────────────────────────────────────

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(
    db: ref.watch(appDatabaseProvider),
    syncService: ref.watch(syncServiceProvider),
  );
});

// ── Date selection state ──────────────────────────────────────────────────

final selectedDateProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

// ── Read providers ────────────────────────────────────────────────────────

@riverpod
Stream<List<Appointment>> appointmentsByDate(
  AppointmentsByDateRef ref,
  DateTime date,
) {
  return ref.watch(appointmentRepositoryProvider).watchByDate(date);
}

@riverpod
Stream<List<Appointment>> appointmentsByPatient(
  AppointmentsByPatientRef ref,
  String patientLocalId,
) {
  return ref.watch(appointmentRepositoryProvider).watchByPatient(patientLocalId);
}

@riverpod
Stream<List<Appointment>> appointmentQueue(
  AppointmentQueueRef ref,
  DateTime date,
) {
  return ref.watch(appointmentRepositoryProvider).watchTodayQueue(date);
}

@riverpod
Future<Appointment?> appointmentDetail(
  AppointmentDetailRef ref,
  String localId,
) {
  return ref.watch(appointmentRepositoryProvider).getById(localId);
}

// ── Mutation providers ────────────────────────────────────────────────────

@riverpod
class CreateAppointmentNotifier extends _$CreateAppointmentNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(CreateAppointmentRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(appointmentRepositoryProvider).createAppointment(req),
    );
  }
}

@riverpod
class CreateWalkInNotifier extends _$CreateWalkInNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(WalkInRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(appointmentRepositoryProvider).createWalkIn(req),
    );
  }
}

@riverpod
class UpdateAppointmentNotifier extends _$UpdateAppointmentNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(UpdateAppointmentRequest req) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(appointmentRepositoryProvider).updateAppointment(req),
    );
  }
}

@riverpod
class DeleteAppointmentNotifier extends _$DeleteAppointmentNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(String localId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(appointmentRepositoryProvider).deleteAppointment(localId),
    );
  }
}

@riverpod
class UpdateAppointmentStatusNotifier
    extends _$UpdateAppointmentStatusNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> execute(String localId, String status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(appointmentRepositoryProvider).updateStatus(localId, status),
    );
  }
}

// ── Online queue providers ────────────────────────────────────────────────

/// One-shot REST fetch of the live queue for [date].
/// Used as the initial snapshot before the SSE stream connects.
@riverpod
Future<List<QueueItem>> queueFetch(
  QueueFetchRef ref,
  DateTime date,
) async {
  final dio = ref.watch(dioProvider);
  final dateStr = DateFormat('yyyy-MM-dd').format(date);
  final resp = await dio.get<Map<String, dynamic>>(
    ApiEndpoints.appointmentQueue,
    queryParameters: {'date': dateStr},
  );
  final raw = resp.data!;
  final list = (raw['results'] as List<dynamic>? ??
          (raw.values.firstWhere(
            (v) => v is List,
            orElse: () => <dynamic>[],
          ) as List<dynamic>))
      .cast<Map<String, dynamic>>();
  return list.map(QueueItem.fromJson).toList();
}

/// SSE-backed live queue stream.
///
/// Emits the REST snapshot first (so the UI is populated immediately),
/// then upgrades to the server-sent-events stream for real-time updates.
/// Any SSE error is swallowed so the stream simply stops; the last emitted
/// value stays on screen.
@riverpod
Stream<List<QueueItem>> queueStream(QueueStreamRef ref) async* {
  final dio = ref.watch(dioProvider);
  final today = DateTime.now();
  final dateStr = DateFormat('yyyy-MM-dd').format(today);

  // ── 1. REST snapshot ──────────────────────────────────────────────────
  try {
    final resp = await dio.get<Map<String, dynamic>>(
      ApiEndpoints.appointmentQueue,
      queryParameters: {'date': dateStr},
    );
    final raw = resp.data!;
    final list = (raw['results'] as List<dynamic>? ??
            (raw.values.firstWhere(
              (v) => v is List,
              orElse: () => <dynamic>[],
            ) as List<dynamic>))
        .cast<Map<String, dynamic>>();
    yield list.map(QueueItem.fromJson).toList();
  } catch (_) {
    yield [];
  }

  // ── 2. SSE stream ─────────────────────────────────────────────────────
  try {
    final response = await dio.get<ResponseBody>(
      ApiEndpoints.appointmentStream,
      options: Options(responseType: ResponseType.stream),
    );
    await for (final line in response.data!.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where((l) => l.startsWith('data:'))) {
      final payload =
          jsonDecode(line.substring(5)) as Map<String, dynamic>;
      final items = (payload['results'] as List<dynamic>? ??
              payload['items'] as List<dynamic>? ??
              <dynamic>[])
          .cast<Map<String, dynamic>>();
      yield items.map(QueueItem.fromJson).toList();
    }
  } catch (_) {
    // SSE failed — hold the last REST snapshot already emitted.
  }
}
