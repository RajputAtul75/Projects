import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/heat_zone.dart';
import '../../core/providers/heat_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/services/location_service.dart';
import '../../core/widgets/loading_widget.dart';

class HeatMapScreen extends ConsumerStatefulWidget {
  const HeatMapScreen({super.key});

  @override
  ConsumerState<HeatMapScreen> createState() => _HeatMapScreenState();
}

class _HeatMapScreenState extends ConsumerState<HeatMapScreen> {
  final MapController _mapController = MapController();
  double _zoom = 13.5;
  bool _useSatelliteTiles = false;
  bool _showLegend = true;
  LatLng? _lastMapCenter;

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(activeCityLocationProvider);
    final zonesAsync = ref.watch(heatZonesProvider);
    final selectedCity = ref.watch(selectedCityProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: locationAsync.when(
        loading: () => const Center(child: DashboardLoadingWidget()),
        error: (err, _) => ErrorRetryWidget(
          message: err.toString(),
          onRetry: () => ref.invalidate(activeCityLocationProvider),
        ),
        data: (activeLocation) {
          final userLatLng = LatLng(
            activeLocation.latitude,
            activeLocation.longitude,
          );

          if (_lastMapCenter == null ||
              (_lastMapCenter!.latitude - userLatLng.latitude).abs() >
                      0.0001 ||
              (_lastMapCenter!.longitude - userLatLng.longitude).abs() >
                      0.0001) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(userLatLng, _zoom);
            });
            _lastMapCenter = userLatLng;
          }

          final zones = zonesAsync.maybeWhen(
            data: (data) => data,
            orElse: () => const <HeatZone>[],
          );

          return Stack(
            children: [
              // Leaflet map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: userLatLng,
                  initialZoom: _zoom,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.doubleTapZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: _tileUrlTemplate(isDark),
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.hdi.heat_intelligence',
                  ),
                  CircleLayer(circles: _buildCircles(zones)),
                  MarkerLayer(markers: _buildMarkers(zones, userLatLng)),
                ],
              ),

              // Top bar overlay
              _buildTopBar(
                context,
                isDark,
                selectedCity?.name ?? 'Current Location',
                onSearchCity: _onSearchCity,
                onUseCurrentLocation: _onUseCurrentLocation,
              ),

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
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onSearchCity() async {
    final controller = TextEditingController();

    final query = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          title: Text(
            'Search City',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter city name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => Navigator.of(ctx).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Search'),
            ),
          ],
        );
      },
    );

    if (!mounted || query == null || query.isEmpty) {
      return;
    }

    try {
      final locationService = ref.read(locationServiceProvider);
      final city = await locationService.searchCity(query);
      if (!mounted) return;
      ref.read(selectedCityProvider.notifier).state = city;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Showing heat zones for ${city.name}')),
      );
    } on LocationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find that city.')),
      );
    }
  }

  void _onUseCurrentLocation() {
    ref.read(selectedCityProvider.notifier).state = null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Using your current location')),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    bool isDark,
    String locationLabel, {
    required VoidCallback onSearchCity,
    required VoidCallback onUseCurrentLocation,
  }) {
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
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                locationLabel,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            GestureDetector(
              onTap: onUseCurrentLocation,
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
            GestureDetector(
              onTap: onSearchCity,
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
            // Map type toggle
            GestureDetector(
              onTap: () {
                setState(() => _useSatelliteTiles = !_useSatelliteTiles);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  !_useSatelliteTiles
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
          onTap: () {
            setState(() => _zoom = (_zoom + 1).clamp(4, 18));
            _mapController.move(_mapController.camera.center, _zoom);
          },
        ),
        const SizedBox(height: 8),
        _mapControlButton(
          icon: Icons.remove,
          isDark: isDark,
          onTap: () {
            setState(() => _zoom = (_zoom - 1).clamp(4, 18));
            _mapController.move(_mapController.camera.center, _zoom);
          },
        ),
        const SizedBox(height: 8),
        _mapControlButton(
          icon: Icons.my_location_rounded,
          isDark: isDark,
          color: AppColors.primary,
          onTap: () {
            setState(() => _zoom = 14);
            _mapController.move(userLatLng, _zoom);
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

  String _tileUrlTemplate(bool isDark) {
    if (_useSatelliteTiles) {
      return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
    if (isDark) {
      return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
    }
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  List<CircleMarker> _buildCircles(List<HeatZone> zones) {
    return zones.map((zone) {
      final color = AppColors.getRiskColor(zone.riskScore);
      return CircleMarker(
        point: LatLng(zone.latitude, zone.longitude),
        radius: (zone.radius / 20).clamp(16, 48),
        color: color.withValues(alpha: 0.2),
        borderColor: color.withValues(alpha: 0.6),
        borderStrokeWidth: 2,
      );
    }).toList();
  }

  List<Marker> _buildMarkers(List<HeatZone> zones, LatLng userLatLng) {
    return [
      Marker(
        point: userLatLng,
        width: 34,
        height: 34,
        child: const Icon(Icons.my_location_rounded,
            color: AppColors.primary, size: 22),
      ),
      ...zones.map((zone) {
        final markerColor = AppColors.getRiskColor(zone.riskScore);
      return Marker(
        point: LatLng(zone.latitude, zone.longitude),
        width: 34,
        height: 34,
        child: Icon(
          Icons.location_on_rounded,
          color: markerColor,
          size: 26,
        ),
      );
      }),
    ];
  }
}
