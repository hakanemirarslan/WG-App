import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_providers.dart';
import '../features/auth/ui/login_page.dart';
import '../features/auth/ui/signup_page.dart';
import '../features/expenses/ui/expense_detail_page.dart';
import '../features/expenses/ui/expense_form_page.dart';
import '../features/expenses/ui/expenses_page.dart';
import '../features/groups/ui/group_page.dart';
import '../features/groups/ui/group_shell.dart';
import '../features/groups/ui/groups_page.dart';
import '../features/groups/ui/join_page.dart';
import '../features/settings/ui/settings_page.dart';
import '../features/shopping_list/ui/shopping_list_page.dart';
import '../l10n/app_localizations.dart';
import 'supabase_client.dart';

/// Turns a Stream into a [Listenable] so go_router can re-evaluate its
/// `redirect` callback whenever the Supabase auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Builds `/login` or `/signup`, keeping the page the user originally wanted
/// (e.g. `/join/<code>`) in `?from=` so we can return there after auth.
String authPath(String path, String? from) =>
    from == null ? path : Uri(path: path, queryParameters: {'from': from}).toString();

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final refreshListenable = GoRouterRefreshStream(authRepository.onAuthStateChange);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final isLoggedIn = supabase.auth.currentSession != null;
      final isAuthRoute =
          state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (!isLoggedIn) {
        if (isAuthRoute) return null;
        // Remember deep links such as /join/<code>; plain '/' needs no return trip.
        final target = state.matchedLocation == '/' ? null : state.uri.toString();
        return authPath('/login', target);
      }
      if (isAuthRoute) {
        return state.uri.queryParameters['from'] ?? '/home';
      }
      if (state.matchedLocation == '/') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SizedBox.shrink()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
      GoRoute(path: '/home', builder: (context, state) => const GroupsPage()),
      // Tabs are children of /group/:id because go_router requires each
      // StatefulShellBranch's default route to have no path parameters of its own.
      GoRoute(
        path: '/group/:id',
        redirect: (context, state) =>
            state.uri.pathSegments.length == 2 ? '${state.uri.path}/list' : null,
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                GroupShell(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(routes: [
                GoRoute(
                  path: 'list',
                  builder: (context, state) =>
                      ShoppingListPage(groupId: state.pathParameters['id']!),
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  path: 'expenses',
                  builder: (context, state) =>
                      ExpensesPage(groupId: state.pathParameters['id']!),
                  routes: [
                    // Full-screen pages on the root navigator (no bottom bar).
                    GoRoute(
                      path: 'new',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) =>
                          ExpenseFormPage(groupId: state.pathParameters['id']!),
                    ),
                    GoRoute(
                      path: ':expenseId',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => ExpenseDetailPage(
                        groupId: state.pathParameters['id']!,
                        expenseId: state.pathParameters['expenseId']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'edit',
                          parentNavigatorKey: _rootNavigatorKey,
                          builder: (context, state) => ExpenseFormPage(
                            groupId: state.pathParameters['id']!,
                            expenseId: state.pathParameters['expenseId']!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  path: 'balance',
                  builder: (context, state) => ComingSoonTab(
                    title: AppLocalizations.of(context)!.tabBalance,
                  ),
                ),
              ]),
              StatefulShellBranch(routes: [
                GoRoute(
                  path: 'members',
                  builder: (context, state) =>
                      GroupPage(groupId: state.pathParameters['id']!),
                ),
              ]),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/join/:code',
        builder: (context, state) => JoinPage(code: state.pathParameters['code']!),
      ),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
    ],
  );
});
