import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_live_nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_live_nova_finance_os/core/theme/glass_widgets.dart';

class FeaturesHubScreen extends StatelessWidget {
  const FeaturesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'All Features',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildPhaseSection(
                    context,
                    'Phase 3: Advanced Features',
                    AppColors.neonTeal,
                    [
                      _FeatureItem('Multi-Currency', Icons.currency_exchange, '/currency-converter'),
                      _FeatureItem('Investment Portfolio', Icons.trending_up, '/portfolio'),
                      _FeatureItem('Crypto Tracking', Icons.currency_bitcoin, '/crypto'),
                      _FeatureItem('Real Estate', Icons.home, '/real-estate'),
                      _FeatureItem('Insurance', Icons.shield, '/insurance'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildPhaseSection(
                    context,
                    'Phase 4: Social Features',
                    AppColors.softPurple,
                    [
                      _FeatureItem('Family Planning', Icons.family_restroom, '/family'),
                      _FeatureItem('Shared Goals', Icons.flag, '/shared-goals'),
                      _FeatureItem('Group Expenses', Icons.group, '/group-expenses'),
                      _FeatureItem('Advisor Marketplace', Icons.person_search, '/advisors'),
                      _FeatureItem('Community', Icons.forum, '/community'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildPhaseSection(
                    context,
                    'Phase 5: Enterprise',
                    AppColors.success,
                    [
                      _FeatureItem('Business Expenses', Icons.business_center, '/business-expenses'),
                      _FeatureItem('Team Collaboration', Icons.groups, '/teams'),
                      _FeatureItem('Advanced Reports', Icons.analytics, '/reports'),
                      _FeatureItem('API Management', Icons.api, '/api-management'),
                      _FeatureItem('White Label', Icons.branding_watermark, '/white-label'),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseSection(
    BuildContext context,
    String title,
    Color accentColor,
    List<_FeatureItem> features,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: accentColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderColor: accentColor.withOpacity(0.3),
            child: InkWell(
              onTap: () {
                // Enable all routes now
                context.push(feature.route);
              },
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(feature.icon, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      feature.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }

  void _showComingSoonDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Row(
          children: [
            const Icon(Icons.construction, color: AppColors.neonTeal),
            const SizedBox(width: 12),
            const Text(
              'Coming Soon',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Text(
          '$featureName is currently under development and will be available soon!',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(color: AppColors.neonTeal),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final String name;
  final IconData icon;
  final String route;

  _FeatureItem(this.name, this.icon, this.route);
}
