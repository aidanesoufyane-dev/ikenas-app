import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../parent/screens/parent_dashboard.dart';
import '../../teacher/screens/teacher_dashboard.dart';
import 'auth_screen.dart';

/// AuthGate handles the startup routing based on authentication state.
/// 
/// Flow:
/// 1. Shows loading splash while checking for saved session
/// 2. If valid session found -> restore user to AppState -> navigate to dashboard
/// 3. If no session -> navigate to login screen
/// 4. Handles role-based routing (Parent or Teacher)
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  /// Check if user has a valid session and restore state
  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Splash delay

    if (!mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);
    
    // Try to restore user session
    final success = await appState.restoreSessionFromStorage();
    
    if (mounted) {
      if (success) {
        // Session restored, navigate to appropriate dashboard
        _navigateToDashboard();
      } else {
        // No valid session, show login
        _navigateToLogin();
      }
    }
  }

  void _navigateToDashboard() {
    final appState = Provider.of<AppState>(context, listen: false);
    
    if (!mounted) return;

    final targetScreen = appState.isParent 
        ? const ParentDashboard()
        : const TeacherDashboard();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white24 : Colors.black26;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DeepSpaceBackground(
        showOrbs: true,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white,
                  ),
                  boxShadow: [
                    if (isDark)
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.2),
                        blurRadius: 40,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark
                              ? Colors.white
                              : const Color(0xFF0F172A))
                              .withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/image3.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Ikenas',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 32),
              CircularProgressIndicator(
                color: Colors.blueAccent,
                strokeWidth: 2,
              ),
              const SizedBox(height: 16),
              Text(
                'Checking session...',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
