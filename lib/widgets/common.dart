import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../main.dart';

/// =====================================================
///  CHIFFRE QUI ROULE (animé)
/// =====================================================
class AnimatedNumber extends StatelessWidget {
  final double value;
  final int decimals;
  final TextStyle? style;
  final String suffix;
  final Duration duration;

  const AnimatedNumber({
    super.key,
    required this.value,
    this.decimals = 0,
    this.style,
    this.suffix = '',
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, _) {
        return Text('${val.toStringAsFixed(decimals)}$suffix', style: style);
      },
    );
  }
}

/// =====================================================
///  CARTE EN VERRE
/// =====================================================
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool highlight;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: highlight ? AppColors.cardHover : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight ? AppColors.accent.withOpacity(0.4) : AppColors.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// =====================================================
///  TITRE DE SECTION (mono uppercase)
/// =====================================================
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Text(text.toUpperCase(), style: AppText.label()),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: AppColors.border)),
        ],
      ),
    );
  }
}

/// =====================================================
///  CARTEAU STAT (label + grande valeur)
/// =====================================================
class StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final String unit;
  final String? subtitle;
  final int decimals;
  final Widget? customChild;
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit = '',
    this.subtitle,
    this.decimals = 0,
    this.customChild,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Icon(icon, size: 12, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(label.toUpperCase(),
                style: AppText.mono(9.5, color: AppColors.fgDim, letter: 1.8)),
          ]),
          const SizedBox(height: 10),
          if (customChild != null) customChild! else
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                AnimatedNumber(
                  value: value,
                  decimals: decimals,
                  style: AppText.display(28, w: FontWeight.w300),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Text(unit, style: AppText.body(12, color: AppColors.fgDim)),
                ],
              ],
            ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: AppText.mono(10, color: AppColors.fgFaint, letter: 0.6)),
          ],
        ],
      ),
    );
  }
}

/// =====================================================
///  FOND ATMOSPHÉRIQUE (gradient mesh + grille)
/// =====================================================
class AtmosphereBackground extends StatelessWidget {
  final String conditionText;
  final bool isDay;
  const AtmosphereBackground({super.key, required this.conditionText, required this.isDay});

  @override
  Widget build(BuildContext context) {
    final cond = conditionText.toLowerCase();
    final isRainy = cond.contains('pluie') || cond.contains('averse') || cond.contains('bruine');
    final isSnowy = cond.contains('neige');
    final isSunny = (cond.contains('soleil') || cond.contains('ensoleill')) && isDay;

    Color glow1 = AppColors.accent;
    Color glow2 = AppColors.accent2;
    if (isRainy) {
      glow1 = AppColors.rain;
      glow2 = AppColors.accent2;
    } else if (isSunny) {
      glow1 = const Color(0xFFE8B86E);
      glow2 = AppColors.accent;
    } else if (isSnowy) {
      glow1 = const Color(0xFFB8C4D8);
      glow2 = AppColors.accent2;
    }

    return Stack(children: [
      // Base
      Positioned.fill(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 1200),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.bg0, AppColors.bg1, AppColors.bg0],
              stops: [0, 0.5, 1],
            ),
          ),
        ),
      ),
      // Glows
      Positioned(
        top: -120,
        right: -80,
        child: _GlowOrb(color: glow1, size: 380),
      ),
      Positioned(
        bottom: -120,
        left: -80,
        child: _GlowOrb(color: glow2, size: 320, opacity: 0.18),
      ),
      // Grille
      Positioned.fill(
        child: CustomPaint(painter: _GridPainter()),
      ),
      // Particules selon la météo
      if (isRainy) const Positioned.fill(child: _RainParticles()),
      if (isSnowy) const Positioned.fill(child: _SnowParticles()),
    ]);
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _GlowOrb({required this.color, required this.size, this.opacity = 0.22});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) => Opacity(
        opacity: t,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withOpacity(opacity), color.withOpacity(0)],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8E6E0).withOpacity(0.04)
      ..strokeWidth = 1;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// =====================================================
///  PARTICULES (pluie & neige)
/// =====================================================
class _RainParticles extends StatefulWidget {
  const _RainParticles();
  @override
  State<_RainParticles> createState() => _RainParticlesState();
}

