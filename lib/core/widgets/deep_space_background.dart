import 'package:flutter/material.dart';

class DeepSpaceBackground extends StatelessWidget {
  final Widget child;
  final bool showOrbs;

  const DeepSpaceBackground({
    super.key,
    required this.child,
    this.showOrbs = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Dynamic Ultimate Radial Background
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
              center: const Alignment(1.0, -1.0),
              radius: 1.5,
            ),
          ),
        ),

        if (showOrbs) ...[
          _buildOrb(
            top: -100,
            right: -100,
            color: isDark
                ? Colors.blue.withValues(alpha: 0.1)
                : Colors.blueAccent.withValues(alpha: 0.05),
          ),
          _buildOrb(
            bottom: -150,
            left: -100,
            color: isDark
                ? Colors.indigo.withValues(alpha: 0.1)
                : Colors.deepPurpleAccent.withValues(alpha: 0.05),
          ),
        ],

        Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: child,
        ),
      ],
    );
  }

  Widget _buildOrb(
      {double? top,
      double? bottom,
      double? left,
      double? right,
      required Color color}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: 400,
        height: 400,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
