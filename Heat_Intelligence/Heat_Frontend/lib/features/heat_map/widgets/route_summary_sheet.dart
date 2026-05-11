import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/route_segment.dart';
import '../../../core/constants/app_colors.dart';

class RouteSummarySheet extends StatelessWidget {
  final List<RouteSegment> segments;
  

  const RouteSummarySheet({super.key, required this.segments});

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();

    double totalDistance = segments.fold(0.0, (sum, s) => sum + s.distance);
    double maxHeat = segments.fold(0.0, (max, s) => s.heatScore > max ? s.heatScore : max);
    
    final color = AppColors.getRiskColor(maxHeat / 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Route Summary', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoTile('Distance', '${(totalDistance / 1000).toStringAsFixed(2)} km', Icons.directions_walk),
              _infoTile('Max Risk', '${maxHeat.toStringAsFixed(0)} / 100', Icons.thermostat, color: color),
              _infoTile('Est. Time', '${(totalDistance / 80).toStringAsFixed(0)} min', Icons.timer),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _infoTile(String title, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppColors.primary, size: 28),
        const SizedBox(height: 8),
        Text(title, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
        Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
