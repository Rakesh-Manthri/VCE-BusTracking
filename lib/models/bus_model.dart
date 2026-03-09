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

  Bus({
    required this.id,
    required this.name,
    required this.route,
    this.activeDriverId,
    this.activeDriverName,
    this.lat,
    this.lng,
    this.lastUpdated,
  });

  bool get hasActiveDriver =>
      activeDriverId != null && activeDriverId!.isNotEmpty;

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
    };
  }
}
