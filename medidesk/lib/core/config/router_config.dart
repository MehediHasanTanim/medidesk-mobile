import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/chambers/presentation/screens/chamber_list_screen.dart';
import '../../features/patients/presentation/screens/patient_list_screen.dart';
import '../../features/patients/presentation/screens/patient_detail_screen.dart';
import '../../features/patients/presentation/screens/patient_form_screen.dart';
import '../../features/appointments/presentation/screens/appointment_list_screen.dart';
import '../../features/appointments/presentation/screens/appointment_detail_screen.dart';
import '../../features/appointments/presentation/screens/appointment_form_screen.dart';
import '../../features/appointments/presentation/screens/queue_management_screen.dart';
import '../../features/consultations/presentation/screens/consultation_detail_screen.dart';
import '../../features/consultations/presentation/screens/consultation_form_screen.dart';
import '../../features/prescriptions/presentation/screens/prescription_detail_screen.dart';
import '../../features/prescriptions/presentation/screens/prescription_form_screen.dart';
import '../../features/test_orders/presentation/screens/test_order_form_screen.dart';
import '../../features/test_orders/presentation/screens/test_order_list_screen.dart';
import '../../features/reports/presentation/screens/report_list_screen.dart';
import '../../features/reports/presentation/screens/report_upload_screen.dart';
import '../../features/billing/presentation/screens/invoice_list_screen.dart';
import '../../features/billing/presentation/screens/invoice_detail_screen.dart';
import '../../features/billing/presentation/screens/invoice_form_screen.dart';
import '../../features/billing/presentation/screens/add_payment_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../core/theme/app_colors.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Re-evaluates (and re-creates the router) whenever auth state flips.
  // GoRouter replacement is desirable here: it clears navigation history,
  // which is exactly what login→dashboard and logout→login transitions need.
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: isAuthenticated ? '/dashboard' : '/login',
    redirect: (context, state) {
      final onLogin = state.matchedLocation == '/login';
      if (!isAuthenticated && !onLogin) return '/login';
      if (isAuthenticated && onLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (ctx, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (ctx, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (ctx, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/chambers',
            name: 'chambers',
            builder: (ctx, state) => const ChamberListScreen(),
          ),
          // Patients
          GoRoute(
            path: '/patients',
            name: 'patients',
            builder: (ctx, state) => const PatientListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'patient-new',
                builder: (ctx, state) => const PatientFormScreen(),
              ),
              GoRoute(
                path: ':localId',
                name: 'patient-detail',
                builder: (ctx, state) =>
                    PatientDetailScreen(localId: state.pathParameters['localId']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'patient-edit',
                    builder: (ctx, state) => PatientFormScreen(
                      localId: state.pathParameters['localId'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Appointments / Schedule
          GoRoute(
            path: '/appointments',
            name: 'appointments',
            builder: (ctx, state) => const AppointmentListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'appointment-new',
                builder: (ctx, state) => AppointmentFormScreen(
                  patientId: state.uri.queryParameters['patientId'],
                ),
              ),
              GoRoute(
                path: 'queue',
                name: 'queue',
                builder: (ctx, state) => const QueueManagementScreen(),
              ),
              GoRoute(
                path: ':localId',
                name: 'appointment-detail',
                builder: (ctx, state) => AppointmentDetailScreen(
                  localId: state.pathParameters['localId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'appointment-edit',
                    builder: (ctx, state) => AppointmentFormScreen(
                      localId: state.pathParameters['localId'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Consultations
          GoRoute(
            path: '/consultations/:localId',
            name: 'consultation-detail',
            builder: (ctx, state) => ConsultationDetailScreen(
              localId: state.pathParameters['localId']!,
            ),
            routes: [
              GoRoute(
                path: 'form',
                name: 'consultation-form',
                builder: (ctx, state) => ConsultationFormScreen(
                  consultationId: state.pathParameters['localId']!,
                ),
              ),
            ],
          ),
          // Prescriptions
          GoRoute(
            path: '/prescriptions/:localId',
            name: 'prescription-detail',
            builder: (ctx, state) => PrescriptionDetailScreen(
              localId: state.pathParameters['localId']!,
            ),
            routes: [
              GoRoute(
                path: 'form',
                name: 'prescription-form',
                builder: (ctx, state) => PrescriptionFormScreen(
                  prescriptionId: state.pathParameters['localId']!,
                ),
              ),
            ],
          ),
          // Test Orders
          GoRoute(
            path: '/test-orders/:consultationId/new',
            name: 'test-order-new',
            builder: (ctx, state) => TestOrderFormScreen(
              consultationId: state.pathParameters['consultationId']!,
            ),
          ),
          GoRoute(
            path: '/test-orders/:consultationId',
            name: 'test-orders',
            builder: (ctx, state) => TestOrderListScreen(
              consultationId: state.pathParameters['consultationId']!,
            ),
          ),
          // Reports
          GoRoute(
            path: '/reports/:patientId',
            name: 'reports',
            builder: (ctx, state) =>
                ReportListScreen(patientId: state.pathParameters['patientId']!),
          ),
          GoRoute(
            path: '/reports/upload',
            name: 'report-upload',
            builder: (ctx, state) => const ReportUploadScreen(),
          ),
          // Billing
          GoRoute(
            path: '/billing/invoices',
            name: 'invoices',
            builder: (ctx, state) => const InvoiceListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'invoice-new',
                builder: (ctx, state) => const InvoiceFormScreen(),
              ),
              GoRoute(
                path: ':localId',
                name: 'invoice-detail',
                builder: (ctx, state) => InvoiceDetailScreen(
                  localId: state.pathParameters['localId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'pay',
                    name: 'add-payment',
                    builder: (ctx, state) => AddPaymentScreen(
                      invoiceId: state.pathParameters['localId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Analytics
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            builder: (ctx, state) => const AnalyticsScreen(),
          ),
          // Settings
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (ctx, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class _AppShell extends StatefulWidget {
  const _AppShell({required this.child});
  final Widget child;

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  static const _routes = [
    '/dashboard',
    '/appointments/queue',
    '/patients',
    '/appointments',
    '/settings',
  ];

  int _indexForLocation(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/appointments/queue')) return 1;
    if (location.startsWith('/patients')) return 2;
    if (location.startsWith('/appointments')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIdx = _indexForLocation(location);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: currentIdx,
          onDestinationSelected: (i) {
            setState(() {});
            context.go(_routes[i]);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.queue_outlined),
              selectedIcon: Icon(Icons.queue),
              label: 'Queue',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_alt_outlined),
              selectedIcon: Icon(Icons.people_alt_rounded),
              label: 'Patients',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today_rounded),
              label: 'Schedule',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Me',
            ),
          ],
        ),
      ),
    );
  }
}
