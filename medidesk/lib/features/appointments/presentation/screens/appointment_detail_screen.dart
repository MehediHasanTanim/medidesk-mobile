import 'package:flutter/material.dart';

class AppointmentDetailScreen extends StatelessWidget {
  const AppointmentDetailScreen({super.key, required this.localId});
  final String localId;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Appointment')),
        body: const Center(child: Text('TODO — AppointmentDetailScreen')),
      );
}
