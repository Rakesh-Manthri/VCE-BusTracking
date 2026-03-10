import 'package:cloud_firestore/cloud_firestore.dart';

class Bus {
  final String id;
  final String name;
  final String route;
  final String? activeDriverId;
  final String? activeDriverName;
  final double? lat;
  final double? lng;
  final Timestamp? lastUpdated;
  final bool hasFixedRoute;

  // Fixed route endpoints
  final String? startName;
  final double? startLat;
  final double? startLng;
  final String? endName;
  final double? endLat;
  final double? endLng;

  // Phase 3: direction chosen by driver
  final String? travelDirection; // 'forward' | 'backward' | null

  Bus({
    required this.id,
    required this.name,
    required this.route,
    this.activeDriverId,
    this.activeDriverName,
    this.lat,
    this.lng,
    this.lastUpdated,
    this.hasFixedRoute = false,
    this.startName,
    this.startLat,
    this.startLng,
    this.endName,
    this.endLat,
    this.endLng,
    this.travelDirection,
  });

  bool get hasActiveDriver =>
      activeDriverId != null && activeDriverId!.isNotEmpty;

  /// Human-readable direction label e.g. "Miyapur → VCE"
  String get directionLabel {
    if (!hasFixedRoute) return route;
    if (travelDirection == 'backward') {
      return '${endName ?? "End"} → ${startName ?? "Start"}';
    }
    return '${startName ?? "Start"} → ${endName ?? "End"}';
  }

  factory Bus.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Bus(
      id: doc.id,
      name: data['name'] ?? '',
      route: data['route'] ?? '',
      activeDriverId: data['activeDriverId'],
      activeDriverName: data['activeDriverName'],
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      lastUpdated: data['lastUpdated'] as Timestamp?,
      hasFixedRoute: data['hasFixedRoute'] as bool? ?? false,
      startName: data['startName'] as String?,
      startLat: (data['startLat'] as num?)?.toDouble(),
      startLng: (data['startLng'] as num?)?.toDouble(),
      endName: data['endName'] as String?,
      endLat: (data['endLat'] as num?)?.toDouble(),
      endLng: (data['endLng'] as num?)?.toDouble(),
      travelDirection: data['travelDirection'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'route': route,
      'activeDriverId': activeDriverId,
      'activeDriverName': activeDriverName,
      'lat': lat,
      'lng': lng,
      'lastUpdated': lastUpdated,
      'hasFixedRoute': hasFixedRoute,
      'startName': startName,
      'startLat': startLat,
      'startLng': startLng,
      'endName': endName,
      'endLat': endLat,
      'endLng': endLng,
      'travelDirection': travelDirection,
    };
  }
}
