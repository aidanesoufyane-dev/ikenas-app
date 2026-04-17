import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthScreen(key: UniqueKey())),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white24 : Colors.black26;
    final mottoColor = isDark ? Colors.white38 : Colors.black45;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DeepSpaceBackground(
        showOrbs: true,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Premium Logo Container
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
                              : Colors.white),
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
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                                color: (isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A))
                                    .withValues(alpha: 0.3),
                                blurRadius: 20),
                          ],
                        ),
                        child: Image.asset('assets/images/image3.png',
                            width: 48, height: 48, fit: BoxFit.contain),
                      ),
                    ),
                  )
                      .animate()
                      .scale(duration: 800.ms, curve: Curves.elasticOut)
                      .shimmer(delay: 5.seconds, duration: 10.seconds),

                  const SizedBox(height: 40),

                  // App Name with Ultimate Contrast
                  Text(
                    'Ikenas',
                    style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                  const SizedBox(height: 8),

                  // Sub-brand / Version
                  Text(
                    AppLocalizations.of(context)!.translate('app_school_2026'),
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 24),

                  // Motto
                  Text(
                    AppLocalizations.of(context)!.translate('app_motto'),
                    style: TextStyle(
                      color: mottoColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),

            // Loading Bottom
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.blueAccent,
                      strokeWidth: 2,
                    ),
                  ).animate().fadeIn(delay: 1000.ms),
                  const SizedBox(height: 32),
                  Text(
                    AppLocalizations.of(context)!.translate('securing_portal'),
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ).animate().fadeIn(delay: 1200.ms),
                  const SizedBox(height: 48),
                  Text(
                    AppLocalizations.of(context)!.translate('copyright_text'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondaryTextColor.withValues(alpha: 0.4),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
