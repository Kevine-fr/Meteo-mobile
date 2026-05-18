import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../main.dart';

/// =====================================================
///  ARC DU SOLEIL (avec position calculée)
/// =====================================================
class SunArc extends StatelessWidget {
  final double progress; // 0..1
  const SunArc({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1800),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) => SizedBox(
        height: 96,
        child: CustomPaint(
          painter: _SunArcPainter(t),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SunArcPainter extends CustomPainter {
  final double t;
  _SunArcPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(8, h - 10)
      ..quadraticBezierTo(w / 2, -15, w - 8, h - 10);

    // background path (dashed)
    final bg = Paint()
      ..color = AppColors.borderStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    _drawDashedPath(canvas, path, bg, [3, 4]);

    // done path
    final metric = path.computeMetrics().first;
    final donePath = metric.extractPath(0, metric.length * t);
    final done = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.accent2, AppColors.accent, AppColors.accent2],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    canvas.drawPath(donePath, done);

    // sun dot at current position
    final tan = metric.getTangentForOffset(metric.length * t);
    if (tan != null) {
      final glow = Paint()
        ..color = AppColors.accent.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(tan.position, 12, glow);
      canvas.drawCircle(tan.position, 6, Paint()..color = AppColors.accent);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, List<double> pattern) {
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      int i = 0;
      while (distance < metric.length) {
        final seg = pattern[i % pattern.length];
        if (draw) {
          canvas.drawPath(metric.extractPath(distance, distance + seg), paint);
        }
        distance += seg;
        draw = !draw;
        i++;
      }
    }
  }

  @override
  bool shouldRepaint(_SunArcPainter old) => old.t != t;
}

/// =====================================================
///  BOUSSOLE DU VENT
/// =====================================================
class WindCompass extends StatelessWidget {
  final double degrees;
  const WindCompass({super.key, required this.degrees});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: degrees),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.elasticOut,
        builder: (_, deg, __) => CustomPaint(
          painter: _CompassPainter(deg),
          size: const Size.square(76),
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final double degrees;
  _CompassPainter(this.degrees);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 2;

    // ring
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.borderStrong,
    );

    // ticks (16 directions)
    final tickPaint = Paint()..color = AppColors.fgDim;
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * 2 * math.pi - math.pi / 2;
      final isCard = i % 4 == 0;
      final inner = r - (isCard ? 6 : 3);
      canvas.drawLine(
        c + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        c + Offset(math.cos(angle) * r, math.sin(angle) * r),
        tickPaint..strokeWidth = isCard ? 1.2 : 0.6,
      );
    }

    // N marker
    final textPainter = TextPainter(
      text: TextSpan(text: 'N', style: AppText.mono(9, color: AppColors.accent, letter: 0.4)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(c.dx - textPainter.width / 2, 0));

    // needle (pointing where the wind comes FROM)
    final angle = (degrees - 90) * math.pi / 180;
    final tipLen = r - 8;
    final tip = c + Offset(math.cos(angle) * tipLen, math.sin(angle) * tipLen);
    final back = c - Offset(math.cos(angle) * 8, math.sin(angle) * 8);
    final perp = Offset(-math.sin(angle), math.cos(angle));

    final needlePath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(back.dx + perp.dx * 3, back.dy + perp.dy * 3)
      ..lineTo(back.dx - perp.dx * 3, back.dy - perp.dy * 3)
      ..close();
    canvas.drawPath(
      needlePath,
      Paint()
        ..shader = LinearGradient(
          colors: [AppColors.accent, AppColors.accent.withOpacity(0.4)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // center
    canvas.drawCircle(c, 4, Paint()..color = AppColors.accent);
    canvas.drawCircle(
      c,
      8,
      Paint()
        ..color = AppColors.accent.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(_CompassPainter old) => old.degrees != degrees;
}

/// =====================================================
///  JAUGE UV CIRCULAIRE
/// =====================================================
class UVGauge extends StatelessWidget {
  final double uv;
  const UVGauge({super.key, required this.uv});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(alignment: Alignment.center, children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: uv.clamp(0.0, 11.0)),
          duration: const Duration(milliseconds: 1400),
          curve: Curves.easeOutCubic,
          builder: (_, val, __) => CustomPaint(
            painter: _UVPainter(val),
            size: const Size.square(76),
          ),
        ),
        AnimatedNumberStatic(
          value: uv,
          style: AppText.display(22, w: FontWeight.w400),
        ),
      ]),
    );
  }
}

