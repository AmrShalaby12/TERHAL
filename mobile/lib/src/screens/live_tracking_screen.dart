/// LiveTrackingScreen
///
/// Shows the bus position on an OpenStreetMap (light) or Carto dark map (dark
/// mode) and receives live location updates through a WebSocket connection.
///
/// An optional simulation can be enabled explicitly for local visual QA. It is
/// disabled by default so production never presents generated GPS as real data.
///
/// Roles:
///   • Student  — read-only, watches the bus marker move.
///   • Supervisor — additionally runs LocationSharingService to push GPS.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api_service.dart';
import '../models.dart';
import '../session_controller.dart';
import '../services/location_service.dart';

// Cairo area fallback used before any route data arrives
const _cairoFallback = LatLng(30.0444, 31.2357);
const _enableTrackingSimulation = bool.fromEnvironment(
  'ENABLE_TRACKING_SIMULATION',
  defaultValue: false,
);

// ─────────────────────────────────────────────────────────────────────────────
// Bus location ping model
// ─────────────────────────────────────────────────────────────────────────────

class _BusLocation {
  const _BusLocation({
    required this.position,
    required this.speedKmh,
    required this.heading,
    required this.timestamp,
  });

  final LatLng position;
  final int speedKmh;
  final int heading;
  final DateTime timestamp;

  factory _BusLocation.fromJson(Map<String, dynamic> json) {
    return _BusLocation(
      position: LatLng(
        double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
        double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
      ),
      speedKmh: int.tryParse(json['speed_kmh']?.toString() ?? '') ?? 0,
      heading: int.tryParse(json['heading']?.toString() ?? '') ?? 0,
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class LiveTrackingScreen extends ConsumerStatefulWidget {
  const LiveTrackingScreen({super.key, required this.trip});

  final TripModel trip;

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  // Map
  final MapController _mapController = MapController();

  // WebSocket
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _wsSub;
  Timer? _reconnectTimer;

  // Bus state
  _BusLocation? _busLocation;
  final List<LatLng> _trail = [];

  // Route geometry
  List<LatLng> _routePolyline = [];
  bool _loadingSnapshot = true;

  // Simulation
  Timer? _simulationTimer;
  int _simIndex = 0;
  double _simFraction = 0.0;
  bool _hasRealData = false;
  final _rng = math.Random();

  // Supervisor GPS sharing
  LocationSharingService? _locationService;
  bool _sharingLocation = false;
  String? _locationError;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (_enableTrackingSimulation) _startSimulation();
    _loadSnapshot();
    _connectWebSocket();

    final user = ref.read(sessionProvider).user;
    if (user != null && user.isSupervisor) _startLocationSharing();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _channel?.sink.close();
    _reconnectTimer?.cancel();
    _simulationTimer?.cancel();
    _locationService?.stop();
    super.dispose();
  }

  // ── Route snapshot ──────────────────────────────────────────────────────────

  Future<void> _loadSnapshot() async {
    try {
      final payload = await ref
          .read(sessionProvider.notifier)
          .trackingForTrip(widget.trip.id);

      final newRoute = payload.routePoints
          .map((p) => LatLng(p.lat, p.lng))
          .toList();
      final newTrail = payload.timeline
          .map((p) => LatLng(p.lat, p.lng))
          .toList();

      if (!mounted) return;
      setState(() {
        _routePolyline = newRoute;
        _loadingSnapshot = false;
        if (newTrail.isNotEmpty) {
          _trail.addAll(newTrail);
          _busLocation = _BusLocation(
            position: newTrail.last,
            speedKmh: 0,
            heading: 0,
            timestamp: DateTime.now(),
          );
          _animateMapTo(newTrail.last);
        }
      });
      if (_enableTrackingSimulation) _startSimulation();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingSnapshot = false;
      });
    }
  }

  // ── WebSocket ───────────────────────────────────────────────────────────────

  void _connectWebSocket() {
    final token = ref.read(sessionProvider).token;
    final uri = Uri.parse(ApiService.wsTrackingUrl(widget.trip.id, token));
    _channel = WebSocketChannel.connect(uri);
    _wsSub = _channel!.stream.listen(
      _onWsMessage,
      onError: (_) => _scheduleReconnect(),
      onDone: _scheduleReconnect,
    );
  }

