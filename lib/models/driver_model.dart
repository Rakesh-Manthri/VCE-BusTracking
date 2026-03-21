import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a driver stored in the Firestore `drivers` collection.
/// Drivers use their own ID+password auth — NOT Firebase Auth.
class Driver {
  final String id;         // Firestore doc id (also used as login ID)
  final String driverId;   // Human-readable ID, e.g. "DRV001"
  final String driverName;
  final String password;   // plain-text (admin-controlled internal system)
  final String? assignedBusId; // optional — bus pre-assigned to this driver
  final Timestamp? createdAt;

  const Driver({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.password,
    this.assignedBusId,
    this.createdAt,
  });

  factory Driver.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Driver(
      id: doc.id,
      driverId: data['driverId'] as String? ?? '',
      driverName: data['driverName'] as String? ?? '',
      password: data['password'] as String? ?? '',
      assignedBusId: data['assignedBusId'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() => {
        'driverId': driverId,
        'driverName': driverName,
        'password': password,
        'assignedBusId': assignedBusId,
        'createdAt': createdAt,
      };
}
