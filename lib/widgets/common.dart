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
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(7),
        child: LayoutBuilder(builder: (ctx, c) {
          // c.maxWidth est déjà la largeur intérieure (padding 7 appliqué)
          final itemW = c.maxWidth / _items.length;
          return SizedBox(
            height: 56,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 550),
                  // easeOutBack : léger rebond, pas de dépassement excessif
                  curve: Curves.easeOutBack,
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