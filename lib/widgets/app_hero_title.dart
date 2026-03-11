import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

/// Animated hero title widget used on auth/lock pages.
/// Features a pulsing glow icon, gradient background, and staggered entrance.
class AppHeroTitle extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const AppHeroTitle({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  State<AppHeroTitle> createState() => _AppHeroTitleState();
}

class _AppHeroTitleState extends State<AppHeroTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Animated pulsing icon with gradient glow
        FadeInDown(
          duration: const Duration(milliseconds: 700),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primary,
                        Color.lerp(primary, secondary, 0.6)!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(isDark
                            ? 0.5 * _pulseAnimation.value
                            : 0.3 * _pulseAnimation.value),
                        blurRadius: 36 * _pulseAnimation.value,
                        spreadRadius: 4 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    size: 46,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
        FadeInUp(
          duration: const Duration(milliseconds: 600),
          delay: const Duration(milliseconds: 200),
          child: Text(
            widget.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
        ),
        const SizedBox(height: 10),
        FadeInUp(
          duration: const Duration(milliseconds: 600),
          delay: const Duration(milliseconds: 350),
          child: Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      isDark ? const Color(0xFF8892A4) : Colors.grey.shade600,
                  letterSpacing: 0.3,
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}
