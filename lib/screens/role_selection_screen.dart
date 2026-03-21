import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'driver_login_screen.dart';
import 'admin_login_screen.dart';

/// The first screen users see. Lets them choose their role before logging in.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1B4B), Color(0xFF1A237E), Color(0xFF01579B)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // App Icon
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withAlpha(60), width: 2),
                  ),
                  child: const Icon(Icons.directions_bus_rounded,
                      size: 72, color: Colors.white),
                ),
                const SizedBox(height: 24),

                const Text(
                  'VCE Bus Tracker',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vasavi College of Engineering',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withAlpha(170),
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 56),

                Text(
                  'Select your role to continue',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withAlpha(200),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Student Card ──────────────────────────────────────────────
                _RoleCard(
                  icon: Icons.school_rounded,
                  title: 'Student',
                  subtitle: 'Track your bus in real-time',
                  color: const Color(0xFF1A237E),
                  accentColor: Colors.blue.shade200,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Driver Card ───────────────────────────────────────────────
                _RoleCard(
                  icon: Icons.drive_eta_rounded,
                  title: 'Driver',
                  subtitle: 'Start your route and share location',
                  color: Colors.orange.shade800,
                  accentColor: Colors.orange.shade200,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DriverLoginScreen()),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Admin Card ────────────────────────────────────────────────
                _RoleCard(
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Admin',
                  subtitle: 'Manage buses, routes and drivers',
                  color: Colors.deepPurple.shade700,
                  accentColor: Colors.deepPurple.shade200,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                  ),
                ),

                const SizedBox(height: 48),

                Text(
                  'VCE Bus Tracking System v2.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withAlpha(100),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color accentColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(40), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withAlpha(220),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(100),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withAlpha(170),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withAlpha(130), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
