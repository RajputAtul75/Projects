import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Animated risk badge widget
class RiskBadge extends StatelessWidget {
  final double riskScore;
  final double size;
  final bool showLabel;

  const RiskBadge({
    super.key,
    required this.riskScore,
    this.size = 72,
    this.showLabel = true,
  });

  String get _label {
    if (riskScore >= 0.75) return 'HIGH';
    if (riskScore >= 0.40) return 'MODERATE';
    return 'SAFE';
  }

  String get _emoji {
    if (riskScore >= 0.75) return '🔴';
    if (riskScore >= 0.40) return '🟡';
    return '🟢';
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getRiskColor(riskScore);
    final bgColor = AppColors.getRiskBackgroundColor(riskScore);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(color: color, width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              _emoji,
              style: TextStyle(fontSize: size * 0.4),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
