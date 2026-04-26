import 'package:flutter/material.dart';

class AppointmentFormScreen extends StatelessWidget {
  const AppointmentFormScreen({super.key, this.patientId});
  final String? patientId;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('New Appointment')),
        body: const Center(child: Text('TODO — AppointmentFormScreen')),
      );
}
