import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../patients/data/models/patient_model.dart';
import '../../../patients/presentation/providers/patient_providers.dart';
import '../../data/models/appointment_model.dart';
import '../providers/appointment_providers.dart';

class AppointmentFormScreen extends ConsumerStatefulWidget {
  const AppointmentFormScreen({super.key, this.patientId, this.localId});

  final String? patientId;
  final String? localId;

  bool get isEditing => localId != null;

  @override
  ConsumerState<AppointmentFormScreen> createState() =>
      _AppointmentFormScreenState();
}

class _AppointmentFormScreenState
    extends ConsumerState<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();

  Patient? _selectedPatient;
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  String _appointmentType = 'new';
  bool _loaded = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    // Pre-fill patient if patientId was passed
    if (widget.patientId != null && _selectedPatient == null) {
      final p = await ref.read(patientDetailProvider(widget.patientId!).future);
      if (p != null && mounted) setState(() => _selectedPatient = p);
    }

    // Load existing appointment for edit
    if (widget.isEditing && !_loaded) {
      final appt =
          await ref.read(appointmentDetailProvider(widget.localId!).future);
      if (appt == null || !mounted) return;
      _notesCtrl.text = appt.notes;
      setState(() {
        _scheduledAt =
            DateTime.tryParse(appt.scheduledAt)?.toLocal() ?? _scheduledAt;
        _appointmentType = appt.appointmentType;
        _loaded = true;
      });
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickPatient() async {
    final patient = await showModalBottomSheet<Patient>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _PatientPickerSheet(),
    );
    if (patient != null) setState(() => _selectedPatient = patient);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatient == null) {
      context.showSnackBar('Please select a patient', isError: true);
      return;
    }

    final scheduledIso = _scheduledAt.toUtc().toIso8601String();

    if (widget.isEditing) {
      await ref.read(updateAppointmentNotifierProvider.notifier).execute(
            UpdateAppointmentRequest(
              localId: widget.localId!,
              scheduledAt: scheduledIso,
              appointmentType: _appointmentType,
              notes: _notesCtrl.text.trim(),
            ),
          );
      final state = ref.read(updateAppointmentNotifierProvider);
      if (!mounted) return;
      state.whenOrNull(
        error: (e, _) => context.showSnackBar(e.toString(), isError: true),
        data: (_) {
          context.showSnackBar('Appointment updated');
          context.pop();
        },
      );
    } else {
      // Use the currently-logged-in doctor's ID from auth.
      // For now, use a placeholder; the repo's sync payload will be patched
      // by the server using the authenticated user's doctor profile.
      const doctorId = 'current-doctor';

      await ref.read(createAppointmentNotifierProvider.notifier).execute(
            CreateAppointmentRequest(
              patientId: _selectedPatient!.id,
              doctorId: doctorId,
              scheduledAt: scheduledIso,
              appointmentType: _appointmentType,
              notes: _notesCtrl.text.trim(),
            ),
          );
      final state = ref.read(createAppointmentNotifierProvider);
      if (!mounted) return;
      state.whenOrNull(
        error: (e, _) => context.showSnackBar(e.toString(), isError: true),
        data: (_) {
          context.showSnackBar('Appointment booked');
          context.pop();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(createAppointmentNotifierProvider).isLoading ||
            ref.watch(updateAppointmentNotifierProvider).isLoading;

    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(
          title:
              Text(widget.isEditing ? 'Edit Appointment' : 'New Appointment'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Patient selector
              InkWell(
                onTap: widget.isEditing ? null : _pickPatient,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Patient *',
                    suffixIcon: Icon(Icons.person_search, size: 18),
                  ),
                  child: Text(
                    _selectedPatient?.fullName ?? 'Select patient',
                    style: TextStyle(
                      color: _selectedPatient == null
                          ? Colors.black38
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Date/time picker
              InkWell(
                onTap: _pickDateTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date & Time *',
                    suffixIcon: Icon(Icons.access_time, size: 18),
                  ),
                  child: Text(
                    DateFormat('EEE, MMM d · h:mm a').format(_scheduledAt),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Appointment type
              DropdownButtonFormField<String>(
                value: _appointmentType,
                decoration:
                    const InputDecoration(labelText: 'Type *'),
                items: const [
                  DropdownMenuItem(value: 'new', child: Text('New Patient')),
                  DropdownMenuItem(
                      value: 'follow_up', child: Text('Follow-up')),
                  DropdownMenuItem(
                      value: 'walk_in', child: Text('Walk-in')),
                ],
                onChanged: (v) =>
                    setState(() => _appointmentType = v!),
              ),
              const SizedBox(height: 12),

              AppTextField(
                label: 'Notes',
                controller: _notesCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              AppButton(
                label: widget.isEditing ? 'Save Changes' : 'Book Appointment',
                onPressed: _submit,
                isLoading: isLoading,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Patient picker bottom sheet ───────────────────────────────────────────

class _PatientPickerSheet extends ConsumerStatefulWidget {
  const _PatientPickerSheet();

  @override
  ConsumerState<_PatientPickerSheet> createState() =>
      _PatientPickerSheetState();
}

class _PatientPickerSheetState extends ConsumerState<_PatientPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(
        patientListProvider(searchQuery: _query.isEmpty ? null : _query));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, controller) => Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search patient…',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: patientsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Error: $e')),
              data: (patients) {
                if (patients.isEmpty) {
                  return const Center(
                    child: Text('No patients found',
                        style: TextStyle(color: AppColors.muted)),
                  );
                }
                return ListView.builder(
                  controller: controller,
                  itemCount: patients.length,
                  itemBuilder: (_, i) {
                    final p = patients[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primarySoft,
                        child: Text(
                          p.fullName
                              .split(' ')
                              .map((w) => w.isNotEmpty ? w[0] : '')
                              .take(2)
                              .join(),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark),
                        ),
                      ),
                      title: Text(p.fullName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(p.phone),
                      onTap: () => Navigator.of(context).pop(p),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
