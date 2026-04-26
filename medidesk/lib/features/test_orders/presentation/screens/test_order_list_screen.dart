import 'package:flutter/material.dart';
class TestOrderListScreen extends StatelessWidget {
  const TestOrderListScreen({super.key, required this.consultationId});
  final String consultationId;
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Test Orders')), body: const Center(child: Text('TODO')));
}
