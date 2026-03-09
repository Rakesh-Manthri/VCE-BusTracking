import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/bus_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class DriverModeScreen extends StatefulWidget {
  final Bus bus;

  const DriverModeScreen({super.key, required this.bus});

  @override
  State<DriverModeScreen> createState() => _DriverModeScreenState();
}

class _DriverModeScreenState extends State<DriverModeScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  StreamSubscription<Position>? _positionStream;
  bool _isDriving = false;
  bool _isClaiming = true;
  bool _claimFailed = false;
  Position? _currentPosition;
  int _updateCount = 0;

  @override
  void initState() {
    super.initState();
    _claimBus();
  }

  @override
  void dispose() {
    _stopDriving(showSnackbar: false);
    super.dispose();
  }

  Future<void> _claimBus() async {
    final user = _authService.currentUser;
    if (user == null) {
      setState(() {
        _isClaiming = false;
        _claimFailed = true;
      });
      return;
    }

    final success = await _firestoreService.claimBus(
      widget.bus.id,
      user.uid,
      user.displayName ?? user.email ?? 'Driver',
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _isClaiming = false;
        _isDriving = true;
      });
      _startLocationUpdates();
    } else {
      setState(() {
        _isClaiming = false;
        _claimFailed = true;
      });
    }
  }

  Future<void> _startLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Location services are disabled. Please enable them.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Location permission is required for driver mode.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError('Location permissions are permanently denied.');
      return;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            if (!mounted) return;
            setState(() {
              _currentPosition = position;
              _updateCount++;
            });

            // Push location to Firestore
            _firestoreService.updateBusLocation(
              widget.bus.id,
              position.latitude,
              position.longitude,
            );
          },
          onError: (e) {
            _showError('Location error: $e');
          },
        );
  }

  Future<void> _stopDriving({bool showSnackbar = true}) async {
    await _positionStream?.cancel();
    _positionStream = null;

    final user = _authService.currentUser;
    if (user != null) {
      await _firestoreService.releaseBus(widget.bus.id, user.uid);
    }

    if (mounted) {
      setState(() => _isDriving = false);
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stopped driving. Bus released.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Driving: ${widget.bus.name}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isDriving) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Stop Driving?'),
                  content: const Text(
                    'This will release the bus and stop sharing your location.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Keep Driving'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _stopDriving();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Stop & Exit'),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Claiming state
    if (_isClaiming) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF1A237E)),
            SizedBox(height: 20),
            Text(
              'Claiming bus...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'Checking if bus is available',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Claim failed
    if (_claimFailed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.block_rounded,
                  size: 56,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bus Unavailable',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'This bus already has an active driver.\nPlease wait until the current driver stops.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Driving state
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Pulsing indicator
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.shade300, width: 3),
            ),
            child: Icon(
              Icons.gps_fixed_rounded,
              size: 56,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'You are driving!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your location is being shared in real-time',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),

          // Info cards
          _infoCard(
            icon: Icons.directions_bus,
            label: 'Bus',
            value: widget.bus.name,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _infoCard(
            icon: Icons.route,
            label: 'Route',
            value: widget.bus.route,
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          _infoCard(
            icon: Icons.location_on,
            label: 'Position',
            value: _currentPosition != null
                ? '${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}'
                : 'Waiting for GPS...',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _infoCard(
            icon: Icons.sync,
            label: 'Updates Sent',
            value: '$_updateCount',
            color: Colors.orange,
          ),

          const Spacer(),

          // Stop driving button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => _stopDriving(),
              icon: const Icon(Icons.stop_circle_rounded, size: 24),
              label: const Text(
                'Stop Driving',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color.shade700, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
