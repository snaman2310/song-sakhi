import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'theme.dart';

/// Soft blurred ambient spheres behind the onboarding screens.
class GlowBackdrop extends StatelessWidget {
  const GlowBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: Container(
                width: 280,
                height: 280,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x331DB954),
                ),
              ),
            ),
          ),
          Positioned(
            top: 150,
            left: 30,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x26C385FF),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: -30,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x1A53E076),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small pill with a pulsing dot (e.g. "V2.4 PRO • REALTIME AI", "LIVE READY").
class StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final bool filled;
  const StatusPill({
    required this.text,
    this.color = AppColors.primary,
    this.filled = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.14) : AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(999),
        border: filled ? Border.all(color: color.withValues(alpha: 0.35)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color, blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 8),
          Text(text,
              style: AppText.labelSmall(color).copyWith(color: color)),
        ],
      ),
    );
  }
}

/// Animated multi-colour equalizer bars used in the floating nudge button.
class NeonBars extends StatefulWidget {
  final bool animate;
  const NeonBars({this.animate = true, super.key});

  @override
  State<NeonBars> createState() => _NeonBarsState();
}

class _NeonBarsState extends State<NeonBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  static const colors = [
    AppColors.neonGreen,
    AppColors.neonCyan,
    AppColors.neonViolet,
    AppColors.neonPink,
    AppColors.neonAmber,
  ];
  static const bases = [8.0, 16.0, 22.0, 12.0, 8.0];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(5, (i) {
            final h = widget.animate
                ? bases[i] + 10 * (0.5 + 0.5 * (_c.value * (i % 2 == 0 ? 1 : -1)))
                : bases[i];
            return Container(
              width: 3,
              height: h.clamp(4, 26).toDouble(),
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: colors[i],
                borderRadius: BorderRadius.circular(3),
                boxShadow: [BoxShadow(color: colors[i], blurRadius: 8)],
              ),
            );
          }),
        );
      },
    );
  }
}

/// The centred soundwave "record" hub from the login design.
class SoundwaveLogo extends StatefulWidget {
  const SoundwaveLogo({super.key});

  @override
  State<SoundwaveLogo> createState() => _SoundwaveLogoState();
}

class _SoundwaveLogoState extends State<SoundwaveLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..repeat(reverse: true);

  static const colors = [
    AppColors.tertiary,
    AppColors.primary,
    AppColors.primaryContainer,
    AppColors.tertiaryContainer,
    AppColors.primary,
    AppColors.tertiary,
  ];
  static const bases = [16.0, 32.0, 44.0, 28.0, 40.0, 20.0];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return SizedBox(
          width: 128,
          height: 128,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x5541A855F7),
                  ),
                ),
              ),
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceLowest,
                  boxShadow: const [BoxShadow(blurRadius: 20, color: Color(0x66000000))],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceLow,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white10, width: 6),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white12, width: 6),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: List.generate(6, (i) {
                            final h = bases[i] +
                                8 * (_c.value * (i.isEven ? 1 : -1));
                            return Container(
                              width: 6,
                              height: h.clamp(6, 46).toDouble(),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: colors[i],
                                borderRadius: BorderRadius.circular(6),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Frosted mirror-glass container used for the modal sheets.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0x8C141419),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: const Color(0x2EFFFFFF)),
            boxShadow: const [
              BoxShadow(color: Color(0x80000000), blurRadius: 40, offset: Offset(0, 16)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Network image with a tasteful gradient fallback (Stitch image URLs can expire).
class SmartImage extends StatelessWidget {
  final String url;
  final List<Color> fallback;
  const SmartImage({required this.url, this.fallback = const [AppColors.surfaceHigh, AppColors.surfaceLowest], super.key});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: fallback,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.album, color: Colors.white24, size: 28),
        ),
      ),
    );
  }
}

/// Step progress header (label left, percent right, track below).
class StepProgress extends StatelessWidget {
  final String left;
  final String right;
  final double fraction;
  const StepProgress({
    required this.left,
    required this.right,
    required this.fraction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(left.toUpperCase(), style: AppText.labelSmall(AppColors.primary)),
            Text(right, style: AppText.labelSmall(AppColors.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                Container(color: AppColors.surfaceHigh),
                FractionallySizedBox(
                  widthFactor: fraction,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [BoxShadow(color: Color(0x8053E076), blurRadius: 8)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
