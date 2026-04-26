import 'package:flutter/material.dart';
class PrescriptionDetailScreen extends StatelessWidget {
  const PrescriptionDetailScreen({super.key, required this.localId});
  final String localId;
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Prescription')), body: const Center(child: Text('TODO')));
}
