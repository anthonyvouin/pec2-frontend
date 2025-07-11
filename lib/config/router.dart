import 'package:firstflutterapp/admin/admin_dashboard.dart';
import 'package:firstflutterapp/notifiers/userNotififers.dart';
import 'package:firstflutterapp/screens/confirm-email/confirm_email_view.dart';
import 'package:firstflutterapp/screens/confirm-email/resend-email-confirmation.dart';
import 'package:firstflutterapp/screens/creator/creator-view.dart';
import 'package:firstflutterapp/screens/home/home_view.dart';
import 'package:firstflutterapp/screens/post-creation/post-details.dart';
import 'package:firstflutterapp/screens/post-creation/upload-photo.dart';
import 'package:firstflutterapp/screens/post_detail/post_fullscreen_view.dart';
import 'package:firstflutterapp/interfaces/post.dart';
import 'package:firstflutterapp/screens/profile/other_profil_view.dart';
import 'package:firstflutterapp/screens/profile/profil_view.dart';
import 'package:firstflutterapp/screens/profile/setting-preferences/setting-preferences.dart';
import 'package:firstflutterapp/screens/profile/setting-user/setting-user.dart';
import 'package:firstflutterapp/screens/profile/subscriptions/user_subscriptions.dart';
import 'package:firstflutterapp/screens/profile/update_profile/update_profile.dart';
import 'package:firstflutterapp/screens/register/end-register.dart';
import 'package:firstflutterapp/screens/register/register_view.dart';
import 'package:firstflutterapp/screens/stripe/stripe_error.dart';
import 'package:firstflutterapp/screens/stripe/stripe_success.dart';
import 'package:firstflutterapp/screens/sub_feed_view/sub_feed_view.dart';
import 'package:firstflutterapp/screens/support.dart';
import 'package:firstflutterapp/screens/update_password/update_password_view.dart';
import 'package:firstflutterapp/screens/search_view/search_view.dart';
import 'package:firstflutterapp/components/bottom-navigation/container.dart';
import 'package:go_router/go_router.dart';
import 'package:firstflutterapp/screens/login/login_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firstflutterapp/admin/users_management.dart';
import 'package:firstflutterapp/admin/contact_management.dart';
import 'package:firstflutterapp/admin/users_chart.dart';
import 'package:firstflutterapp/admin/content_creator.dart';
import 'package:firstflutterapp/admin/categories_management.dart';
import 'package:firstflutterapp/screens/message/message.dart';
import 'package:firstflutterapp/admin/admin_kpi.dart';
import 'package:firstflutterapp/screens/reset-password/request-reset-password.dart';
import 'package:firstflutterapp/screens/reset-password/confirm-reset-password.dart';

import 'package:firstflutterapp/admin/statistics_page.dart';

import '../screens/creator/creator_statistics.dart';

const homeRoute = '/';
const loginRoute = '/login';
const uploadPhotoRoute = '/upload-photo';
const subFeedRoute = '/sub';
const registerRoute = '/register';
const registerInfoRoute = '/register/info';
const confirmEmailRoute = '/confirm-email';
const resendConfirmEmailRoute = '/confirm-email/resend';
const profileRoute = '/profile';
const otherProfileRoute = '/profile/:username';
const editProfileRoute = '/profile/edit';
const profileParams = '/profile/params';
const profileUpdatePassword = '/profile/params/update-password';
const profileSupport = '/profile/params/support';
const profileSubscriptions = '/profile/params/subscriptions';
const adminRoute = '/admin';
const adminDashboard = '/admin/dashboard';
const adminUsersManagement = '/admin/users';
const adminContacts = '/admin/contacts';
const adminUsersChart = '/admin/users-chart';
const adminContentCreator = '/admin/content-creator';
const adminRevenueChart = '/admin/revenue-chart';
const adminPostsChart = '/admin/posts-chart';
const adminStatistics = '/admin/statistics';
const profilePreferences = '/profile/params/preferences';
const searchRoute = '/search';
const messageRoute = '/message';
const adminKpiDashboard = '/admin/kpi-dashboard';
const adminCategoriesManagement = '/admin/categories-management';
const resetPasswordRoute = '/reset-password';
const confirmResetPasswordRoute = '/reset-password/confirm';
const postDetailRoute = '/post/:id';
const postEdit = '/post/edit/:id';

Future<String?> hasAdminPermissions(
  BuildContext context,
  GoRouterState state,
) async {
  final user = context.read<UserNotifier>();

  if (await user.isAdmin()) {
    return null;
  }

  return loginRoute;
}

Future<String?> isAuthenticated(
  BuildContext context,
  GoRouterState state,
) async {
  final session = context.read<UserNotifier>();
  final allowedUnauthenticatedPaths = ['/stripe-success', '/stripe-error'];
  if (allowedUnauthenticatedPaths.contains(state.uri.path)) {
    return null;
  }
  if (await session.isAuthenticated()) {
    return null;
  }
  return loginRoute;
}

