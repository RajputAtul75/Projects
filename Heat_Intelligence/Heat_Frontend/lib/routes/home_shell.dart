import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/providers/alert_provider.dart';

/// Home shell with animated bottom navigation bar
class HomeShell extends ConsumerStatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  static const List<String> _routes = [
    '/home',
    '/map',
    '/analysis',
    '/alerts',
    '/settings',
  ];

  void _onTap(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
      context.go(_routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = ref.watch(unreadAlertCountProvider);

    // Sync index based on current route
    final location = GoRouterState.of(context).uri.path;
    final routeIndex = _routes.indexOf(location);
    if (routeIndex != -1 && routeIndex != _currentIndex) {
      _currentIndex = routeIndex;
    }

    return Scaffold(
      body: widget.child,
      extendBody: true,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.dashboard_rounded,
                      Icons.dashboard_outlined, 'Home', isDark),
                  _buildNavItem(
                      1, Icons.map_rounded, Icons.map_outlined, 'Map', isDark),
                  _buildNavItem(2, Icons.analytics_rounded,
                      Icons.analytics_outlined, 'Analysis', isDark),
                  _buildNavItem(
                    3,
                    Icons.notifications_rounded,
                    Icons.notifications_outlined,
                    'Alerts',
                    isDark,
                    badge: unreadCount > 0 ? unreadCount : null,
                  ),
                  _buildNavItem(4, Icons.settings_rounded,
                      Icons.settings_outlined, 'Settings', isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    bool isDark, {
    int? badge,
  }) {
    final isActive = _currentIndex == index;
    final color = isActive
        ? AppColors.primary
        : (isDark ? Colors.grey[600]! : Colors.grey[500]!);

    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: isActive
            ? BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  isActive ? activeIcon : inactiveIcon,
                  color: color,
                  size: 24,
                ),
                if (badge != null)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.heatHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$badge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
