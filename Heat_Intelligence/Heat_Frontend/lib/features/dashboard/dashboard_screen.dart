import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/heat_data.dart';
import '../../core/providers/heat_provider.dart';
import '../../core/providers/alert_provider.dart';
import '../../core/widgets/risk_badge.dart';
import '../../core/widgets/heat_card.dart';
import '../../core/widgets/loading_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatAsync = ref.watch(heatDataProvider);
    final historyAsync = ref.watch(heatHistoryProvider);
    final unreadCount = ref.watch(unreadAlertCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: heatAsync.when(
          loading: () => const DashboardLoadingWidget(),
          error: (err, _) => ErrorRetryWidget(
            message: err.toString(),
            onRetry: () => ref.invalidate(heatDataProvider),
          ),
          data: (heatData) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(heatDataProvider);
              ref.invalidate(heatHistoryProvider);
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: _buildHeader(context, heatData, unreadCount),
                ),

                // Risk badge card
                SliverToBoxAdapter(
                  child: _buildRiskSection(context, heatData),
                ),

                // Stats cards
                SliverToBoxAdapter(
                  child: _buildStatsRow(context, heatData),
                ),

                // Recommendations
                SliverToBoxAdapter(
                  child: _buildRecommendations(context, heatData),
                ),

                // 7-day trend chart
                SliverToBoxAdapter(
                  child: historyAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(20),
                      child: LoadingWidget(height: 220),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (history) =>
                        _buildTrendChart(context, history, isDark),
                  ),
                ),

                // Extra info cards
                SliverToBoxAdapter(
                  child: _buildExtraInfo(context, heatData),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, HeatData data, int unreadCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()} 👋',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.dashboard,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '📍 ${data.locationName}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.grey[500] : Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Notification bell
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.heatHigh,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildRiskSection(BuildContext context, HeatData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final riskColor = AppColors.getRiskColor(data.riskScore);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              riskColor.withValues(alpha: isDark ? 0.25 : 0.1),
              riskColor.withValues(alpha: isDark ? 0.1 : 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: riskColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            RiskBadge(riskScore: data.riskScore, size: 80),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data.riskEmoji} ${data.riskLabel}',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: riskColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Risk Score: ${(data.riskScore * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Risk progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: data.riskScore,
                      minHeight: 8,
                      backgroundColor: riskColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(riskColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildStatsRow(BuildContext context, HeatData data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: HeatCard(
              title: AppStrings.currentTemp,
              value: '${data.temperature.toStringAsFixed(1)}°C',
              icon: Icons.thermostat_rounded,
              iconColor: AppColors.heatHigh,
              subtitle: 'Feels like ${data.heatIndex.toStringAsFixed(1)}°C',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: HeatCard(
              title: 'Humidity',
              value: '${data.humidity.toStringAsFixed(0)}%',
              icon: Icons.water_drop_rounded,
              iconColor: AppColors.primary,
              subtitle: data.windSpeed != null
                  ? 'Wind: ${data.windSpeed!.toStringAsFixed(1)} km/h'
                  : null,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildRecommendations(BuildContext context, HeatData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tips = data.riskScore >= 0.75
        ? AppStrings.highRiskTips
        : data.riskScore >= 0.40
            ? AppStrings.moderateRiskTips
            : AppStrings.safeTips;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  AppStrings.recommendations,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    tip,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                )),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildTrendChart(
      BuildContext context, List<HeatData> history, bool isDark) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up_rounded,
                    color: AppColors.accent, size: 22),
                const SizedBox(width: 8),
                Text(
                  AppStrings.heatTrend,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.grey.withValues(alpha: 0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, _) => Text(
                          '${value.toInt()}°',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[500] : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          if (i < 0 || i >= history.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            DateFormat('E')
                                .format(history[i].timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isDark ? Colors.grey[500] : Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: history
                          .map((e) => e.temperature)
                          .reduce((a, b) => a < b ? a : b) -
                      3,
                  maxY: history
                          .map((e) => e.temperature)
                          .reduce((a, b) => a > b ? a : b) +
                      3,
                  lineBarsData: [
                    LineChartBarData(
                      spots: history
                          .asMap()
                          .entries
                          .map((e) => FlSpot(
                              e.key.toDouble(), e.value.temperature))
                          .toList(),
                      isCurved: true,
                      curveSmoothness: 0.3,
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.accent.withValues(alpha: 0.3),
                            AppColors.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, _, _) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.getRiskColor(
                            history[spot.x.toInt()].riskScore,
                          ),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final d = history[spot.x.toInt()];
                          return LineTooltipItem(
                            '${d.temperature.toStringAsFixed(1)}°C\nRisk: ${(d.riskScore * 100).toInt()}%',
                            GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildExtraInfo(BuildContext context, HeatData data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          if (data.uvIndex != null)
            Expanded(
              child: HeatCard(
                title: 'UV Index',
                value: data.uvIndex!.toStringAsFixed(1),
                icon: Icons.wb_sunny_rounded,
                iconColor: const Color(0xFFFFB300),
                subtitle: _getUvLabel(data.uvIndex!),
              ),
            ),
          if (data.uvIndex != null) const SizedBox(width: 12),
          Expanded(
            child: HeatCard(
              title: AppStrings.heatIndex,
              value: '${data.heatIndex.toStringAsFixed(1)}°C',
              icon: Icons.local_fire_department_rounded,
              iconColor: AppColors.accent,
              subtitle: 'Apparent temp',
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 500.ms).slideY(begin: 0.1);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getUvLabel(double uv) {
    if (uv >= 11) return 'Extreme';
    if (uv >= 8) return 'Very High';
    if (uv >= 6) return 'High';
    if (uv >= 3) return 'Moderate';
    return 'Low';
  }
}