  void _onWsMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['type'] != 'location_update') return;
      _hasRealData = true; // real data suppresses simulation
      final loc = _BusLocation.fromJson(json);
      if (!mounted) return;
      setState(() {
        _busLocation = loc;
        _trail.add(loc.position);
        if (_trail.length > 60) _trail.removeAt(0);
      });
      _animateMapTo(loc.position);
    } catch (_) {}
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      _wsSub?.cancel();
      _channel?.sink.close();
      _connectWebSocket();
    });
  }

  // ── Simulation ──────────────────────────────────────────────────────────────

  void _startSimulation() {
    _simulationTimer?.cancel();

    final route = _routePolyline.isNotEmpty
        ? _routePolyline
        : _cairoFallbackRoute();

    // Reset position when route changes
    _simIndex = 0;
    _simFraction = 0.0;

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (_hasRealData || !mounted) return;
      if (route.length < 2) return;

      // Advance ~5% of a segment per tick with slight jitter
      _simFraction += 0.045 + _rng.nextDouble() * 0.015;

      while (_simFraction >= 1.0) {
        _simFraction -= 1.0;
        _simIndex = (_simIndex + 1) % (route.length - 1);
      }

      final a = route[_simIndex];
      final b = route[_simIndex + 1];
      final lat = a.latitude + (b.latitude - a.latitude) * _simFraction;
      final lng = a.longitude + (b.longitude - a.longitude) * _simFraction;
      final pos = LatLng(lat, lng);

      final dLat = b.latitude - a.latitude;
      final dLng = b.longitude - a.longitude;
      final heading = ((math.atan2(dLng, dLat) * 180 / math.pi) + 360) % 360;
      final speed = 28 + _rng.nextInt(22); // 28–50 km/h

      setState(() {
        _busLocation = _BusLocation(
          position: pos,
          speedKmh: speed,
          heading: heading.toInt(),
          timestamp: DateTime.now(),
        );
        _trail.add(pos);
        if (_trail.length > 60) _trail.removeAt(0);
      });
    });
  }

  // Demo loop around central Cairo when no backend route is available
  static List<LatLng> _cairoFallbackRoute() => const [
    LatLng(30.0444, 31.2357),
    LatLng(30.0482, 31.2393),
    LatLng(30.0516, 31.2428),
    LatLng(30.0549, 31.2398),
    LatLng(30.0531, 31.2343),
    LatLng(30.0498, 31.2308),
    LatLng(30.0462, 31.2325),
    LatLng(30.0444, 31.2357),
  ];

  // ── Supervisor GPS sharing ───────────────────────────────────────────────────

  Future<void> _startLocationSharing() async {
    final api = ref.read(apiServiceProvider);
    final token = ref.read(sessionProvider).token;
    _locationService = LocationSharingService(
      onLocation:
          ({
            required latitude,
            required longitude,
            required speedKmh,
            required heading,
          }) => api.pushDriverLocation(
            token: token,
            tripId: widget.trip.id,
            latitude: latitude,
            longitude: longitude,
            speedKmh: speedKmh,
            heading: heading,
          ),
      onError: (msg) {
        if (mounted) setState(() => _locationError = msg);
      },
    );
    final started = await _locationService!.start();
    if (mounted) setState(() => _sharingLocation = started);
  }

  // ── Map helpers ─────────────────────────────────────────────────────────────

  void _animateMapTo(LatLng position) {
    _mapController.move(position, _mapController.camera.zoom.clamp(13.0, 17.0));
  }

  void _focusOnRoute() {
    final points = _routePolyline.isNotEmpty
        ? _routePolyline
        : (_trail.isNotEmpty ? _trail : [_initialCenter]);
    if (points.isEmpty) {
      _mapController.move(_initialCenter, 14);
      return;
    }

    final avgLat =
        points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final avgLng =
        points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;

    _mapController.move(
      LatLng(avgLat, avgLng),
      points.length >= 2 ? 13.1 : 14.6,
    );
  }

  LatLng get _initialCenter {
    if (_busLocation != null) return _busLocation!.position;
    if (_routePolyline.isNotEmpty) {
      return _routePolyline[_routePolyline.length ~/ 2];
    }
    return _cairoFallback;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    const canvasColor = Color(0xFF06070A);
    const accent = Color(0xFFBF1E23);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: canvasColor,
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: 14,
                minZoom: 10,
                maxZoom: 19,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.terhal.mobile',
                  maxZoom: 19,
                ),
                if (_routePolyline.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePolyline,
                        color: Colors.white.withValues(alpha: 0.16),
                        strokeWidth: 8,
                        borderColor: accent.withValues(alpha: 0.10),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                if (_trail.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _trail,
                        color: accent,
                        strokeWidth: 5.5,
                        borderColor: accent.withValues(alpha: 0.22),
                        borderStrokeWidth: 10,
                      ),
                    ],
                  ),
                if (_routePolyline.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      _endpointMarker(
                        _routePolyline.first,
                        Icons.trip_origin_rounded,
                        const Color(0xFFB9BCC8),
                        trip.route.originName,
                      ),
                      _endpointMarker(
                        _routePolyline.last,
                        Icons.home_rounded,
                        accent,
                        trip.route.destinationName,
                      ),
                    ],
                  ),
                if (_busLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _busLocation!.position,
                        width: 72,
                        height: 72,
                        child: _BusMarker(heading: _busLocation!.heading),
                      ),
                    ],
                  ),
              ],
            ),

            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        canvasColor.withValues(alpha: 0.22),
                        Colors.transparent,
                        canvasColor.withValues(alpha: 0.30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.2, 0.95),
                      radius: 1.05,
                      colors: [
                        accent.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 150,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        canvasColor.withValues(alpha: 0.95),
                        canvasColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    _TopButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(
                            sigmaX: 20,
                            sigmaY: 20,
                            tileMode: ui.TileMode.decal,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.24),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.alt_route_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        trip.route.name,
                                        style: TextStyle(
                                          fontFamily: 'Tajawal',
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${trip.route.originName} ← ${trip.route.destinationName}',
                                        style: TextStyle(
                                          fontFamily: 'Tajawal',
                                          color: Colors.white70,
                                          fontSize: 11.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.20),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: accent.withValues(alpha: 0.32),
                                    ),
                                  ),
                                  child: Text(
                                    _hasRealData ? 'LIVE' : 'TRACK',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TopButton(
                      icon: Icons.my_location_rounded,
                      onTap: () {
                        if (_busLocation != null) {
                          _mapController.move(_busLocation!.position, 15);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            if (_loadingSnapshot)
              Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

            if (_enableTrackingSimulation &&
                !_hasRealData &&
                _busLocation != null)
              Positioned(top: 118, right: 16, child: const _SimBadge()),

            Positioned(
              left: 16,
              right: 16,
              bottom: _kPanelEstimatedHeight + 18,
              child: Row(
                children: [
                  Expanded(
                    child: _MapActionButton(
                      label: 'تمركز',
                      icon: Icons.my_location_rounded,
                      onTap: () {
                        if (_busLocation != null) {
                          _mapController.move(_busLocation!.position, 15);
                        } else {
                          _mapController.move(_initialCenter, 14);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MapActionButton(
                      label: 'نظرة عامة',
                      icon: Icons.route_rounded,
                      onTap: _focusOnRoute,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomPanel(
                trip: trip,
                busLocation: _busLocation,
                sharingLocation: _sharingLocation,
                locationError: _locationError,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Marker _endpointMarker(
    LatLng point,
    IconData icon,
    Color color,
    String label,
  ) {
    return Marker(
      point: point,
      width: 44,
      height: 44,
      child: Tooltip(
        message: label,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.86),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 12),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// Rough height estimate used to position floating controls above the panel.
const double _kPanelEstimatedHeight = 200;

// ─────────────────────────────────────────────────────────────────────────────
// Bus marker with pulsing glow
// ─────────────────────────────────────────────────────────────────────────────

class _BusMarker extends StatefulWidget {
  const _BusMarker({required this.heading});

  final int heading;

  @override
  State<_BusMarker> createState() => _BusMarkerState();
}

class _BusMarkerState extends State<_BusMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _pulse = Tween<double>(
      begin: 0.55,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Transform.rotate(
      angle: widget.heading * math.pi / 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing halo
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, _) => Container(
              width: 72 * _pulse.value,
              height: 72 * _pulse.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withValues(alpha: (1 - _pulse.value) * 0.40),
              ),
            ),
          ),
          // Mid ring
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.15),
            ),
          ),
          // Bus icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.55),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar button (back / re-center) — theme-aware
// ─────────────────────────────────────────────────────────────────────────────

class _TopButton extends StatelessWidget {
  const _TopButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: 18,
          sigmaY: 18,
          tileMode: ui.TileMode.decal,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Ink(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapActionButton extends StatefulWidget {
  const _MapActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_MapActionButton> createState() => _MapActionButtonState();
}

class _MapActionButtonState extends State<_MapActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: SizedBox(
        height: 48,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: 18,
              sigmaY: 18,
              tileMode: ui.TileMode.decal,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: (_) => setState(() => _pressed = true),
                onTapUp: (_) => setState(() => _pressed = false),
                onTapCancel: () => setState(() => _pressed = false),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        const Color(0xFFBF1E23).withValues(alpha: 0.20),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFBF1E23).withValues(alpha: 0.16),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: 1.6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.8),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.icon, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              widget.label,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Simulation badge
// ─────────────────────────────────────────────────────────────────────────────

class _SimBadge extends StatelessWidget {
  const _SimBadge();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
          tileMode: ui.TileMode.decal,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.56),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFBF1E23),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'محاكاة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error banner
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Bottom info panel — fully theme-aware
// ─────────────────────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.trip,
    required this.busLocation,
    required this.sharingLocation,
    required this.locationError,
  });

  final TripModel trip;
  final _BusLocation? busLocation;
  final bool sharingLocation;
  final String? locationError;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _statusColor(trip.status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: 24,
            sigmaY: 24,
            tileMode: ui.TileMode.decal,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xF516171C), const Color(0xE5101115)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.38),
                  blurRadius: 32,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row: bus code · direction · status ──────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        trip.bus.code.isEmpty ? 'BUS' : trip.bus.code,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        trip.isDeparture ? 'رحلة الذهاب' : 'رحلة العودة',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _statusLabel(trip.status),
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Metrics row: departure · arrival · speed ───────────────
                Row(
                  children: [
                    _Metric(
                      icon: Icons.access_time_rounded,
                      label: 'الانطلاق',
                      value: trip.departureTime,
                    ),
                    const SizedBox(width: 10),
                    _Metric(
                      icon: Icons.flag_rounded,
                      label: 'الوصول المتوقع',
                      value: trip.scheduledArrivalTime,
                    ),
                    const SizedBox(width: 10),
                    // Speed is the only live-changing value — rendered in
                    // brand red so the eye locks on it immediately.
                    _Metric(
                      icon: Icons.speed_rounded,
                      label: 'السرعة',
                      value: busLocation != null
                          ? '${busLocation!.speedKmh} كم/س'
                          : '— كم/س',
                      accent: cs.primary,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Separator with red glow ────────────────────────────────
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary.withValues(alpha: 0.0),
                        cs.primary.withValues(alpha: 0.55),
                        cs.primary.withValues(alpha: 0.0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Driver / supervisor ────────────────────────────────────
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 17,
                      color: Colors.white38,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        trip.driverName.isEmpty ? '—' : trip.driverName,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.shield_outlined,
                      size: 17,
                      color: Colors.white38,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        trip.supervisorName.isEmpty ? '—' : trip.supervisorName,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // ── Location sharing indicator ─────────────────────────────
                if (sharingLocation) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF17A267).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _PulseDot(color: Color(0xFF17A267)),
                        const SizedBox(width: 8),
                        Text(
                          'يتم مشاركة الموقع تلقائياً',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: const Color(0xFF17A267),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _statusColor(String s) => switch (s) {
    'in_progress' => const Color(0xFF17A267),
    'boarding' => const Color(0xFFFFA53B),
    'completed' => const Color(0xFF087B66),
    'delayed' => const Color(0xFFFFA53B),
    'cancelled' => const Color(0xFFA61C1C),
    _ => const Color(0xFF969AAF),
  };

  static String _statusLabel(String s) => switch (s) {
    'in_progress' => 'جارية',
    'boarding' => 'ركوب',
    'scheduled' => 'مجدولة',
    'completed' => 'مكتملة',
    'delayed' => 'متأخرة',
    'cancelled' => 'ملغاة',
    _ => s,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Metric tile inside the bottom panel
// ─────────────────────────────────────────────────────────────────────────────

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
  });

  final IconData icon;
  final String label;
  final String value;

  /// When set, the value text and icon render in this colour. Used to make
  /// the live speed reading visually pop against the static time values.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final iconColor = accent ?? Colors.white38;
    final valueColor = accent ?? Colors.white;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: accent != null
              ? accent!.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: accent != null
              ? Border.all(color: accent!.withValues(alpha: 0.25), width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: iconColor),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 10,
                      color: Colors.white38,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: valueColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing dot indicator (location sharing)
// ─────────────────────────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.75,
      end: 1.25,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
