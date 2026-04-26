import 'package:flutter/material.dart';

class AddPaymentScreen extends StatelessWidget {
  const AddPaymentScreen({super.key, required this.invoiceId});
  final String invoiceId;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Add Payment')),
        body: const Center(child: Text('TODO — AddPaymentScreen')),
      );
}
