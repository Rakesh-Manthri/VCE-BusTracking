import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/bus_model.dart';
import '../models/bus_stop_model.dart';

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

  /// Claim a bus as the active driver.
  /// Uses a simple get + update (no transaction) to avoid silent hangs.
  Future<bool> claimBus(
    String busId,
    String userId,
    String userName, {
    String? travelDirection,
  }) async {
    try {
      debugPrint('[FirestoreService] claimBus() called — busId=$busId userId=$userId dir=$travelDirection');

      // ── Step 1: read current state (5-second timeout) ──────────────────────
      final busDoc = await _firestore
          .collection('buses')
          .doc(busId)
          .get()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Firestore read timed out after 5s'),
          );

      if (!busDoc.exists) {
        debugPrint('[FirestoreService] claimBus() FAILED — bus document does not exist');
        return false;
      }

      final data = busDoc.data() as Map<String, dynamic>;
      final currentDriver = data['activeDriverId'] as String?;
      debugPrint('[FirestoreService] claimBus() — current activeDriverId=$currentDriver');

      // ── Step 2: check if another driver already owns it ────────────────────
      if (currentDriver != null &&
          currentDriver.isNotEmpty &&
          currentDriver != userId) {
        debugPrint('[FirestoreService] claimBus() DENIED — another driver owns this bus');
        return false;
      }

      // ── Step 3: write claim immediately (no transaction, no GPS needed) ────
      debugPrint('[FirestoreService] claimBus() — writing claim to Firestore…');
      await _firestore
          .collection('buses')
          .doc(busId)
          .update({
            'activeDriverId': userId,
            'activeDriverName': userName,
            'travelDirection': travelDirection,
            'lastUpdated': FieldValue.serverTimestamp(),
          })
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Firestore write timed out after 5s'),
          );

      debugPrint('[FirestoreService] claimBus() SUCCESS');
      return true;
    } catch (e) {
      debugPrint('[FirestoreService] claimBus() ERROR: $e');
      return false;
    }
  }

  /// Release a bus (stop driving)
  Future<void> releaseBus(String busId, String userId) async {
    final busDoc = await _firestore.collection('buses').doc(busId).get();
    if (!busDoc.exists) return;
    final data = busDoc.data() as Map<String, dynamic>;
    if (data['activeDriverId'] == userId) {
      await _firestore.collection('buses').doc(busId).update({
        'activeDriverId': null,
        'activeDriverName': null,
        'travelDirection': null,
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

  // ─── STOPS ────────────────────────────────────────────────────────────────

  /// Real-time stream of stops for a fixed-route bus, ordered by `order`
  Stream<List<BusStop>> getStopsStream(String busId) {
    return _firestore
        .collection('buses')
        .doc(busId)
        .collection('stops')
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map((d) => BusStop.fromFirestore(d)).toList());
  }

  /// Add or update a stop
  Future<void> addStop(String busId, BusStop stop) async {
    final ref = _firestore
        .collection('buses')
        .doc(busId)
        .collection('stops');
    if (stop.id.isEmpty) {
      await ref.add(stop.toMap());
    } else {
      await ref.doc(stop.id).set(stop.toMap());
    }
  }

  /// Delete a stop
  Future<void> deleteStop(String busId, String stopId) async {
    await _firestore
        .collection('buses')
        .doc(busId)
        .collection('stops')
        .doc(stopId)
        .delete();
  }

  /// Swap order of two adjacent stops (Move Up / Move Down)
  Future<void> swapStopOrder(
    String busId,
    String stopIdA,
    int orderA,
    String stopIdB,
    int orderB,
  ) async {
    final batch = _firestore.batch();
    final ref = _firestore.collection('buses').doc(busId).collection('stops');
    batch.update(ref.doc(stopIdA), {'order': orderB});
    batch.update(ref.doc(stopIdB), {'order': orderA});
    await batch.commit();
  }

  // ─── ADMIN ────────────────────────────────────────────────────────────────

  /// Fetch admin password from Firestore
  Future<String?> getAdminPassword() async {
    try {
      final snap =
          await _firestore.collection('adminConfig').limit(1).get();
      if (snap.docs.isEmpty) return null;
      return snap.docs.first.data()['adminPassword'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Add a normal bus (admin only)
  Future<void> addBus({
    required String name,
    required String route,
    bool hasFixedRoute = false,
    String? startName,
    double? startLat,
    double? startLng,
    String? endName,
    double? endLat,
    double? endLng,
  }) async {
    await _firestore.collection('buses').add({
      'name': name,
      'route': route,
      'hasFixedRoute': hasFixedRoute,
      'startName': startName,
      'startLat': startLat,
      'startLng': startLng,
      'endName': endName,
      'endLat': endLat,
      'endLng': endLng,
      'travelDirection': null,
      'activeDriverId': null,
      'activeDriverName': null,
      'lat': null,
      'lng': null,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  /// Force-claim a bus without any ownership check (debug only).
  /// Directly writes activeDriverId and related fields.
  Future<void> forceClaimBus({
    required String busId,
    required String userId,
    required String userName,
    String? travelDirection,
  }) async {
    debugPrint('[FirestoreService] forceClaimBus() — bypassing ownership check');
    await _firestore.collection('buses').doc(busId).update({
      'activeDriverId': userId,
      'activeDriverName': userName,
      'travelDirection': travelDirection,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    debugPrint('[FirestoreService] forceClaimBus() — write done');
  }
}
