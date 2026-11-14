import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/design_system.dart';
import '../../features/authentication/auth_controller.dart';
import '../../features/authentication/login_screen.dart';
import '../../features/authentication/sign_up_screen.dart';
import '../../features/booking/fare_screen.dart';
import '../../features/booking/passengers_screen.dart';
import '../../features/checkout/confirmation_screen.dart';
import '../../features/checkout/review_screen.dart';
import '../../features/flight_search/flight_results_screen.dart';
import '../../features/flight_search/flight_search_providers.dart';
import '../../features/my_flights/trip_details_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/account_screens.dart';
import '../../features/seats/seats_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/splash/splash_screen.dart';
import 'routes.dart';

/// Cross-fade used where the reference dissolves between screens:
/// splash to sign-in, and sign-in to the app.
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child, Duration duration) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut), child: child),
  );
}

/// Standard push with the iOS slide and swipe-back gesture.
CupertinoPage<void> _push(GoRouterState state, Widget child) => CupertinoPage<void>(key: state.pageKey, child: child);

const _public = {Routes.splash, Routes.login, Routes.signUp};

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    // Anything behind sign-in sends a signed-out visitor to the login screen.
    redirect: (context, state) {
      final signedIn = ref.read(authControllerProvider).isSignedIn;
      if (!signedIn && !_public.contains(state.matchedLocation)) return Routes.login;
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: Routes.login,
        pageBuilder: (context, state) => _fadePage(state, const LoginScreen(), SysflyMotion.splashToLogin),
      ),
      GoRoute(path: Routes.signUp, pageBuilder: (context, state) => _push(state, const SignUpScreen())),
      GoRoute(
        path: Routes.home,
        pageBuilder: (context, state) => _fadePage(state, const MainShell(), SysflyMotion.loaderFadeOut),
      ),
      GoRoute(path: Routes.notifications, pageBuilder: (context, state) => _push(state, const NotificationsScreen())),
      GoRoute(
        path: Routes.results,
        pageBuilder: (context, state) => _push(
          state,
          FlightResultsScreen(
            leg: state.uri.queryParameters['leg'] == 'inbound' ? SearchLeg.inbound : SearchLeg.outbound,
          ),
        ),
      ),
      GoRoute(path: Routes.fare, pageBuilder: (context, state) => _push(state, const FareScreen())),
      GoRoute(path: Routes.passengers, pageBuilder: (context, state) => _push(state, const PassengersScreen())),
      GoRoute(path: Routes.seats, pageBuilder: (context, state) => _push(state, const SeatsScreen())),
      GoRoute(path: Routes.review, pageBuilder: (context, state) => _push(state, const ReviewScreen())),
      GoRoute(
        path: '${Routes.confirmed}/:reference',
        pageBuilder: (context, state) => _fadePage(
          state,
          ConfirmationScreen(reference: state.pathParameters['reference']!),
          SysflyMotion.loaderFadeOut,
        ),
      ),
      GoRoute(
        path: '${Routes.trip}/:reference',
        pageBuilder: (context, state) => _push(state, TripDetailsScreen(reference: state.pathParameters['reference']!)),
      ),
      GoRoute(path: Routes.personalInfo, pageBuilder: (context, state) => _push(state, const PersonalInfoScreen())),
      GoRoute(path: Routes.savedTravellers, pageBuilder: (context, state) => _push(state, const SavedTravellersScreen())),
      GoRoute(path: Routes.paymentMethods, pageBuilder: (context, state) => _push(state, const PaymentMethodsScreen())),
      GoRoute(path: Routes.travelDocuments, pageBuilder: (context, state) => _push(state, const TravelDocumentsScreen())),
    ],
  );
});
