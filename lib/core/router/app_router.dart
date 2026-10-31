import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/phone_auth_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/donations/presentation/screens/donations_history_screen.dart';
import '../../features/donations/presentation/screens/record_donation_screen.dart';
import '../../features/donor_finder/presentation/screens/donor_finder_screen.dart';
import '../../features/hospitals/presentation/screens/hospitals_list_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/permission_explanation_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/requests/presentation/screens/create_request_screen.dart';
import '../../features/requests/presentation/screens/request_detail_screen.dart';
import '../../features/requests/presentation/screens/requests_inbox_screen.dart';
import '../../features/sos/presentation/screens/sos_screen.dart';
import '../widgets/main_nav_shell.dart';
import 'not_found_screen.dart';
import 'route_constants.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutePaths.splash,
    debugLogDiagnostics: false,
    errorBuilder: (context, state) => const NotFoundScreen(),
    redirect: (BuildContext context, GoRouterState state) {
      final loc = state.matchedLocation;

      // Allow splash, onboarding, and permissions unconditionally
      if (loc == AppRoutePaths.splash ||
          loc == AppRoutePaths.onboarding ||
          loc == AppRoutePaths.permissions) {
        return null;
      }

      // Check if unauthenticated and trying to access protected routes
      final isAuthRoute = loc == AppRoutePaths.login ||
          loc == AppRoutePaths.register ||
          loc == AppRoutePaths.forgotPassword ||
          loc == AppRoutePaths.phoneAuth;

      if (!authState.isAuthenticated) {
        // If not authenticated, we allow access to public and preview paths
        // When auth is strictly required for certain actions, redirection can trigger
        return null;
      }

      // If user is authenticated and attempts to visit login/register, route to dashboard
      if (authState.isAuthenticated && isAuthRoute) {
        return AppRoutePaths.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.permissions,
        builder: (context, state) => const PermissionExplanationScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.phoneAuth,
        builder: (context, state) => const PhoneAuthScreen(),
      ),
      // 5-Tab Primary Shell with persistent bottom navigation bar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Tab 1: Find Donors
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.donorFinder,
                builder: (context, state) => const DonorFinderScreen(),
              ),
            ],
          ),
          // Tab 2: SOS
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.sos,
                builder: (context, state) => const SosScreen(),
              ),
            ],
          ),
          // Tab 3: History
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.donations,
                builder: (context, state) => const DonationsHistoryScreen(),
              ),
            ],
          ),
          // Tab 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutePaths.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutePaths.requests,
        builder: (context, state) => const RequestsInboxScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.createRequest,
        builder: (context, state) => const CreateRequestScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.requestDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return RequestDetailScreen(requestId: id);
        },
      ),
      GoRoute(
        path: AppRoutePaths.recordDonation,
        builder: (context, state) {
          final hospitalId = state.uri.queryParameters['hospitalId'];
          return RecordDonationScreen(initialHospitalId: hospitalId);
        },
      ),
      GoRoute(
        path: AppRoutePaths.hospitals,
        builder: (context, state) => const HospitalsListScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.leaderboard,
        builder: (context, state) => const LeaderboardScreen(),
      ),
    ],
  );
});
