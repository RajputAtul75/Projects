import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/heat_data.dart';
import '../../core/providers/heat_provider.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/heat_card.dart';

class AreaAnalysisScreen extends ConsumerWidget {
  const AreaAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatAsync = ref.watch(heatDataProvider);
    final historyAsync = ref.watch(heatHistoryProvider);
    final predictionAsync = ref.watch(heatPredictionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: heatAsync.when(
          loading: () => const DashboardLoadingWidget(),
          error: (err, _) => ErrorRetryWidget(
            message: err.toString(),
            onRetry: () => ref.invalidate(heatDataProvider),
          ),
          data: (heatData) => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Area Analysis',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '📍 ${heatData.locationName} • ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? Colors.grey[500] : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
              ),

              // Current stats grid
              SliverToBoxAdapter(
                child: _buildStatsGrid(context, heatData),
              ),

              // Risk score gauge
              SliverToBoxAdapter(
                child: _buildRiskGauge(context, heatData, isDark),
              ),

              // Heat history
              SliverToBoxAdapter(
                child: historyAsync.when(
                  loading: () => const Padding(
                      padding: EdgeInsets.all(20),
                      child: LoadingWidget(height: 250)),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (history) =>
                      _buildHistoryChart(context, history, isDark),
                ),
              ),

              // AI Prediction
              SliverToBoxAdapter(
                child: predictionAsync.when(
                  loading: () => const Padding(
                      padding: EdgeInsets.all(20),
                      child: LoadingWidget(height: 250)),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (prediction) =>
                      _buildPredictionChart(context, prediction, isDark),
                ),
              ),

              // Risk breakdown
              SliverToBoxAdapter(
                child: _buildRiskBreakdown(context, heatData, isDark),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, HeatData data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: HeatCard(
                  title: 'Temperature',
                  value: '${data.temperature.toStringAsFixed(1)}°C',
                  icon: Icons.thermostat_rounded,
                  iconColor: AppColors.heatHigh,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HeatCard(
                  title: 'Heat Index',
                  value: '${data.heatIndex.toStringAsFixed(1)}°C',
                  icon: Icons.local_fire_department_rounded,
                  iconColor: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: HeatCard(
                  title: 'Humidity',
                  value: '${data.humidity.toStringAsFixed(0)}%',
                  icon: Icons.water_drop_rounded,
                  iconColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HeatCard(
                  title: 'Wind Speed',
                  value: '${data.windSpeed?.toStringAsFixed(1) ?? "N/A"} km/h',
                  icon: Icons.air_rounded,
                  iconColor: const Color(0xFF26A69A),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 500.ms);
  }

  Widget _buildRiskGauge(BuildContext context, HeatData data, bool isDark) {
    final riskColor = AppColors.getRiskColor(data.riskScore);
    final percentage = (data.riskScore * 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(24),
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
          children: [
            Row(
              children: [
                Icon(Icons.speed_rounded, color: riskColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Risk Assessment',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Circular gauge
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: data.riskScore,
                      strokeWidth: 12,
                      strokeCap: StrokeCap.round,
                      backgroundColor: riskColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(riskColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percentage%',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: riskColor,
                        ),
                      ),
                      Text(
                        data.riskLabel,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  Widget _buildHistoryChart(
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
                const Icon(Icons.history_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  '7-Day Temperature History',
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
              child: BarChart(
                BarChartData(
                  barGroups: history.asMap().entries.map((e) {
                    final color = AppColors.getRiskColor(e.value.riskScore);
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.temperature,
                          color: color,
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: 50,
                            color: color.withValues(alpha: 0.06),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}°',
                          style: TextStyle(
                              fontSize: 11,
                              color:
                                  isDark ? Colors.grey[500] : Colors.grey),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= history.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            DateFormat('E').format(history[i].timestamp),
                            style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms);
  }

  Widget _buildPredictionChart(
      BuildContext context, List<HeatData> predictions, bool isDark) {
    if (predictions.isEmpty) return const SizedBox.shrink();

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
                const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFF7C4DFF), size: 22),
                const SizedBox(width: 8),
                Text(
                  'AI Prediction (24h)',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'AI',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7C4DFF),
                    ),
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
                        reservedSize: 36,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}°',
                          style: TextStyle(
                              fontSize: 11,
                              color:
                                  isDark ? Colors.grey[500] : Colors.grey),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= predictions.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            DateFormat('HH:mm')
                                .format(predictions[i].timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  isDark ? Colors.grey[500] : Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: predictions
                          .asMap()
                          .entries
                          .map((e) => FlSpot(
                              e.key.toDouble(), e.value.temperature))
                          .toList(),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFFE040FB)],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dashArray: [8, 4],
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                            const Color(0xFFE040FB).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) =>
                            FlDotCirclePainter(
                          radius: 3.5,
                          color: const Color(0xFF7C4DFF),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms);
  }

  Widget _buildRiskBreakdown(
      BuildContext context, HeatData data, bool isDark) {
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
            Text(
              'Risk Factor Breakdown',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _riskFactor(
              'Temperature',
              ((data.temperature - 25) / 25).clamp(0.0, 1.0),
              Icons.thermostat_rounded,
              AppColors.heatHigh,
              isDark,
            ),
            const SizedBox(height: 14),
            _riskFactor(
              'Humidity',
              (data.humidity / 100),
              Icons.water_drop_rounded,
              AppColors.primary,
              isDark,
            ),
            if (data.uvIndex != null) ...[
              const SizedBox(height: 14),
              _riskFactor(
                'UV Index',
                (data.uvIndex! / 11).clamp(0.0, 1.0),
                Icons.wb_sunny_rounded,
                const Color(0xFFFFB300),
                isDark,
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 500.ms);
  }

  Widget _riskFactor(
      String label, double value, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(value * 100).toInt()}%',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
