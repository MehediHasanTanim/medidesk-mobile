import 'package:flutter/material.dart';
class ReportListScreen extends StatelessWidget {
  const ReportListScreen({super.key, required this.patientId});
  final String patientId;
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Reports')), body: const Center(child: Text('TODO')));
}
