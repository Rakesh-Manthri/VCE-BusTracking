import 'package:shared_preferences/shared_preferences.dart';

/// Manages the logged-in driver session using SharedPreferences.
/// Drivers use driverId-based auth (not Firebase Auth).
class DriverSessionService {
  static const _keyDriverId = 'driver_id';
  static const _keyDriverName = 'driver_name';
  static const _keyDriverDocId = 'driver_doc_id';

  /// Save driver session after successful login
  static Future<void> saveSession({
    required String driverId,
    required String driverName,
    required String driverDocId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDriverId, driverId);
    await prefs.setString(_keyDriverName, driverName);
    await prefs.setString(_keyDriverDocId, driverDocId);
  }

  /// Returns the logged-in driver ID (e.g. "DRV001"), or null if not logged in
  static Future<String?> getDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDriverId);
  }

  /// Returns the logged-in driver's display name, or null
  static Future<String?> getDriverName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDriverName);
  }

  /// Returns the Firestore document ID for this driver, or null
  static Future<String?> getDriverDocId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDriverDocId);
  }

  /// Check if a driver is currently logged in
  static Future<bool> isLoggedIn() async {
    final id = await getDriverId();
    return id != null && id.isNotEmpty;
  }

  /// Clear driver session on logout
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDriverId);
    await prefs.remove(_keyDriverName);
    await prefs.remove(_keyDriverDocId);
  }
}
