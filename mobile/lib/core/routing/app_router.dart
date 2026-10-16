import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/about/about_atlas_screen.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/coordinator/audit_logs_screen.dart';
import '../../features/coordinator/coordinator_teams_screen.dart';
import '../../features/coordinator/coordinator_users_screen.dart';
import '../../features/coordinator/reports_screen.dart';
import '../../features/coordinator/semesters_screen.dart';
import '../../features/dashboard/coordinator_dashboard_screen.dart';
import '../../features/dashboard/student_dashboard_screen.dart';
import '../../features/dashboard/supervisor_dashboard_screen.dart';
import '../../features/defenses/defenses_screen.dart';
import '../../features/defenses/schedule_defense_screen.dart';
import '../../features/evaluations/evaluation_scoring_screen.dart';
import '../../features/evaluations/my_grade_screen.dart';
import '../../features/evaluations/rubrics_screen.dart';
import '../../features/milestones/create_milestone_screen.dart';
import '../../features/milestones/grade_submission_screen.dart';
import '../../features/milestones/milestones_screen.dart';
import '../../features/milestones/new_submission_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/proposals/proposal_review_screen.dart';
import '../../features/proposals/proposals_screen.dart';
import '../../features/proposals/submit_proposal_screen.dart';
import '../../features/supervisor/requests_inbox_screen.dart';
import '../../features/supervisor/supervised_teams_screen.dart';
import '../../features/teams/create_team_screen.dart';
import '../../features/teams/join_team_screen.dart';
import '../../features/teams/my_team_screen.dart';
import '../../features/teams/supervisor_request_screen.dart';
import '../../shared/models/user_model.dart';
import '../../shared/widgets/loading_indicator.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) {
        if (previous?.isAuthenticated != next.isAuthenticated ||
            previous?.isInitialized != next.isInitialized) {
          notifyListeners();
        }
      },
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);

      if (!authState.isInitialized) {
        return null; // Wait for initialization
      }

      final isAuthenticated = authState.isAuthenticated;
      final currentLoc = state.matchedLocation;

      final isAuthRoute = currentLoc == '/login' ||
          currentLoc == '/register' ||
          currentLoc == '/forgot-password';

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // Splash / Initialization Screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(
          body: Center(child: LoadingIndicator(message: 'Initializing ATLAS Suite...')),
        ),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Dynamic Role-Aware Dashboard Router
      GoRoute(
        path: '/dashboard',
        builder: (context, state) {
          final authState = ref.watch(authControllerProvider);
          final role = authState.user?.role ?? UserRole.student;
          if (role.isSupervisor) {
            return const SupervisorDashboardScreen();
          } else if (role.isCoordinator) {
            return const CoordinatorDashboardScreen();
          }
          return const StudentDashboardScreen();
        },
      ),

      // Student Team Routes
      GoRoute(
        path: '/teams/my-team',
        builder: (context, state) => const MyTeamScreen(),
      ),
      GoRoute(
        path: '/teams/create',
        builder: (context, state) => const CreateTeamScreen(),
      ),
      GoRoute(
        path: '/teams/join',
        builder: (context, state) => const JoinTeamScreen(),
      ),
      GoRoute(
        path: '/teams/request-supervisor',
        builder: (context, state) {
          final teamId = state.extra as String? ?? '';
          return SupervisorRequestScreen(teamId: teamId);
        },
      ),

      // Supervisor Routes
      GoRoute(
        path: '/supervisor/requests',
        builder: (context, state) => const RequestsInboxScreen(),
      ),
      GoRoute(
        path: '/supervisor/teams',
        builder: (context, state) => const SupervisedTeamsScreen(),
      ),

      // Proposals Routes
      GoRoute(
        path: '/proposals',
        builder: (context, state) {
          final teamId = state.extra as String?;
          return ProposalsScreen(teamId: teamId);
        },
      ),
      GoRoute(
        path: '/proposals/submit',
        builder: (context, state) {
          final teamId = state.extra as String? ?? '';
          return SubmitProposalScreen(teamId: teamId);
        },
      ),
      GoRoute(
        path: '/proposals/review/:id',
        builder: (context, state) {
          final proposalId = state.pathParameters['id'] ?? '';
          return ProposalReviewScreen(proposalId: proposalId);
        },
      ),

      // Milestones & Deliverables Routes
      GoRoute(
        path: '/milestones',
        builder: (context, state) {
          final teamId = state.extra as String?;
          return MilestonesScreen(teamId: teamId);
        },
      ),
      GoRoute(
        path: '/milestones/submit',
        builder: (context, state) {
          final map = state.extra as Map<String, dynamic>? ?? {};
          return NewSubmissionScreen(
            milestoneId: map['milestone_id'] as String? ?? '',
            teamId: map['team_id'] as String? ?? '',
            milestoneTitle: map['milestone_title'] as String? ?? 'Milestone',
          );
        },
      ),
      GoRoute(
        path: '/milestones/grade',
        builder: (context, state) {
          final map = state.extra as Map<String, dynamic>? ?? {};
          return GradeSubmissionScreen(
            submissionId: map['submission_id'] as String? ?? '',
            submissionTitle: map['title'] as String? ?? 'Deliverable',
            maxScore: (map['max_score'] as num?)?.toDouble() ?? 100.0,
          );
        },
      ),
      GoRoute(
        path: '/milestones/create',
        builder: (context, state) => const CreateMilestoneScreen(),
      ),

      // Oral Defenses Routes
      GoRoute(
        path: '/defenses',
        builder: (context, state) => const DefensesScreen(),
      ),
      GoRoute(
        path: '/defenses/schedule',
        builder: (context, state) => const ScheduleDefenseScreen(),
      ),

      // Evaluations & Rubrics Routes
      GoRoute(
        path: '/evaluations/rubrics',
        builder: (context, state) => const RubricsScreen(),
      ),
      GoRoute(
        path: '/evaluations/score',
        builder: (context, state) {
          final map = state.extra as Map<String, dynamic>? ?? {};
          return EvaluationScoringScreen(
            teamId: map['team_id'] as String? ?? '',
            teamName: map['team_name'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/grades',
        builder: (context, state) => const MyGradeScreen(),
      ),

      // Notifications Route
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Coordinator Administration Routes
      GoRoute(
        path: '/coordinator/teams',
        builder: (context, state) => const CoordinatorTeamsScreen(),
      ),
      GoRoute(
        path: '/coordinator/users',
        builder: (context, state) => const CoordinatorUsersScreen(),
      ),
      GoRoute(
        path: '/coordinator/semesters',
        builder: (context, state) => const SemestersScreen(),
      ),
      GoRoute(
        path: '/coordinator/audit-logs',
        builder: (context, state) => const AuditLogsScreen(),
      ),
      GoRoute(
        path: '/coordinator/reports',
        builder: (context, state) => const ReportsScreen(),
      ),

      // Profile Route
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // About ATLAS Dedicated Route
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutAtlasScreen(),
      ),
    ],
  );
});