class _RainParticlesState extends State<_RainParticles> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<_Drop> _drops = [];
  final _rand = math.Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 60; i++) {
      _drops.add(_Drop(
        x: _rand.nextDouble(),
        y: _rand.nextDouble(),
        speed: 0.6 + _rand.nextDouble() * 0.8,
        len: 14 + _rand.nextDouble() * 12,
      ));
    }
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _RainPainter(_drops, _ctrl.value),
        size: Size.infinite,
      ),
    );
  }
}

class _Drop {
  double x, y, speed, len;
  _Drop({required this.x, required this.y, required this.speed, required this.len});
}

class _RainPainter extends CustomPainter {
  final List<_Drop> drops;
  final double t;
  _RainPainter(this.drops, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.rain.withOpacity(0.35)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (final d in drops) {
      final y = ((d.y + t * d.speed) % 1.1) * size.height - 20;
      final x = d.x * size.width;
      canvas.drawLine(Offset(x, y), Offset(x, y + d.len), paint);
    }
  }

  @override
  bool shouldRepaint(_RainPainter o) => true;
}

class _SnowParticles extends StatefulWidget {
  const _SnowParticles();
  @override
  State<_SnowParticles> createState() => _SnowParticlesState();
}

class _SnowParticlesState extends State<_SnowParticles> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<_Flake> _flakes = [];
  final _rand = math.Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 40; i++) {
      _flakes.add(_Flake(
        x: _rand.nextDouble(),
        y: _rand.nextDouble(),
        speed: 0.05 + _rand.nextDouble() * 0.15,
        size: 1.5 + _rand.nextDouble() * 2,
        wobble: _rand.nextDouble() * math.pi * 2,
      ));
    }
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: _SnowPainter(_flakes, _ctrl.value),
        size: Size.infinite,
      ),
    );
  }
}

class _Flake {
  double x, y, speed, size, wobble;
  _Flake({required this.x, required this.y, required this.speed, required this.size, required this.wobble});
}

class _SnowPainter extends CustomPainter {
  final List<_Flake> flakes;
  final double t;
  _SnowPainter(this.flakes, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.fg.withOpacity(0.5);
    for (final f in flakes) {
      final y = ((f.y + t * f.speed * 8) % 1.1) * size.height - 10;
      final x = (f.x + math.sin((t * 2 * math.pi) + f.wobble) * 0.03) * size.width;
      canvas.drawCircle(Offset(x, y), f.size, paint);
    }
  }

  @override
  bool shouldRepaint(_SnowPainter o) => true;
}

/// =====================================================
///  TAB NAVIGATION (bas) avec indicateur animé
/// =====================================================
class AnimatedBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const AnimatedBottomNav({super.key, required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.wb_sunny_outlined, 'Aujourd\'hui'),
    (Icons.access_time_rounded, 'Horaire'),
    (Icons.calendar_today_rounded, 'Prévisions'),
    (Icons.bubble_chart_outlined, 'Détails'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, MediaQuery.of(context).padding.bottom + 14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg2.withOpacity(0.72),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(7),
        child: LayoutBuilder(builder: (ctx, c) {
          final itemW = (c.maxWidth - 14) / _items.length;
          return SizedBox(
            height: 56,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                  left: currentIndex * itemW,
                  top: 0,
                  bottom: 0,
                  width: itemW,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                    ),
                  ),
                ),
                Row(
                  children: List.generate(_items.length, (i) {
                    final active = i == currentIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onTap(i),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: active ? 1.1 : 1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              child: Icon(
                                _items[i].$1,
                                size: 18,
                                color: active ? AppColors.accent : AppColors.fgDim,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _items[i].$2.toUpperCase(),
                              style: AppText.mono(8.5,
                                  color: active ? AppColors.accent : AppColors.fgDim,
                                  letter: 1.0),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// =====================================================
///  ENTRÉE STAGGÉRÉE des éléments (slide + fade)
/// =====================================================
class StaggeredEntry extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;
  const StaggeredEntry({
    super.key,
    required this.child,
    required this.index,
    this.baseDelay = const Duration(milliseconds: 60),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + index * 30),
      curve: Curves.easeOutCubic,
      builder: (_, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 16),
          child: c,
        ),
      ),
      child: child,
    );
  }
}
