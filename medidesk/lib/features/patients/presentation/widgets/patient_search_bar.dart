import 'package:flutter/material.dart';

class PatientSearchBar extends StatefulWidget {
  const PatientSearchBar({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<PatientSearchBar> createState() => _PatientSearchBarState();
}

class _PatientSearchBarState extends State<PatientSearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _ctrl,
        decoration: InputDecoration(
          hintText: 'Search by name, phone, or patient ID…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _ctrl.clear();
                    widget.onChanged('');
                  },
                )
              : null,
          filled: true,
          isDense: true,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
