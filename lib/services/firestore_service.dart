import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bus_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream all buses in real-time
  Stream<List<Bus>> getBusesStream() {
    return _firestore.collection('buses').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Bus.fromFirestore(doc)).toList();
    });
  }

  /// Stream a single bus document in real-time
  Stream<Bus?> getBusStream(String busId) {
    return _firestore.collection('buses').doc(busId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Bus.fromFirestore(doc);
    });
  }

  /// Claim a bus as the active driver using a Firestore transaction
  /// Returns true if successfully claimed, false if already taken
  Future<bool> claimBus(String busId, String userId, String userName) async {
    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        final busDoc = await transaction.get(
          _firestore.collection('buses').doc(busId),
        );

        if (!busDoc.exists) return false;

        final data = busDoc.data() as Map<String, dynamic>;
        final currentDriver = data['activeDriverId'] as String?;

        // If there's already a driver and it's not us, fail
        if (currentDriver != null &&
            currentDriver.isNotEmpty &&
            currentDriver != userId) {
          return false;
        }

        // Claim the bus
        transaction.update(_firestore.collection('buses').doc(busId), {
          'activeDriverId': userId,
          'activeDriverName': userName,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      return false;
    }
  }

  /// Release a bus (stop driving)
  Future<void> releaseBus(String busId, String userId) async {
    final busDoc = await _firestore.collection('buses').doc(busId).get();
    if (!busDoc.exists) return;

    final data = busDoc.data() as Map<String, dynamic>;
    // Only release if we are the active driver
    if (data['activeDriverId'] == userId) {
      await _firestore.collection('buses').doc(busId).update({
        'activeDriverId': null,
        'activeDriverName': null,
        'lat': null,
        'lng': null,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Update the bus location (called by driver)
  Future<void> updateBusLocation(String busId, double lat, double lng) async {
    await _firestore.collection('buses').doc(busId).update({
      'lat': lat,
      'lng': lng,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
}
