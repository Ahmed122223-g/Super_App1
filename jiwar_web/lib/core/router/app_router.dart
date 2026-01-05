import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jiwar_web/core/providers/auth_provider.dart';
import 'package:jiwar_web/pages/home/home_page.dart';
import 'package:jiwar_web/pages/auth/login_page.dart';
import 'package:jiwar_web/pages/auth/signup_page.dart';
import 'package:jiwar_web/pages/auth/admin_signup_page.dart';
import 'package:jiwar_web/pages/static/about_page.dart';
import 'package:jiwar_web/pages/static/privacy_page.dart';
import 'package:jiwar_web/pages/static/terms_page.dart';
import 'package:jiwar_web/pages/search/search_page.dart';
import 'package:jiwar_web/pages/dashboard/doctor/doctor_dashboard.dart';
import 'package:jiwar_web/pages/dashboard/pharmacy/pharmacy_dashboard.dart';
import 'package:jiwar_web/pages/dashboard/teacher/teacher_dashboard.dart';
import 'package:jiwar_web/pages/dashboard/user/user_dashboard.dart';
import 'package:jiwar_web/pages/booking/booking_page.dart';
import 'package:jiwar_web/pages/orders/pharmacy_order_page.dart';

/// App router configuration provider
final routerProvider = Provider<GoRouter>((ref) {
  // We use a ValueNotifier to notify GoRouter when auth state changes
  // without rebuilding the entire router (which resets navigation stack)
  final authNotifier = ValueNotifier<AuthState>(const AuthState());
  
  // Listen to auth updates and notify the router
  ref.listen<AuthState>(
    authProvider,
    (previous, next) {
      authNotifier.value = next;
      authNotifier.notifyListeners();
    },
    fireImmediately: true,
  );

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // READ the current state, don't watch it here or in the provider body
      // to avoid unnecessary rebuilds of the redirect logic itself (though GoRouter handles that)
      // The important part is that the Provider body didn't rebuild.
      final authState = ref.read(authProvider);
      
      final isLoggingIn = state.uri.path == '/login';
      final isSigningUp = state.uri.path == '/signup' || state.uri.path == '/signup_admin';
      final isDashboard = state.uri.path.startsWith('/dashboard');
      
      // If not authenticated and trying to access dashboard -> Redirect to Login
      if (!authState.isAuthenticated && isDashboard) {
        return '/login';
      }
      
      // If authenticated and trying to access login/signup -> Redirect to Dashboard
      if (authState.isAuthenticated && (isLoggingIn || isSigningUp)) {
        // Redirect based on user type if available, default to user dashboard
        switch (authState.userType) {
          case 'doctor':
            return '/dashboard/doctor';
          case 'pharmacy':
            return '/dashboard/pharmacy';
          case 'teacher':
            return '/dashboard/teacher';
          default:
            return '/dashboard/user';
        }
      }
      
      return null;
    },
    routes: [
      // Landing page
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (context, state) => _buildPage(
          const HomePage(),
          state,
        ),
      ),
      
      // Search map
      GoRoute(
        path: '/search',
        name: 'search',
        pageBuilder: (context, state) {
          final query = state.uri.queryParameters['q'];
          final type = state.uri.queryParameters['type'];
          return _buildPage(
             SearchPage(query: query, type: type),
            state,
          );
        },
      ),
      
      // User authentication
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _buildPage(
          const LoginPage(),
          state,
        ),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        pageBuilder: (context, state) => _buildPage(
          const SignupPage(),
          state,
        ),
      ),
      
      // Admin authentication
      GoRoute(
        path: '/signup_admin',
        name: 'signup_admin',
        pageBuilder: (context, state) => _buildPage(
          const AdminSignupPage(),
          state,
        ),
      ),
      
      // Dashboard Routes
      GoRoute(
        path: '/dashboard/doctor',
        name: 'doctor_dashboard',
        pageBuilder: (context, state) => _buildPage(
          const DoctorDashboard(),
          state,
        ),
      ),
      GoRoute(
        path: '/dashboard/pharmacy',
        name: 'pharmacy_dashboard',
        pageBuilder: (context, state) => _buildPage(
          const PharmacyDashboard(),
          state,
        ),
      ),
      GoRoute(
        path: '/dashboard/teacher',
        name: 'teacher_dashboard',
        pageBuilder: (context, state) => _buildPage(
          const TeacherDashboard(),
          state,
        ),
      ),
      GoRoute(
        path: '/dashboard/user',
        name: 'user_dashboard',
        pageBuilder: (context, state) => _buildPage(
          const UserDashboard(),
          state,
        ),
      ),

      // Static pages
      GoRoute(
        path: '/about',
        name: 'about',
        pageBuilder: (context, state) => _buildPage(
          const AboutPage(),
          state,
        ),
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        pageBuilder: (context, state) => _buildPage(
          const PrivacyPage(),
          state,
        ),
      ),
      GoRoute(
        path: '/terms',
        name: 'terms',
        pageBuilder: (context, state) => _buildPage(
          const TermsPage(),
          state,
        ),
      ),
      
      // Booking & Ordering
      GoRoute(
        path: '/booking/:type/:id',
        name: 'booking',
        pageBuilder: (context, state) {
          final type = state.pathParameters['type']!;
          final id = int.parse(state.pathParameters['id']!);
          final extra = state.extra as Map<String, dynamic>? ?? {};
          
          return _buildPage(
            BookingPage(
              providerId: id,
              providerType: type,
              providerName: extra['name'] ?? 'Provider',
              specialty: extra['specialty'],
              examinationFee: extra['examinationFee'] != null ? (extra['examinationFee'] as num).toDouble() : null,
              consultationFee: extra['consultationFee'] != null ? (extra['consultationFee'] as num).toDouble() : null,
            ),
            state,
          );
        },
      ),
      GoRoute(
        path: '/order-pharmacy/:id',
        name: 'pharmacy_order',
        pageBuilder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final extra = state.extra as Map<String, dynamic>? ?? {};
          
          return _buildPage(
            PharmacyOrderPage(
              pharmacyId: id,
              pharmacyName: extra['name'] ?? 'Pharmacy',
            ),
            state,
          );
        },
      ),
    ],
    errorPageBuilder: (context, state) => _buildPage(
      Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '404 - Page Not Found',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(state.uri.toString()),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
      state,
    ),
  );
});

/// Build page with fade transition
CustomTransitionPage<void> _buildPage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}
