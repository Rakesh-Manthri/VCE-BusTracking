import 'package:flutter/material.dart';
import 'dart:async';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/bus_model.dart';
import '../services/firestore_service.dart';

class TrackerScreen extends StatefulWidget {
  final Bus bus;

  const TrackerScreen({super.key, required this.bus});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  late final WebViewController _webController;
  final _firestoreService = FirestoreService();
  StreamSubscription<Bus?>? _busSubscription;
  StreamSubscription<Position>? _positionStream;
  Position? _userPosition;
  Bus? _latestBus;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _startTracking();
  }

  @override
  void dispose() {
    _busSubscription?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() => _mapReady = true);
            _updateMapIfReady();
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadFlutterAsset('assets/map.html');
  }

  void _startTracking() {
    // Listen to bus location changes from Firestore
    _busSubscription = _firestoreService.getBusStream(widget.bus.id).listen((
      bus,
    ) {
      if (!mounted) return;
      setState(() => _latestBus = bus);
      _updateMapIfReady();
    });

    // Track user's own position
    _initUserLocation();
  }

  Future<void> _initUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) {
            if (!mounted) return;
            setState(() => _userPosition = position);
            _updateMapIfReady();
          },
        );
  }

  void _updateMapIfReady() {
    if (!_mapReady || !mounted) return;

    final bus = _latestBus;
    if (bus == null ||
        !bus.hasActiveDriver ||
        bus.lat == null ||
        bus.lng == null) {
      return;
    }

    if (_userPosition != null) {
      _webController.runJavaScript(
        'updateBusRoute(${_userPosition!.latitude}, ${_userPosition!.longitude}, ${bus.lat}, ${bus.lng});',
      );
    } else {
      // If no user position yet, just center on bus
      _webController.runJavaScript('centerMap(${bus.lat}, ${bus.lng});');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bus = _latestBus;
    final isOnline = bus != null && bus.hasActiveDriver;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.bus.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Status indicator in app bar
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isOnline
                  ? Colors.green.withAlpha(50)
                  : Colors.red.withAlpha(50),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOnline ? Colors.green.shade300 : Colors.red.shade300,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: isOnline ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 5),
                Text(
                  isOnline ? 'Live' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOnline
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          WebViewWidget(controller: _webController),

          // Offline overlay
          if (!isOnline)
            Container(
              color: Colors.black.withAlpha(120),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.wifi_off_rounded,
                          size: 44,
                          color: Colors.red.shade400,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Bus is Offline',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No active driver for this bus.\nTracking will resume automatically\nwhen a driver starts.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Waiting for driver...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom info bar (when online)
          if (isOnline)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        color: Color(0xFF1A237E),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            bus.route,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Driver: ${bus.activeDriverName ?? "Unknown"}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
