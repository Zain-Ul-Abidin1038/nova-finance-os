import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_finance_os/core/theme/app_colors.dart';
import 'package:nova_finance_os/core/theme/glass_widgets.dart';
import 'package:nova_finance_os/core/theme/theme_provider.dart';
import 'package:nova_finance_os/features/profile/services/profile_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final textColor = isDark ? AppColors.textPrimary : LightColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.textSecondary : LightColors.textSecondary;
    final profile = ref.watch(profileServiceProvider);
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.background : LightColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: textColor),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Profile',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Profile Header
                  _buildProfileHeader(context, profile, textColor, secondaryTextColor, isDark),
                  const SizedBox(height: 32),

                  // Account Section
                  _buildSectionLabel('ACCOUNT', secondaryTextColor),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'Personal Information',
                    subtitle: 'Update your details',
                    onTap: () => context.push('/profile/edit'),
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    isDark: isDark,
                  ),
                  _buildMenuItem(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    subtitle: profile.email,
                    onTap: () => context.push('/profile/edit'),
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    isDark: isDark,
                  ),
                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Change password coming soon')),
                      );
                    },
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 32),

                  // Preferences Section
                  _buildSectionLabel('PREFERENCES', secondaryTextColor),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Manage notification settings',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications coming soon')),
                      );
                    },
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    isDark: isDark,
                  ),
                  _buildMenuItem(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    subtitle: 'English (US)',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Language settings coming soon')),
                      );
                    },
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    isDark: isDark,
                  ),
                  _buildThemeToggle(ref, isDark, textColor, secondaryTextColor),

                  const SizedBox(height: 32),

                  // Data Section
                  _buildSectionLabel('DATA & PRIVACY', secondaryTextColor),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    icon: Icons.cloud_sync_outlined,
                    title: 'Sync Settings',
                    subtitle: 'Manage cloud sync',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sync settings coming soon')),
                      );
                    },
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    isDark: isDark,
                  ),
                  _buildMenuItem(
                    icon: Icons.download_outlined,
                    title: 'Export Data',
                    subtitle: 'Download your data',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Export data coming soon')),
                      );
                    },
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    isDark: isDark,
                  ),
                  _buildMenuItem(
                    icon: Icons.delete_outline,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Delete account coming soon')),
                      );
                    },
                    isDestructive: true,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 32),

                  // About Section
                  _buildSectionLabel('ABOUT', secondaryTextColor),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    title: 'App Version',
                    subtitle: '1.0.0',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Finance OS v1.0.0')),
                      );
                    },
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    isDark: isDark,
                  ),
                  _buildMenuItem(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    subtitle: 'Read our terms',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Terms of Service coming soon')),
                      );
                    },
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    isDark: isDark,
                  ),
                  _buildMenuItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'How we protect your data',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy Policy coming soon')),
                      );
                    },
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 32),

                  // Logout Button
                  _buildLogoutButton(context, isDark, textColor, secondaryTextColor),

                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserProfile profile, Color textColor, Color secondaryTextColor, bool isDark) {
    final accentColor = isDark ? AppColors.neonTeal : LightColors.neonTeal;
    final secondaryAccent = isDark ? AppColors.softPurple : LightColors.softPurple;
    
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Profile Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentColor, width: 3),
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0.2),
                  secondaryAccent.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: Icon(
              Icons.person,
              size: 50,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            profile.name,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            profile.email,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Edit Profile Button
          ElevatedButton.icon(
            onPressed: () => context.push('/profile/edit'),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, Color secondaryTextColor) {
    return Text(
      text,
      style: TextStyle(
        color: secondaryTextColor.withValues(alpha: 0.6),
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.8,
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color textColor,
    required Color secondaryTextColor,
    required bool isDark,
    bool isDestructive = false,
  }) {
    final accentColor = isDark ? AppColors.neonTeal : LightColors.neonTeal;
    final errorColor = isDark ? AppColors.error : LightColors.error;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 16,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? errorColor.withValues(alpha: 0.15)
                        : accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive ? errorColor : accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDestructive ? errorColor : textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: secondaryTextColor.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isDark, Color textColor, Color secondaryTextColor) {
    final errorColor = isDark ? AppColors.error : LightColors.error;
    final surfaceColor = isDark ? AppColors.surfaceDark : LightColors.surface;
    
    return GlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          // Show logout confirmation
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: surfaceColor,
              title: Text(
                'Logout',
                style: TextStyle(color: textColor),
              ),
              content: Text(
                'Are you sure you want to logout?',
                style: TextStyle(color: secondaryTextColor),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/auth');
                  },
                  child: Text(
                    'Logout',
                    style: TextStyle(color: errorColor),
                  ),
                ),
              ],
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: errorColor),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  color: errorColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(WidgetRef ref, bool isDark, Color textColor, Color secondaryTextColor) {
    final accentColor = isDark ? AppColors.neonTeal : LightColors.neonTeal;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderRadius: 16,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDark ? 'Dark mode' : 'Light mode',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isDark,
                onChanged: (value) {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
                activeThumbColor: accentColor,
                activeTrackColor: accentColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