class _UVPainter extends CustomPainter {
  final double uv;
  _UVPainter(this.uv);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = AppColors.border,
    );

    final sweep = (uv / 11) * 2 * math.pi;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [AppColors.good, AppColors.accent, AppColors.warn],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_UVPainter old) => old.uv != uv;
}

// Static animated number for inside other widgets
class AnimatedNumberStatic extends StatelessWidget {
  final double value;
  final int decimals;
  final TextStyle? style;
  const AnimatedNumberStatic({
    super.key,
    required this.value,
    this.decimals = 0,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 1300),
      curve: Curves.easeOutCubic,
      builder: (_, val, __) => Text(val.toStringAsFixed(decimals), style: style),
    );
  }
}

/// =====================================================
///  GRAPHIQUE TEMPÉRATURE HORAIRE (ligne + barres pluie)
/// =====================================================
class HourlyChart extends StatefulWidget {
  final List<HourPoint> hours;
  const HourlyChart({super.key, required this.hours});
  @override
  State<HourlyChart> createState() => _HourlyChartState();
}

class HourPoint {
  final int hour;
  final double temp;
  final double precipMm;
  final int rainChance;
  HourPoint({required this.hour, required this.temp, required this.precipMm, required this.rainChance});
}

class _HourlyChartState extends State<HourlyChart> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _ChartPainter(widget.hours, _ctrl.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<HourPoint> hours;
  final double t;
  _ChartPainter(this.hours, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (hours.isEmpty) return;
    const padX = 12.0, padY = 18.0;
    final w = size.width - padX * 2;
    final h = size.height - padY * 2;
    final temps = hours.map((e) => e.temp).toList();
    final tMin = (temps.reduce(math.min)) - 2;
    final tMax = (temps.reduce(math.max)) + 2;

    // grid lines
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = padY + h * (i / 3);
      _drawDashed(canvas, Offset(0, y), Offset(size.width, y), grid, 3, 4);
    }

    // rain bars
    final rainPaint = Paint()..color = AppColors.rain.withOpacity(0.55);
    for (int i = 0; i < hours.length; i++) {
      final x = padX + i * (w / (hours.length - 1));
      final barH = (hours[i].precipMm * 50).clamp(0, 40).toDouble();
      if (barH > 0.5) {
        final progress = (t * 2 - i / hours.length).clamp(0.0, 1.0);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 2, size.height - padY - barH * progress, 4, barH * progress),
            const Radius.circular(2),
          ),
          rainPaint,
        );
      }
    }

    // path
    final pts = <Offset>[];
    for (int i = 0; i < hours.length; i++) {
      final x = padX + i * (w / (hours.length - 1));
      final ratio = (hours[i].temp - tMin) / (tMax - tMin);
      final y = padY + h * (1 - ratio);
      pts.add(Offset(x, y));
    }

    // area gradient under the curve
    final areaPath = Path()..moveTo(pts.first.dx, size.height - padY);
    for (final p in pts) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath.lineTo(pts.last.dx, size.height - padY);
    areaPath.close();

    final areaProgress = math.min(1.0, t * 1.5);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * areaProgress, size.height));
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.accent.withOpacity(0.35), AppColors.accent.withOpacity(0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.restore();

    // line
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      linePath.lineTo(pts[i].dx, pts[i].dy);
    }
    final lineMetric = linePath.computeMetrics().first;
    final visibleLine = lineMetric.extractPath(0, lineMetric.length * t);
    canvas.drawPath(
      visibleLine,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 0.5),
    );

    // labels x (every 6h)
    for (int i = 0; i < hours.length; i += 6) {
      final x = padX + i * (w / (hours.length - 1));
      final tp = TextPainter(
        text: TextSpan(
          text: '${hours[i].hour.toString().padLeft(2, '0')}h',
          style: AppText.mono(9, color: AppColors.fgFaint),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - 12));
    }
  }

  void _drawDashed(Canvas c, Offset a, Offset b, Paint p, double on, double off) {
    final total = (b - a).distance;
    final dir = (b - a) / total;
    double d = 0;
    while (d < total) {
      final s = a + dir * d;
      final e = a + dir * math.min(d + on, total);
      c.drawLine(s, e, p);
      d += on + off;
    }
  }

  @override
  bool shouldRepaint(_ChartPainter o) => o.t != t;
}

