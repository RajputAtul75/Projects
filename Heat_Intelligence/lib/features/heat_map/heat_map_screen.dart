import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/heat_zone.dart';
import '../../core/providers/heat_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/widgets/loading_widget.dart';

class HeatMapScreen extends ConsumerStatefulWidget {
  const HeatMapScreen({super.key});

  @override
  ConsumerState<HeatMapScreen> createState() => _HeatMapScreenState();
}

class _HeatMapScreenState extends ConsumerState<HeatMapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  MapType _mapType = MapType.normal;
  bool _showLegend = true;

  @override
  Widget build(BuildContext context) {
    final positionAsync = ref.watch(currentPositionProvider);
    final zonesAsync = ref.watch(heatZonesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: positionAsync.when(
        loading: () => const Center(child: DashboardLoadingWidget()),
        error: (err, _) => ErrorRetryWidget(
          message: err.toString(),
          onRetry: () => ref.invalidate(currentPositionProvider),
        ),
        data: (position) {
          final userLatLng =
              LatLng(position.latitude, position.longitude);

          return Stack(
            children: [
              // Google Map
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: userLatLng,
                  zoom: 13.5,
                ),
                onMapCreated: (controller) {
                  if (!_mapController.isCompleted) {
                    _mapController.complete(controller);
                  }
                  if (isDark) {
                    controller.setMapStyle(_darkMapStyle);
                  }
                },
                mapType: _mapType,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: true,
                circles: zonesAsync.when(
                  data: (zones) => _buildCircles(zones),
                  loading: () => {},
                  error: (_, __) => {},
                ),
                markers: zonesAsync.when(
                  data: (zones) => _buildMarkers(zones),
                  loading: () => {},
                  error: (_, __) => {},
                ),
              ),

              // Top bar overlay
              _buildTopBar(context, isDark),

              // Legend
              if (_showLegend)
                Positioned(
                  left: 16,
                  bottom: 100,
                  child: _buildLegend(isDark),
                ),

              // Map controls
              Positioned(
                right: 16,
                bottom: 100,
                child: _buildMapControls(isDark, userLatLng),
              ),

              // Selected zone info
              zonesAsync.when(
                data: (zones) => zones.isNotEmpty
                    ? Positioned(
                        left: 16,
                        right: 16,
                        bottom: 24,
                        child: _buildZoneInfo(zones.first, isDark),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2C2C2C).withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.map_rounded,
                color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Text(
              'Live Heat Map',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            // Map type toggle
            GestureDetector(
              onTap: () {
                setState(() {
                  _mapType = _mapType == MapType.normal
                      ? MapType.satellite
                      : MapType.normal;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _mapType == MapType.normal
                      ? Icons.satellite_alt_rounded
                      : Icons.map_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3),
    );
  }

  Widget _buildLegend(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2C2C2C).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Risk Zones',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _legendItem('High Risk', AppColors.heatHigh),
          _legendItem('Moderate', AppColors.heatModerate),
          _legendItem('Safe', AppColors.heatSafe),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControls(bool isDark, LatLng userLatLng) {
    return Column(
      children: [
        _mapControlButton(
          icon: Icons.add,
          isDark: isDark,
          onTap: () async {
            final controller = await _mapController.future;
            controller.animateCamera(CameraUpdate.zoomIn());
          },
        ),
        const SizedBox(height: 8),
        _mapControlButton(
          icon: Icons.remove,
          isDark: isDark,
          onTap: () async {
            final controller = await _mapController.future;
            controller.animateCamera(CameraUpdate.zoomOut());
          },
        ),
        const SizedBox(height: 8),
        _mapControlButton(
          icon: Icons.my_location_rounded,
          isDark: isDark,
          color: AppColors.primary,
          onTap: () async {
            final controller = await _mapController.future;
            controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: userLatLng, zoom: 14),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _mapControlButton(
          icon: _showLegend ? Icons.layers_clear : Icons.layers_rounded,
          isDark: isDark,
          onTap: () => setState(() => _showLegend = !_showLegend),
        ),
      ],
    );
  }

  Widget _mapControlButton({
    required IconData icon,
    required bool isDark,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2C2C2C).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color ?? (isDark ? Colors.white70 : Colors.grey[700]),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildZoneInfo(HeatZone zone, bool isDark) {
    final riskColor = AppColors.getRiskColor(zone.riskScore);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2C2C2C).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: riskColor.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.location_on, color: riskColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  zone.name,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${zone.temperature.toStringAsFixed(1)}°C • Risk: ${(zone.riskScore * 100).toInt()}%',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: riskColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              zone.riskScore >= 0.75
                  ? 'HIGH'
                  : zone.riskScore >= 0.40
                      ? 'MOD'
                      : 'SAFE',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3);
  }

  Set<Circle> _buildCircles(List<HeatZone> zones) {
    return zones.map((zone) {
      final color = AppColors.getRiskColor(zone.riskScore);
      return Circle(
        circleId: CircleId(zone.id),
        center: LatLng(zone.latitude, zone.longitude),
        radius: zone.radius,
        fillColor: color.withValues(alpha: 0.2),
        strokeColor: color.withValues(alpha: 0.6),
        strokeWidth: 2,
      );
    }).toSet();
  }

  Set<Marker> _buildMarkers(List<HeatZone> zones) {
    return zones.map((zone) {
      return Marker(
        markerId: MarkerId(zone.id),
        position: LatLng(zone.latitude, zone.longitude),
        infoWindow: InfoWindow(
          title: zone.name,
          snippet:
              '${zone.temperature.toStringAsFixed(1)}°C | Risk: ${(zone.riskScore * 100).toInt()}%',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          zone.riskScore >= 0.75
              ? BitmapDescriptor.hueRed
              : zone.riskScore >= 0.40
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueGreen,
        ),
      );
    }).toSet();
  }

  static const String _darkMapStyle = '''
  [
    {"elementType":"geometry","stylers":[{"color":"#242f3e"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},
    {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#38414e"}]},
    {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212a37"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263c"}]}
  ]
  ''';
}
