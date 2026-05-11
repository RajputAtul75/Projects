import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _backgroundLocation = false;
  double _alertThreshold = 0.75;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  AppStrings.settings,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms),
            ),

            // Profile card
            SliverToBoxAdapter(
              child: _buildProfileCard(isDark),
            ),

            // Appearance section
            SliverToBoxAdapter(
              child: _buildSectionTitle('Appearance', isDark),
            ),
            SliverToBoxAdapter(
              child: _buildSettingsTile(
                icon: Icons.dark_mode_rounded,
                iconColor: const Color(0xFF7C4DFF),
                title: AppStrings.darkMode,
                subtitle: isDark ? 'Dark mode is on' : 'Light mode is on',
                isDark: isDark,
                trailing: Switch.adaptive(
                  value: isDark,
                  onChanged: (val) {
                    ref.read(themeProvider.notifier).setDark(val);
                  },
                  activeTrackColor: AppColors.primary,
                ),
              ),
            ),

            // Notifications
            SliverToBoxAdapter(
              child: _buildSectionTitle('Notifications', isDark),
            ),
            SliverToBoxAdapter(
              child: _buildSettingsTile(
                icon: Icons.notifications_active_rounded,
                iconColor: AppColors.accent,
                title: AppStrings.notifications,
                subtitle: _notificationsEnabled ? 'Enabled' : 'Disabled',
                isDark: isDark,
                trailing: Switch.adaptive(
                  value: _notificationsEnabled,
                  onChanged: (val) =>
                      setState(() => _notificationsEnabled = val),
                  activeTrackColor: AppColors.primary,
                ),
              ),
            ),

            // Alert threshold slider
            SliverToBoxAdapter(
              child: _buildThresholdSlider(isDark),
            ),

            // Location
            SliverToBoxAdapter(
              child: _buildSectionTitle('Location', isDark),
            ),
            SliverToBoxAdapter(
              child: _buildSettingsTile(
                icon: Icons.location_on_rounded,
                iconColor: AppColors.heatSafe,
                title: AppStrings.locationTracking,
                subtitle: _backgroundLocation
                    ? 'Active — monitoring heat zones'
                    : 'Disabled',
                isDark: isDark,
                trailing: Switch.adaptive(
                  value: _backgroundLocation,
                  onChanged: (val) =>
                      setState(() => _backgroundLocation = val),
                  activeTrackColor: AppColors.primary,
                ),
              ),
            ),

            // About section
            SliverToBoxAdapter(
              child: _buildSectionTitle('About', isDark),
            ),
            SliverToBoxAdapter(
              child: _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.primary,
                title: 'Heat Intelligence',
                subtitle: AppStrings.version,
                isDark: isDark,
                onTap: () => _showAboutDialog(context, isDark),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSettingsTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: const Color(0xFFFF7043),
                title: 'Privacy Policy',
                subtitle: 'How we handle your data',
                isDark: isDark,
                onTap: () {},
              ),
            ),
            SliverToBoxAdapter(
              child: _buildSettingsTile(
                icon: Icons.mail_outline_rounded,
                iconColor: const Color(0xFF26A69A),
                title: 'Support',
                subtitle: 'Contact us for help',
                isDark: isDark,
                onTap: () {},
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.whatshot_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Heat Intelligence',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Urban Heat Island Detection',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'PRO',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 500.ms);
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey[500] : Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThresholdSlider(bool isDark) {
    final color = AppColors.getRiskColor(_alertThreshold);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.tune_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.alertThreshold,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color:
                              isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Alert when risk ≥ ${(_alertThreshold * 100).toInt()}%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(_alertThreshold * 100).toInt()}%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: _alertThreshold,
              min: 0.2,
              max: 0.95,
              divisions: 15,
              activeColor: color,
              inactiveColor: color.withValues(alpha: 0.2),
              onChanged: (val) => setState(() => _alertThreshold = val),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.whatshot_rounded,
                color: AppColors.primary, size: 28),
            const SizedBox(width: 10),
            Text(
              'Heat Intelligence',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Heat Detection Intelligence (HDI) helps users detect, visualize, and get alerts about urban heat islands using real-time temperature data, GPS location, and ML-based heat risk scoring.\n\n${AppStrings.version}',
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.6,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