/// =====================================================
///  ICÔNES MÉTÉO (peinture vectorielle)
/// =====================================================
class WeatherIcon extends StatelessWidget {
  final int code;
  final bool isDay;
  final double size;
  final Color? color;
  const WeatherIcon({super.key, required this.code, this.isDay = true, this.size = 28, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.fg;
    if (_rainCodes.contains(code)) return Icon(Icons.water_drop_outlined, size: size, color: c);
    if (_snowCodes.contains(code)) return Icon(Icons.ac_unit, size: size, color: c);
    if (_thunderCodes.contains(code)) return Icon(Icons.flash_on, size: size, color: c);
    if (_fogCodes.contains(code)) return Icon(Icons.cloud_outlined, size: size, color: c.withOpacity(0.6));
    if (_cloudCodes.contains(code)) return Icon(Icons.cloud, size: size, color: c);
    if (_partlyCodes.contains(code)) {
      return Icon(isDay ? Icons.wb_cloudy_outlined : Icons.nightlight_round_outlined, size: size, color: c);
    }
    return Icon(isDay ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined, size: size, color: c);
  }

  static const _partlyCodes = {1003};
  static const _cloudCodes = {1006, 1009};
  static const _fogCodes = {1030, 1135, 1147};
  static const _rainCodes = {1063, 1150, 1153, 1180, 1183, 1186, 1189, 1192, 1195, 1240, 1243, 1246,};
  static const _snowCodes = {1066, 1114, 1210, 1213, 1216, 1219, 1222, 1225, 1255, 1258};
  static const _thunderCodes = {1087, 1273, 1276, 1279, 1282};
}

/// =====================================================
///  PHASE DE LUNE (peinture)
/// =====================================================
class MoonVisual extends StatelessWidget {
  final int illumination; // 0..100
  final String phase;
  final double size;
  const MoonVisual({super.key, required this.illumination, required this.phase, this.size = 90});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: illumination / 100),
        duration: const Duration(milliseconds: 1400),
        curve: Curves.easeOutCubic,
        builder: (_, t, __) => CustomPaint(
          painter: _MoonPainter(t, phase),
          size: Size.square(size),
        ),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  final double illum; // 0..1
  final String phase;
  _MoonPainter(this.illum, this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // shadow base
    canvas.drawCircle(
      c,
      r,
      Paint()..color = const Color(0xFF1A1D28),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [const Color(0xFF3A3F4D), const Color(0xFF1A1D28)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // lit portion clipped
    if (illum > 0.01) {
      canvas.save();
      // For waxing crescent, the lit part is on the right
      final isWaning = phase.toLowerCase().contains('waning') || phase.toLowerCase().contains('décroiss');
      final offsetX = isWaning ? -r * 2 * (1 - illum) : r * 2 * (1 - illum);
      final clipRect = Rect.fromCircle(center: c + Offset(offsetX, 0), radius: r);
      canvas.clipPath(Path()..addOval(clipRect));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            colors: [const Color(0xFFE8E6E0), const Color(0xFFA8A59B)],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
      canvas.restore();
    }

    // glow
    canvas.drawCircle(
      c,
      r + 4,
      Paint()
        ..color = AppColors.fg.withOpacity(0.06 * illum)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
  }

  @override
  bool shouldRepaint(_MoonPainter o) => o.illum != illum;
}
