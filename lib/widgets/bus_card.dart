import 'package:flutter/material.dart';
import '../models/bus_model.dart';

/// Defines which role is viewing the bus card.
/// Used to show/hide Drive and Track buttons appropriately.
enum UserRole { student, driver }

class BusCard extends StatelessWidget {
  final Bus bus;
  final String currentUserId;
  final VoidCallback onDrive;
  final VoidCallback onTrack;
  final UserRole userRole;

  const BusCard({
    super.key,
    required this.bus,
    required this.currentUserId,
    required this.onDrive,
    required this.onTrack,
    this.userRole = UserRole.student, // default: student (backward compat)
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = bus.hasActiveDriver;
    final bool iAmDriver = bus.activeDriverId == currentUserId;
    final bool canDrive = !isActive || iAmDriver;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: icon + name/route + status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    bus.hasFixedRoute
                        ? Icons.route_rounded
                        : Icons.directions_bus_rounded,
                    color: bus.hasFixedRoute
                        ? Colors.teal.shade700
                        : const Color(0xFF1A237E),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bus.route,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? Colors.green.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle,
                          size: 8,
                          color: isActive ? Colors.green : Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        isActive ? 'Active' : 'Idle',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Direction label (shown when bus is active with direction)
            if (isActive &&
                bus.hasFixedRoute &&
                bus.travelDirection != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.navigation_rounded,
                        size: 14, color: Colors.teal.shade700),
                    const SizedBox(width: 6),
                    Text(
                      bus.directionLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Driver info
            if (isActive) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Text(
                      'Driver: ${bus.activeDriverName ?? "Unknown"}',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500),
                    ),
                    if (iAmDriver) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('YOU',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // ── Action buttons based on role ─────────────────────────────────
            if (userRole == UserRole.driver)
              // Drivers: only see Drive button (full width)
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: canDrive ? onDrive : null,
                  icon: Icon(
                      iAmDriver ? Icons.stop_circle : Icons.drive_eta,
                      size: 18),
                  label: Text(
                    iAmDriver
                        ? 'Currently Driving...'
                        : isActive
                            ? 'Bus Taken'
                            : 'Start Driving',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iAmDriver
                        ? Colors.orange.shade700
                        : canDrive
                            ? const Color(0xFF1A237E)
                            : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade500,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              )
            else
              // Students: only see Track button (full width)
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: isActive ? onTrack : null,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: Text(
                    isActive ? 'Track Bus' : 'Bus Offline',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A237E),
                    side: BorderSide(
                      color: isActive
                          ? const Color(0xFF1A237E)
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    disabledForegroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
