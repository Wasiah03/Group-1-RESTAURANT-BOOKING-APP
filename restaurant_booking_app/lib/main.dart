import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'providers/menu_provider.dart';
import 'providers/booking_provider.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/guest_screen.dart';
import 'screens/user_home_screen.dart';
import 'screens/booking_form_screen.dart';
import 'screens/my_reservations_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/edit_booking_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: Builder(
        builder: (context) {
          final router = GoRouter(
            initialLocation: '/',
            redirect: (context, state) {
              final authProvider = context.read<AuthProvider>();
              final isAuthenticated = authProvider.isAuthenticated;
              final currentUser = authProvider.currentUser;

              final isGoingToLogin = state.matchedLocation == '/';
              final isGoingToRegister = state.matchedLocation == '/register';
              final isGoingToGuest = state.matchedLocation == '/guest';

              // If not authenticated and trying to access protected routes
              if (!isAuthenticated &&
                  !isGoingToLogin &&
                  !isGoingToRegister &&
                  !isGoingToGuest) {
                return '/';
              }

              // If authenticated and going to login/register, redirect based on role
              if (isAuthenticated && (isGoingToLogin || isGoingToRegister)) {
                if (currentUser?.role == 'admin') {
                  return '/admin';
                } else {
                  return '/user';
                }
              }

              return null; // No redirect
            },
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const LoginScreen(),
              ),
              GoRoute(
                path: '/register',
                builder: (context, state) => const RegistrationScreen(),
              ),
              GoRoute(
                path: '/guest',
                builder: (context, state) => const GuestScreen(),
              ),
              GoRoute(
                path: '/user',
                builder: (context, state) => const UserHomeScreen(),
              ),
              GoRoute(
                path: '/user/book/:packageId',
                builder: (context, state) {
                  final packageId = state.pathParameters['packageId']!;
                  return BookingFormScreen(packageId: packageId);
                },
              ),
              GoRoute(
                path: '/user/reservations',
                builder: (context, state) => const MyReservationsScreen(),
              ),
              GoRoute(
                path: '/admin',
                builder: (context, state) => const AdminDashboardScreen(),
              ),
              GoRoute(
                path: '/edit-booking/:bookingId',
                builder: (context, state) {
                  final bookingId = state.pathParameters['bookingId']!;
                  return EditBookingScreen(bookingId: bookingId);
                },
              ),
            ],
          );

          return MaterialApp.router(
            title: 'The Grand Palate',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF5D4037),
                brightness: Brightness.light,
              ),
              primaryColor: const Color(0xFF5D4037),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
                backgroundColor: Color(0xFF5D4037),
                foregroundColor: Colors.white,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D4037),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
