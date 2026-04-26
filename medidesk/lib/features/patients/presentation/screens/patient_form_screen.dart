import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../data/models/patient_model.dart';
import '../providers/patient_providers.dart';

class PatientFormScreen extends ConsumerStatefulWidget {
  const PatientFormScreen({super.key, this.localId});

  final String? localId;

  bool get isEditing => localId != null;

  @override
  ConsumerState<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends ConsumerState<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _familyHistoryCtrl = TextEditingController();
  final _allergyCtrl = TextEditingController();
  final _chronicCtrl = TextEditingController();

  String _selectedGender = 'M';
  String? _dateOfBirth;
  List<String> _allergies = [];
  List<String> _chronicDiseases = [];
  bool _loaded = false;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _nationalIdCtrl.dispose();
    _ageCtrl.dispose();
    _familyHistoryCtrl.dispose();
    _allergyCtrl.dispose();
    _chronicCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    if (!widget.isEditing || _loaded) return;
    final patient = await ref.read(patientDetailProvider(widget.localId!).future);
    if (patient == null || !mounted) return;

    _fullNameCtrl.text = patient.fullName;
    _phoneCtrl.text = patient.phone;
    _addressCtrl.text = patient.address;
    _emailCtrl.text = patient.email ?? '';
    _nationalIdCtrl.text = patient.nationalId ?? '';
    _ageCtrl.text = patient.ageYears?.toString() ?? '';
    _familyHistoryCtrl.text = patient.familyHistory;
    _dateOfBirth = patient.dateOfBirth;
    _allergies = List.from(patient.allergies);
    _chronicDiseases = List.from(patient.chronicDiseases);
    setState(() {
      _selectedGender = patient.gender;
      _loaded = true;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.isEditing) {
      await ref.read(updatePatientNotifierProvider.notifier).execute(
            UpdatePatientRequest(
              localId: widget.localId!,
              fullName: _fullNameCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              gender: _selectedGender,
              address: _addressCtrl.text.trim(),
              dateOfBirth: _dateOfBirth,
              email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
              nationalId: _nationalIdCtrl.text.trim().isEmpty
                  ? null
                  : _nationalIdCtrl.text.trim(),
              ageYears: _ageCtrl.text.trim().isEmpty
                  ? null
                  : int.tryParse(_ageCtrl.text.trim()),
              allergies: _allergies,
              chronicDiseases: _chronicDiseases,
              familyHistory: _familyHistoryCtrl.text.trim(),
            ),
          );

      final state = ref.read(updatePatientNotifierProvider);
      if (!mounted) return;
      state.whenOrNull(
        error: (e, _) => context.showSnackBar(e.toString(), isError: true),
        data: (_) {
          context.showSnackBar('Patient updated');
          context.pop();
        },
      );
    } else {
      await ref.read(createPatientNotifierProvider.notifier).execute(
            CreatePatientRequest(
              fullName: _fullNameCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              gender: _selectedGender,
              address: _addressCtrl.text.trim(),
              dateOfBirth: _dateOfBirth,
              email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
              nationalId: _nationalIdCtrl.text.trim().isEmpty
                  ? null
                  : _nationalIdCtrl.text.trim(),
              ageYears: _ageCtrl.text.trim().isEmpty
                  ? null
                  : int.tryParse(_ageCtrl.text.trim()),
              allergies: _allergies,
              chronicDiseases: _chronicDiseases,
              familyHistory: _familyHistoryCtrl.text.trim(),
            ),
          );

      final state = ref.read(createPatientNotifierProvider);
      if (!mounted) return;
      state.whenOrNull(
        error: (e, _) => context.showSnackBar(e.toString(), isError: true),
        data: (_) {
          context.showSnackBar('Patient registered');
          context.pop();
        },
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth != null
          ? DateTime.parse(_dateOfBirth!)
          : DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(createPatientNotifierProvider).isLoading ||
        ref.watch(updatePatientNotifierProvider).isLoading;

    return LoadingOverlay(
      isLoading: isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit Patient' : 'New Patient'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppTextField(
                label: 'Full Name *',
                controller: _fullNameCtrl,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, label: 'Full name'),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Phone *',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: Validators.phone,
              ),
              const SizedBox(height: 12),

              // Gender selector
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: const InputDecoration(labelText: 'Gender *'),
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('Male')),
                  DropdownMenuItem(value: 'F', child: Text('Female')),
                  DropdownMenuItem(value: 'O', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _selectedGender = v!),
              ),
              const SizedBox(height: 12),

              AppTextField(
                label: 'Address *',
                controller: _addressCtrl,
                maxLines: 2,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, label: 'Address'),
              ),
              const SizedBox(height: 12),

              // Date of birth
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(
                    _dateOfBirth ?? 'Select date',
                    style: TextStyle(
                      color: _dateOfBirth == null ? Colors.black38 : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              AppTextField(
                label: 'Age (if DOB unknown)',
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    Validators.integer(v, label: 'Age', min: 0, max: 150),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Email',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: Validators.email,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'National ID',
                controller: _nationalIdCtrl,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Allergies
              _TagInput(
                label: 'Allergies',
                tags: _allergies,
                controller: _allergyCtrl,
                onAdd: (v) => setState(() => _allergies.add(v)),
                onRemove: (v) => setState(() => _allergies.remove(v)),
                chipColor: Colors.red[50]!,
                textColor: Colors.red[700]!,
              ),
              const SizedBox(height: 16),

              // Chronic diseases
              _TagInput(
                label: 'Chronic Diseases',
                tags: _chronicDiseases,
                controller: _chronicCtrl,
                onAdd: (v) => setState(() => _chronicDiseases.add(v)),
                onRemove: (v) => setState(() => _chronicDiseases.remove(v)),
                chipColor: Colors.orange[50]!,
                textColor: Colors.orange[700]!,
              ),
              const SizedBox(height: 12),

              AppTextField(
                label: 'Family History',
                controller: _familyHistoryCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              AppButton(
                label: widget.isEditing ? 'Save Changes' : 'Register Patient',
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

class _TagInput extends StatelessWidget {
  const _TagInput({
    required this.label,
    required this.tags,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
    required this.chipColor,
    required this.textColor,
  });

  final String label;
  final List<String> tags;
  final TextEditingController controller;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final Color chipColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        if (tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: tags
                .map(
                  (t) => Chip(
                    label: Text(
                      t,
                      style: TextStyle(color: textColor, fontSize: 12),
                    ),
                    backgroundColor: chipColor,
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => onRemove(t),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Add $label...',
                  isDense: true,
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (v) {
                  final trimmed = v.trim();
                  if (trimmed.isNotEmpty) {
                    onAdd(trimmed);
                    controller.clear();
                  }
                },
              ),
            ),
            TextButton(
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isNotEmpty) {
                  onAdd(trimmed);
                  controller.clear();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ],
    );
  }
}
