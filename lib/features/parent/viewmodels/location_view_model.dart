import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/models.dart';

class LocationViewModel extends ChangeNotifier {
  BusLocationModel? _currentLocation;
  List<LocationHistoryRecord> _history = [];
  bool _isLoading = false;
  String? _errorMessage;

  BusLocationModel? get currentLocation => _currentLocation;
  List<LocationHistoryRecord> get history => _history;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Timer? _pollingTimer;

  // Hardcoded route: school → home (Casablanca area)
  static const List<_LatLng> _route = [
    _LatLng(33.5731, -7.5898), // school
    _LatLng(33.5720, -7.5912),
    _LatLng(33.5705, -7.5930),
    _LatLng(33.5690, -7.5944),
    _LatLng(33.5675, -7.5950),
    _LatLng(33.5660, -7.5955),
    _LatLng(33.5651, -7.5958), // home
  ];

  int _routeStep = 2; // start mid-route

  void startPolling(String studentId) {
    _pollingTimer?.cancel();
    _buildHardcodedState();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _advanceBus();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  void _buildHardcodedState() {
    final pt = _route[_routeStep];
    _currentLocation = BusLocationModel(
      id: 'BUS',
      latitude: pt.lat,
      longitude: pt.lng,
      speed: 35.0,
      batteryLevel: 85.0,
      status: 'in_progress',
      lastUpdate: _timeNow(),
    );

    _history = [
      LocationHistoryRecord(
        title: 'Départ de l\'école',
        subtitle: 'Ikenas — Route principale',
        time: '11:05',
        icon: Icons.school_rounded,
        color: Colors.blueAccent,
      ),
      LocationHistoryRecord(
        title: 'En route',
        subtitle: 'Boulevard Mohammed V',
        time: '11:12',
        icon: Icons.directions_bus_rounded,
        color: Colors.orangeAccent,
      ),
      LocationHistoryRecord(
        title: 'Arrêt 1',
        subtitle: 'Quartier Al Fida — 2 élèves déposés',
        time: '11:18',
        icon: Icons.location_on_rounded,
        color: Colors.purpleAccent,
      ),
      LocationHistoryRecord(
        title: 'En route',
        subtitle: 'Route des Ouled Ziane',
        time: '11:24',
        icon: Icons.directions_bus_rounded,
        color: Colors.orangeAccent,
      ),
    ];

    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void _advanceBus() {
    if (_routeStep < _route.length - 1) {
      _routeStep++;
    } else {
      _routeStep = 0; // loop back for demo
    }

    final pt = _route[_routeStep];
    final isHome = _routeStep == _route.length - 1;

    _currentLocation = BusLocationModel(
      id: 'BUS',
      latitude: pt.lat,
      longitude: pt.lng,
      speed: isHome ? 0.0 : (28 + (_routeStep * 3)).toDouble(),
      batteryLevel: (85 - _routeStep).toDouble(),
      status: isHome ? 'stopped' : 'in_progress',
      lastUpdate: _timeNow(),
    );

    if (isHome) {
      _history.add(LocationHistoryRecord(
        title: 'Arrivée à domicile',
        subtitle: 'Trajet terminé',
        time: _timeNow(),
        icon: Icons.home_rounded,
        color: Colors.greenAccent,
      ));
    }

    notifyListeners();
  }

  String _timeNow() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

class _LatLng {
  final double lat;
  final double lng;
  const _LatLng(this.lat, this.lng);
}
