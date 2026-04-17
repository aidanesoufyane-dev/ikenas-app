import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/models/models.dart';
import '../../../core/localization/app_localizations.dart';
import '../viewmodels/location_view_model.dart';

class LocationScreen extends StatefulWidget {
  final StudentModel student;
  const LocationScreen({super.key, required this.student});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  // Real Casablanca Coordinates (Static for now)
  final LatLng _schoolLoc = const LatLng(33.5731, -7.5898);
  final LatLng _homeLoc = const LatLng(33.5651, -7.5958);

  double _currentZoom = 15;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationViewModel>().startPolling(widget.student.id);
    });
  }

  @override
  void dispose() {
    context.read<LocationViewModel>().stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
            AppLocalizations.of(context)!.translate('bus_tracking_title'),
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.5)),
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<LocationViewModel>(
        builder: (context, vm, child) {
          final busLoc = vm.currentLocation != null
              ? LatLng(
                  vm.currentLocation!.latitude, vm.currentLocation!.longitude)
              : _schoolLoc; // Fallback to school if no bus location

          return Stack(
            children: [
              // 1. Map Layer
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: busLoc,
                  initialZoom: _currentZoom,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onMapEvent: (event) {
                    if (event is MapEventMove) {
                      setState(() => _currentZoom = event.camera.zoom);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                  ),
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _homeLoc,
                        radius: 100,
                        useRadiusInMeter: true,
                        color: Colors.greenAccent.withValues(alpha: 0.1),
                        borderColor: Colors.greenAccent.withValues(alpha: 0.3),
                        borderStrokeWidth: 2,
                      ),
                      CircleMarker(
                        point: _schoolLoc,
                        radius: 200,
                        useRadiusInMeter: true,
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        borderColor: Colors.blueAccent.withValues(alpha: 0.3),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _schoolLoc,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.2),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.school_rounded,
                              color: Colors.blueAccent, size: 24),
                        ),
                      ),
                      Marker(
                        point: _homeLoc,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.2),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.house_rounded,
                              color: Colors.greenAccent, size: 24),
                        ),
                      ),
                      Marker(
                        point: busLoc,
                        width: 100,
                        height: 120,
                        child: _buildStudentMarker(context, vm.currentLocation),
                      ),
                    ],
                  ),
                ],
              ),

              // UI Overlays
              _buildFloatingStatusPills(context, vm.currentLocation),
              _buildZoomControls(),

              if (vm.isLoading && vm.history.isEmpty)
                const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent)),

              if (vm.errorMessage != null && vm.history.isEmpty)
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 64,
                            color: Colors.blueAccent.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text(
                            AppLocalizations.of(context)!
                                .translate(vm.errorMessage!),
                            style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontWeight: FontWeight.w900,
                                fontSize: 16)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => vm.startPolling(widget.student.id),
                          child: Text(
                              AppLocalizations.of(context)!.translate('retry')),
                        ),
                      ],
                    ),
                  ),
                ),

              _DraggableHistorySheet(
                history: vm.history,
                buildAlerts: () =>
                    _buildImportantAlerts(context, vm.currentLocation),
                buildStats: () =>
                    _buildBusFleetStats(context, vm.currentLocation),
                buildItem: (r) => _buildTimelineItem(context, r),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImportantAlerts(BuildContext context, BusLocationModel? bus) {
    bool isArrived = bus != null && bus.status == 'stopped'; // Simple logic
    return Column(
      children: [
        GlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          color: isArrived
              ? Colors.greenAccent.withValues(alpha: 0.05)
              : Colors.orangeAccent.withValues(alpha: 0.05),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color:
                        (isArrived ? Colors.greenAccent : Colors.orangeAccent)
                            .withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: Icon(
                    isArrived
                        ? Icons.check_circle_outline_rounded
                        : Icons.directions_bus_filled_rounded,
                    color: isArrived ? Colors.greenAccent : Colors.orangeAccent,
                    size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        isArrived
                            ? "${AppLocalizations.of(context)!.translate('arrived_label')} : ${AppLocalizations.of(context)!.translate('home_label')}"
                            : AppLocalizations.of(context)!
                                .translate('trip_in_progress'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15)),
                    Text(bus?.lastUpdate ?? "Just now",
                        style: const TextStyle(
                            color: Colors.black38,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color:
                        (isArrived ? Colors.greenAccent : Colors.orangeAccent)
                            .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(isArrived ? "SECURED" : "LIVE",
                    style: TextStyle(
                        color: isArrived
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingStatusPills(
      BuildContext context, BusLocationModel? bus) {
    return Positioned(
      bottom: 120,
      left: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPill(
              "${AppLocalizations.of(context)!.translate('gps_signal')} : ${bus != null ? 'STRONG' : 'UNKNOWN'}"),
          const SizedBox(height: 8),
          _buildPill(
              "${bus?.batteryLevel.toInt() ?? 0}% ${AppLocalizations.of(context)!.translate('battery')}"),
        ],
      ),
    );
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          style: const TextStyle(
              color: Color(0xFF0A0F1E),
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 0.5)),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      right: 16,
      bottom: 160,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildZoomBtn(
                icon: Icons.add_rounded,
                onTap: () {
                  final newZoom = (_currentZoom + 1).clamp(3.0, 18.0);
                  _mapController.move(_mapController.camera.center, newZoom);
                  setState(() => _currentZoom = newZoom);
                }),
            Container(
                height: 1,
                width: 28,
                color: Colors.white.withValues(alpha: 0.08)),
            _buildZoomBtn(
                icon: Icons.remove_rounded,
                onTap: () {
                  final newZoom = (_currentZoom - 1).clamp(3.0, 18.0);
                  _mapController.move(_mapController.camera.center, newZoom);
                  setState(() => _currentZoom = newZoom);
                }),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Icon(icon, color: Colors.white70, size: 20)),
    );
  }

  Widget _buildStudentMarker(BuildContext context, BusLocationModel? bus) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: Colors.blueAccent.withValues(alpha: 0.5), width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                  blurRadius: 8)
            ],
          ),
          child: Text(bus?.id ?? "BUS",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                  color: Colors.blueAccent.withValues(alpha: 0.4),
                  blurRadius: 15,
                  spreadRadius: 5)
            ],
          ),
          child: const Icon(Icons.directions_bus_rounded,
              color: Colors.white, size: 22),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            duration: 1000.ms),
      ],
    );
  }

  Widget _buildTimelineItem(
      BuildContext context, LocationHistoryRecord record) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: record.color.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: Icon(record.icon, color: record.color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(record.title,
                        style: TextStyle(
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w900,
                            fontSize: 15)),
                    Text(record.time,
                        style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(record.subtitle,
                    style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black45,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusFleetStats(BuildContext context, BusLocationModel? bus) {
    return Row(
      children: [
        _buildStatItem(
            AppLocalizations.of(context)!.translate('speed_label'),
            "${bus?.speed.toInt() ?? 0} km/h",
            Icons.speed_rounded,
            Colors.blueAccent),
        const SizedBox(width: 16),
        _buildStatItem(
            AppLocalizations.of(context)!.translate('capacity_label'),
            "--/--",
            Icons.people_outline_rounded,
            Colors.indigoAccent),
      ],
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            Text(label,
                style: const TextStyle(
                    color: Colors.black38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _DraggableHistorySheet extends StatefulWidget {
  final List<LocationHistoryRecord> history;
  final Widget Function() buildAlerts;
  final Widget Function() buildStats;
  final Widget Function(LocationHistoryRecord) buildItem;

  const _DraggableHistorySheet({
    required this.history,
    required this.buildAlerts,
    required this.buildStats,
    required this.buildItem,
  });

  @override
  State<_DraggableHistorySheet> createState() => _DraggableHistorySheetState();
}

class _DraggableHistorySheetState extends State<_DraggableHistorySheet> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(() {
      final expanded = _sheetController.size > 0.55;
      if (expanded != _isExpanded) setState(() => _isExpanded = expanded);
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.35,
      minChildSize: 0.35,
      maxChildSize: 0.80,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25), blurRadius: 24)
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 14),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.buildAlerts(),
                      const SizedBox(height: 24),
                      widget.buildStats(),
                      const SizedBox(height: 30),
                      Divider(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.06)),
                      const SizedBox(height: 20),
                      Text(
                          AppLocalizations.of(context)!
                              .translate('today_history'),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A))),
                      const SizedBox(height: 16),
                      ...widget.history.map((r) => widget.buildItem(r)),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
