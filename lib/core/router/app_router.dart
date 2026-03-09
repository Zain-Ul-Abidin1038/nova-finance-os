import 'package:go_router/go_router.dart';
import 'package:nova_finance_os/features/home/presentation/home_screen.dart';
import 'package:nova_finance_os/features/receipts/presentation/camera_screen.dart';
import 'package:nova_finance_os/features/voice/presentation/voice_screen.dart';
import 'package:nova_finance_os/features/location/presentation/location_screen.dart';
import 'package:nova_finance_os/features/calendar/presentation/calendar_screen.dart';
import 'package:nova_finance_os/features/chat/presentation/intelligent_chat_screen.dart';
import 'package:nova_finance_os/features/auth/presentation/glassmorphic_auth_screen.dart';
import 'package:nova_finance_os/features/analytics/presentation/analytics_screen.dart';
import 'package:nova_finance_os/features/profile/presentation/profile_screen.dart';
import 'package:nova_finance_os/features/profile/presentation/edit_profile_screen.dart';
import 'package:nova_finance_os/features/nova_test/presentation/nova_test_screen.dart';
import 'package:nova_finance_os/features/marathon/presentation/marathon_screen.dart';
import 'package:nova_finance_os/features/finance/presentation/income_screen.dart';
import 'package:nova_finance_os/features/finance/presentation/expense_screen.dart';
import 'package:nova_finance_os/features/finance/presentation/ledger_screen.dart';
import 'package:nova_finance_os/features/vision_nova/presentation/vision_nova_screen.dart';
import 'package:nova_finance_os/features/nova_navigator/presentation/nova_navigator_screen.dart';
import 'package:nova_finance_os/features/currency/presentation/currency_converter_screen.dart';
import 'package:nova_finance_os/features/investments/presentation/portfolio_screen.dart';
import 'package:nova_finance_os/features/features_hub/presentation/features_hub_screen.dart';
import 'package:nova_finance_os/features/crypto/presentation/crypto_dashboard_screen.dart';
import 'package:nova_finance_os/features/real_estate/presentation/property_portfolio_screen.dart';
import 'package:nova_finance_os/features/insurance/presentation/insurance_dashboard_screen.dart';
import 'package:nova_finance_os/features/family/presentation/family_dashboard_screen.dart';
import 'package:nova_finance_os/features/shared_goals/presentation/shared_goals_screen.dart';
import 'package:nova_finance_os/features/group_expenses/presentation/group_expenses_screen.dart';
import 'package:nova_finance_os/features/enterprise/business/presentation/business_expenses_screen.dart';
import 'package:nova_finance_os/features/enterprise/collaboration/presentation/team_workspace_screen.dart';
import 'package:nova_finance_os/features/enterprise/reporting/presentation/reports_screen.dart';
import 'package:nova_finance_os/features/enterprise/api/presentation/api_management_screen.dart';
import 'package:nova_finance_os/features/enterprise/white_label/presentation/white_label_screen.dart';
import 'package:nova_finance_os/features/advisors/presentation/advisor_marketplace_screen.dart';
import 'package:nova_finance_os/features/community/presentation/community_insights_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/auth',
  routes: [
    GoRoute(
      path: '/nova-test',
      builder: (context, state) => const NovaTestScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const GlassmorphicAuthScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/camera',
      builder: (context, state) => const CameraScreen(),
    ),
    GoRoute(
      path: '/voice',
      builder: (context, state) => const VoiceScreen(),
    ),
    GoRoute(
      path: '/location',
      builder: (context, state) => const LocationScreen(),
    ),
    GoRoute(
      path: '/calendar',
      builder: (context, state) => const CalendarScreen(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) => const IntelligentChatScreen(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const AnalyticsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/marathon',
      builder: (context, state) => const MarathonScreen(),
    ),
    GoRoute(
      path: '/income',
      builder: (context, state) => const IncomeScreen(),
    ),
    GoRoute(
      path: '/expense',
      builder: (context, state) => const ExpenseScreen(),
    ),
    GoRoute(
      path: '/ledger',
      builder: (context, state) => const LedgerScreen(),
    ),
    GoRoute(
      path: '/vision-nova',
      builder: (context, state) => const VisionNovaScreen(),
    ),
    GoRoute(
      path: '/nova-navigator',
      builder: (context, state) => const NovaNavigatorScreen(),
    ),
    GoRoute(
      path: '/currency-converter',
      builder: (context, state) => const CurrencyConverterScreen(),
    ),
    GoRoute(
      path: '/portfolio',
      builder: (context, state) => const PortfolioScreen(),
    ),
    GoRoute(
      path: '/features-hub',
      builder: (context, state) => const FeaturesHubScreen(),
    ),
    GoRoute(
      path: '/crypto',
      builder: (context, state) => const CryptoDashboardScreen(),
    ),
    GoRoute(
      path: '/real-estate',
      builder: (context, state) => const PropertyPortfolioScreen(),
    ),
    GoRoute(
      path: '/insurance',
      builder: (context, state) => const InsuranceDashboardScreen(),
    ),
    GoRoute(
      path: '/family',
      builder: (context, state) => const FamilyDashboardScreen(),
    ),
    GoRoute(
      path: '/shared-goals',
      builder: (context, state) => const SharedGoalsScreen(),
    ),
    GoRoute(
      path: '/group-expenses',
      builder: (context, state) => const GroupExpensesScreen(),
    ),
    GoRoute(
      path: '/business-expenses',
      builder: (context, state) => const BusinessExpensesScreen(),
    ),
    GoRoute(
      path: '/teams',
      builder: (context, state) => const TeamWorkspaceScreen(),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: '/api-management',
      builder: (context, state) => const ApiManagementScreen(),
    ),
    GoRoute(
      path: '/white-label',
      builder: (context, state) => const WhiteLabelScreen(),
    ),
    GoRoute(
      path: '/advisors',
      builder: (context, state) => const AdvisorMarketplaceScreen(),
    ),
    GoRoute(
      path: '/community',
      builder: (context, state) => const CommunityInsightsScreen(),
    ),
  ],
);
