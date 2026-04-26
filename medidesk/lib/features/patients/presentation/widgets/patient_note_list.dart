import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/sync_status_badge.dart';
import '../../data/models/patient_model.dart';
import '../providers/patient_providers.dart';

class PatientNoteList extends ConsumerStatefulWidget {
  const PatientNoteList({super.key, required this.patientLocalId});

  final String patientLocalId;

  @override
  ConsumerState<PatientNoteList> createState() => _PatientNoteListState();
}

class _PatientNoteListState extends ConsumerState<PatientNoteList> {
  final _noteCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(addPatientNoteNotifierProvider.notifier).execute(
            patientLocalId: widget.patientLocalId,
            content: text,
            // TODO: pass real current-user ID from auth provider
            userId: null,
          );
      if (mounted) _noteCtrl.clear();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(patientNotesProvider(widget.patientLocalId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Clinical Notes',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── Inline add-note form ────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Write a clinical note…',
                      isDense: true,
                    ),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Save note',
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, size: 18),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Notes list ──────────────────────────────────────────────
            notesAsync.when(
              data: (notes) {
                if (notes.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No notes yet.',
                      style: TextStyle(color: Colors.black38, fontSize: 13),
                    ),
                  );
                }
                return Column(
                  children: notes
                      .map((note) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _NoteItem(note: note),
                          ))
                      .toList(),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(
                'Failed to load notes: $e',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteItem extends StatelessWidget {
  const _NoteItem({required this.note});

  final PatientNote note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateFormatter.toRelativeDate(note.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
              const Spacer(),
              SyncStatusBadge(syncStatus: note.syncStatus),
            ],
          ),
          const SizedBox(height: 6),
          Text(note.content, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
