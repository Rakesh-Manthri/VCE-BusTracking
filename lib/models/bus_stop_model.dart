import 'package:cloud_firestore/cloud_firestore.dart';

class BusStop {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final int order;

  BusStop({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.order,
  });

  factory BusStop.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BusStop(
      id: doc.id,
      name: data['name'] ?? '',
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'lat': lat,
      'lng': lng,
      'order': order,
    };
  }
}