final router = GoRouter(
  initialLocation: homeRoute,
  routes: [
    /// Routes avec BottomNavigationBar
    ShellRoute(
      // navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        final location = state.uri.toString();
        return Scaffold(
          body: child,
          bottomNavigationBar: BottomNavBar(currentPath: location),
        );
      },
      routes: [
        GoRoute(
          path: homeRoute,
          builder: (context, state) => HomeView(),
          redirect: (context, state) {
            return isAuthenticated(context, state);
          },
        ),
        GoRoute(
          path: searchRoute,
          builder: (context, state) => SearchView(),
          redirect: (context, state) {
            return isAuthenticated(context, state);
          },
        ),
        GoRoute(
          path: uploadPhotoRoute,
          builder: (context, state) => UploadPhotoView(),
          redirect: (context, state) {
            return isAuthenticated(context, state);
          },
        ),
        GoRoute(
          path: subFeedRoute,
          builder: (context, state) => SubscriptionFeedView(),
          redirect: (context, state) {
            return isAuthenticated(context, state);
          },
        ),
        GoRoute(
          path: messageRoute,
          builder: (context, state) => const MessagePage(),
          redirect: (context, state) {
            return isAuthenticated(context, state);
          },
        ),
        GoRoute(
          path: profileRoute,
          builder: (context, state) => ProfileView(),
          name: 'profile',
          redirect: (context, state) {
            return isAuthenticated(context, state);
          },
          routes: [
            GoRoute(
              path: 'edit',
              name: 'edit-profile',
              builder: (context, state) => UpdateProfile(),
            ),
            GoRoute(
              path: 'creator',
              name: 'profile-creator',
              builder: (context, state) => CreatorView(),
            ),
            GoRoute(
              path: 'statistic-creator',
              name: 'statistic-creator',
              builder: (context, state) => CreatorStatView(),
            ),
            GoRoute(
              path: 'params',
              name: 'profile-params',
              builder: (context, state) => SettingUser(),
              routes: [
                GoRoute(
                  path: 'update-password',
                  name: 'update-password',
                  builder: (context, state) => UpdatePasswordView(),
                ),
                GoRoute(
                  path: 'support',
                  name: 'support',
                  builder: (context, state) => SupportPage(),
                ),
                GoRoute(
                  path: 'preferences',
                  name: 'preferences',
                  builder: (context, state) => SettingPreferences(),
                ),
                GoRoute(
                  path: 'subscriptions',
                  name: 'subscriptions',
                  builder: (context, state) => const UserSubscriptionsPage(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: otherProfileRoute,
          builder: (context, state) {
            final username = state.pathParameters['username'];
            return OtherProfileView(username: username);
          },
          redirect: (context, state) {
            return isAuthenticated(context, state);
          },
        ),
      ],
    ),

    /// Autres routes (sans menu)
    GoRoute(
      path: '/stripe-success',
      name: 'stripe-success',
      builder: (context, state) => StripeSuccess(),
    ),
    GoRoute(
      path: '/stripe-error',
      name: 'stripe-error',
      builder: (context, state) => StripeError(),
    ),
    GoRoute(
      path: '/messages',
      builder: (context, state) => MessagePage(),
      name: 'messages',
    ),
    GoRoute(path: loginRoute, builder: (context, state) => LoginView()),
    GoRoute(
      path: registerRoute,
      builder: (context, state) => RegisterView(),
      routes: [
        GoRoute(path: 'info', builder: (context, state) => EndRegisterView()),
      ],
    ),
    GoRoute(
      path: confirmEmailRoute,
      builder: (context, state) => ConfirmEmailPage(),
      routes: [
        GoRoute(
          path: 'resend',
          builder: (context, state) => ResendEmailConfirmation(),
        ),
      ],
    ),
    GoRoute(
      path: resetPasswordRoute,
      builder: (context, state) => ResetPasswordRequestPage(),
    ),
    GoRoute(
      path: confirmResetPasswordRoute,
      builder: (context, state) => ConfirmResetPasswordPage(),
    ),
    GoRoute(
      path: postDetailRoute,
      builder: (context, state) {
        final postId = state.pathParameters['id'];
        final allPosts = state.extra as List<Post>?;

        // On crée une page intermédiaire pour isoler le chargement du post et éviter les problèmes de build
        return PostFullscreenView(initialPostId: postId!, allPosts: allPosts!);
      },
      redirect: (context, state) {
        return isAuthenticated(context, state);
      },
    ),
    GoRoute(
      path: postEdit,
      builder: (context, state) {
        final extraData = state.extra as Map<String, dynamic>?;
        return PostDetailsView(
          name: extraData?['name'],
          description: extraData?['description'],
          id: extraData?['id'],
          categories: extraData?['categories'],
          visibility: extraData?['visibility'],
          imageUrl: extraData?['imageUrl'],
          step: 'update',
        );
      },
      redirect: (context, state) {
        return isAuthenticated(context, state);
      },
    ),
    ShellRoute(
      builder: (context, state, child) {
        return AdminDashboardPage(child: child);
      },
      routes: [
        GoRoute(
          path: adminRoute,
          builder: (context, state) => const Center(child: Text('Dashboard')),
        ),
        GoRoute(
          path: '$adminRoute/dashboard',
          builder: (context, state) => const AdminKpiDashboard(),
        ),
        GoRoute(
          path: '$adminRoute/users',
          builder: (context, state) => const UsersManagement(),
        ),
        GoRoute(
          path: '$adminRoute/contacts',
          builder: (context, state) => const ContactManagement(),
        ),
        GoRoute(
          path: '$adminRoute/users-chart',
          builder: (context, state) => const UserStatsChart(),
        ),
        GoRoute(
          path: '$adminRoute/content-creator',
          builder: (context, state) => const AdminContentCreator(),
        ),
        GoRoute(
          path: '$adminRoute/kpi-dashboard',
          builder: (context, state) => const AdminKpiDashboard(),
        ),
        GoRoute(
          path: '$adminRoute/categories-management',
          builder: (context, state) => const CategoriesManagement(),
        ),
        GoRoute(
          path: '$adminRoute/statistics',
          builder: (context, state) => const StatisticsPage(),
        ),
        
      ],
    ),
  ],
  refreshListenable: UserNotifier(),
);
