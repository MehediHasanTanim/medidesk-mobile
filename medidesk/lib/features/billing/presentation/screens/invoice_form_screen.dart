import 'package:flutter/material.dart';

class InvoiceFormScreen extends StatelessWidget {
  const InvoiceFormScreen({super.key, this.patientId});
  final String? patientId;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('New Invoice')),
        body: const Center(child: Text('TODO — InvoiceFormScreen')),
      );
}
