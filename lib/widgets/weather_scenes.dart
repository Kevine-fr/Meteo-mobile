import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../main.dart';

/// =====================================================
///  SCÈNES MÉTÉO - 13 ambiances animées distinctes
/// =====================================================
enum WeatherScene {
  sunnyDay,
  clearNight,
  partlyCloudyDay,
  partlyCloudyNight,
  cloudy,
  overcast,
  fog,
  lightRain,
  drizzle,
  rain,
  heavyRain,
  snow,
  heavySnow,
  blizzard,
  sleet,
  thunder,
  thunderRain,
}

WeatherScene sceneFromCode(int code, bool isDay) {
  if (code == 1000) return isDay ? WeatherScene.sunnyDay : WeatherScene.clearNight;
  if (code == 1003) return isDay ? WeatherScene.partlyCloudyDay : WeatherScene.partlyCloudyNight;
  if (code == 1006) return WeatherScene.cloudy;
  if (code == 1009) return WeatherScene.overcast;

  if ({1030, 1135, 1147}.contains(code)) return WeatherScene.fog;
  if ({1114, 1117}.contains(code)) return WeatherScene.blizzard;
  if ({1279, 1282}.contains(code)) return WeatherScene.thunder;
  if ({1087, 1273, 1276}.contains(code)) return WeatherScene.thunderRain;
  if ({1072, 1150, 1153, 1168, 1171}.contains(code)) return WeatherScene.drizzle;
  if ({1069, 1198, 1201, 1204, 1207, 1237, 1249, 1252, 1261, 1264}.contains(code)) return WeatherScene.sleet;
  if ({1066, 1210, 1213, 1255}.contains(code)) return WeatherScene.snow;
  if ({1216, 1219, 1222, 1225, 1258}.contains(code)) return WeatherScene.heavySnow;
  if ({1063, 1180}.contains(code)) return WeatherScene.lightRain;
  if ({1183, 1186, 1189, 1240}.contains(code)) return WeatherScene.rain;
  if ({1192, 1195, 1243, 1246}.contains(code)) return WeatherScene.heavyRain;
  return WeatherScene.cloudy;
}

/// =====================================================
///  WIDGET PRINCIPAL - fondu entre scènes
/// =====================================================
class WeatherBackground extends StatelessWidget {
  final int conditionCode;
  final bool isDay;
  const WeatherBackground({super.key, required this.conditionCode, required this.isDay});

  @override
  Widget build(BuildContext context) {
    final scene = sceneFromCode(conditionCode, isDay);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 1500),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey(scene),
        child: _buildScene(scene),
      ),
    );
  }

  Widget _buildScene(WeatherScene scene) {
    switch (scene) {
      case WeatherScene.sunnyDay:           return const _SunnyDayScene();
      case WeatherScene.clearNight:         return const _ClearNightScene();
      case WeatherScene.partlyCloudyDay:    return const _PartlyCloudyScene(isDay: true);
      case WeatherScene.partlyCloudyNight:  return const _PartlyCloudyScene(isDay: false);
      case WeatherScene.cloudy:             return const _CloudyScene(density: 0.6);
      case WeatherScene.overcast:           return const _CloudyScene(density: 1.0);
      case WeatherScene.fog:                return const _FogScene();
      case WeatherScene.lightRain:          return const _RainScene(intensity: 0.4);
      case WeatherScene.drizzle:            return const _RainScene(intensity: 0.3, drops: 40);
      case WeatherScene.rain:               return const _RainScene(intensity: 0.7);
      case WeatherScene.heavyRain:          return const _RainScene(intensity: 1.0, drops: 120);
      case WeatherScene.snow:               return const _SnowScene(intensity: 0.6);
      case WeatherScene.heavySnow:          return const _SnowScene(intensity: 1.0);
      case WeatherScene.blizzard:           return const _SnowScene(intensity: 1.0, blizzard: true);
      case WeatherScene.sleet:              return const _SleetScene();
      case WeatherScene.thunder:            return const _ThunderScene(withRain: false);
      case WeatherScene.thunderRain:        return const _ThunderScene(withRain: true);
    }
  }
}

/// =====================================================
///  GRADIENT DE BASE + GRILLE (partagé)
/// =====================================================
class _SceneBase extends StatelessWidget {
  final List<Color> colors;
  final Widget? child;
  const _SceneBase({required this.colors, this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
          ),
        ),
      ),
      Positioned.fill(child: CustomPaint(painter: _GridPainter())),
      if (child != null) Positioned.fill(child: child!),
    ]);
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8E6E0).withOpacity(0.035)
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
///  ☀️  JOUR ENSOLEILLÉ
/// =====================================================
class _SunnyDayScene extends StatefulWidget {
  const _SunnyDayScene();
  @override
  State<_SunnyDayScene> createState() => _SunnyDaySceneState();
}

class _SunnyDaySceneState extends State<_SunnyDayScene> with TickerProviderStateMixin {
  late final AnimationController _rays = AnimationController(vsync: this, duration: const Duration(seconds: 80))..repeat();
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  late final AnimationController _dust = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  final List<_Dust> _particles = List.generate(20, (_) => _Dust.random());

  @override
  void dispose() {
    _rays.dispose();
    _pulse.dispose();
    _dust.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SceneBase(
      colors: const [Color(0xFF1F1610), Color(0xFF120D0E), Color(0xFF0A0A12)],
      child: Stack(children: [
        // grand halo chaud en haut à droite
        Positioned(
          top: -180, right: -130,
          child: Container(
            width: 460, height: 460,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [const Color(0xFFE8B86E).withOpacity(0.28), const Color(0xFFE8B86E).withOpacity(0)],
              ),
            ),
          ),
        ),
        // soleil
        Positioned(
          top: 40, right: 30,
          child: AnimatedBuilder(
            animation: Listenable.merge([_rays, _pulse]),
            builder: (_, __) => Transform.scale(
              scale: 0.96 + _pulse.value * 0.07,
              child: CustomPaint(
                size: const Size(130, 130),
                painter: _SunPainter(angle: _rays.value * 2 * math.pi),
              ),
            ),
          ),
        ),
        // particules dorées qui flottent
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _dust,
            builder: (_, __) => CustomPaint(
              painter: _DustPainter(_particles, _dust.value, color: const Color(0xFFE8B86E)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Dust {
  double x, y, speed, size, phase;
  _Dust({required this.x, required this.y, required this.speed, required this.size, required this.phase});
  factory _Dust.random() {
    final r = math.Random();
    return _Dust(
      x: r.nextDouble(),
      y: r.nextDouble(),
      speed: 0.2 + r.nextDouble() * 0.4,
      size: 0.8 + r.nextDouble() * 1.6,
      phase: r.nextDouble() * 2 * math.pi,
    );
  }
}

class _DustPainter extends CustomPainter {
  final List<_Dust> particles;
  final double t;
  final Color color;
  _DustPainter(this.particles, this.t, {required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = ((p.y - t * p.speed) % 1.1) * size.height;
      final wobble = math.sin(t * 2 * math.pi + p.phase) * 8;
      final x = p.x * size.width + wobble;
      canvas.drawCircle(
        Offset(x, y),
        p.size,
        Paint()..color = color.withOpacity(0.3 + 0.3 * math.sin(t * 2 * math.pi + p.phase)),
      );
    }
  }

  @override
  bool shouldRepaint(_DustPainter o) => o.t != t;
}

class _SunPainter extends CustomPainter {
  final double angle;
  _SunPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // glow
    canvas.drawCircle(
      c, r * 1.3,
      Paint()
        ..color = const Color(0xFFE8B86E).withOpacity(0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    // rayons
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    final ray = Paint()
      ..color = const Color(0xFFE8B86E).withOpacity(0.5)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 12; i++) {
      final a = i * (math.pi / 6);
      final inner = r * 0.5;
      final outer = r * (i.isEven ? 0.92 : 0.78);
      canvas.drawLine(
        Offset(math.cos(a) * inner, math.sin(a) * inner),
        Offset(math.cos(a) * outer, math.sin(a) * outer),
        ray,
      );
    }
    canvas.restore();

    // coeur du soleil
    canvas.drawCircle(
      c, r * 0.42,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFF4D49B), const Color(0xFFD4A574)],
        ).createShader(Rect.fromCircle(center: c, radius: r * 0.42)),
    );
  }

  @override
  bool shouldRepaint(_SunPainter o) => o.angle != angle;
}

/// =====================================================
///  🌙  NUIT CLAIRE (étoiles + lune)
/// =====================================================
class _ClearNightScene extends StatefulWidget {
  const _ClearNightScene();
  @override
  State<_ClearNightScene> createState() => _ClearNightSceneState();
}

class _ClearNightSceneState extends State<_ClearNightScene> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  final List<_Star> _stars = List.generate(60, (_) => _Star.random());
  _Shooting? _shooting;
  Timer? _shootingTimer;

  @override
  void initState() {
    super.initState();
    _scheduleShootingStar();
  }

  void _scheduleShootingStar() {
    final r = math.Random();
    _shootingTimer = Timer(Duration(seconds: 12 + r.nextInt(20)), () {
      if (!mounted) return;
      setState(() => _shooting = _Shooting.random());
      Timer(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        setState(() => _shooting = null);
        _scheduleShootingStar();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _shootingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SceneBase(
      colors: const [Color(0xFF1A1F35), Color(0xFF0E1326), Color(0xFF0A0E1A)],
      child: Stack(children: [
        // halo lune
        Positioned(
          top: -100, right: -60,
          child: Container(
            width: 280, height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [const Color(0xFF8EB4D8).withOpacity(0.22), const Color(0xFF8EB4D8).withOpacity(0)],
              ),
            ),
          ),
        ),
        // lune
        Positioned(
          top: 50, right: 36,
          child: CustomPaint(size: const Size(90, 90), painter: _MoonBgPainter()),
        ),
        // étoiles
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(painter: _StarsPainter(_stars, _ctrl.value)),
          ),
        ),
        // étoile filante
        if (_shooting != null)
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOut,
              builder: (_, t, __) => CustomPaint(painter: _ShootingStarPainter(_shooting!, t)),
            ),
          ),
      ]),
    );
  }
}

class _Star {
  double x, y, size, twinklePhase, baseOpacity;
  _Star({required this.x, required this.y, required this.size, required this.twinklePhase, required this.baseOpacity});
  factory _Star.random() {
    final r = math.Random();
    return _Star(
      x: r.nextDouble(),
      y: r.nextDouble() * 0.85,
      size: 0.6 + r.nextDouble() * 1.4,
      twinklePhase: r.nextDouble() * 2 * math.pi,
      baseOpacity: 0.3 + r.nextDouble() * 0.5,
    );
  }
}

class _StarsPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  _StarsPainter(this.stars, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final twinkle = (math.sin(t * 2 * math.pi + s.twinklePhase) + 1) * 0.5;
      final opacity = (s.baseOpacity * (0.4 + twinkle * 0.6)).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        Paint()..color = Colors.white.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter o) => o.t != t;
}

class _MoonBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r + 6, Paint()
      ..color = const Color(0xFF8EB4D8).withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
    canvas.drawCircle(c, r, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [const Color(0xFFE0DCD0), const Color(0xFF8A8780)],
      ).createShader(Rect.fromCircle(center: c, radius: r)));
  }
  @override
  bool shouldRepaint(_) => false;
}

class _Shooting {
  final double startX, startY, dx, dy;
  _Shooting({required this.startX, required this.startY, required this.dx, required this.dy});
  factory _Shooting.random() {
    final r = math.Random();
    return _Shooting(
      startX: r.nextDouble() * 0.6,
      startY: r.nextDouble() * 0.3,
      dx: 0.3 + r.nextDouble() * 0.3,
      dy: 0.15 + r.nextDouble() * 0.15,
    );
  }
}

class _ShootingStarPainter extends CustomPainter {
  final _Shooting s;
  final double t;
  _ShootingStarPainter(this.s, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final head = Offset((s.startX + s.dx * t) * size.width, (s.startY + s.dy * t) * size.height);
    final tail = Offset((s.startX + s.dx * (t - 0.08).clamp(0.0, 1.0)) * size.width,
        (s.startY + s.dy * (t - 0.08).clamp(0.0, 1.0)) * size.height);
    final shader = LinearGradient(
      colors: [Colors.white.withOpacity(0), Colors.white.withOpacity((1 - t).clamp(0.0, 1.0))],
    ).createShader(Rect.fromPoints(tail, head));
    canvas.drawLine(tail, head, Paint()..shader = shader..strokeWidth = 1.5..strokeCap = StrokeCap.round);
    canvas.drawCircle(head, 1.8, Paint()..color = Colors.white.withOpacity((1 - t).clamp(0.0, 1.0)));
  }
  @override
  bool shouldRepaint(_ShootingStarPainter o) => o.t != t;
}

/// =====================================================
///  ⛅  PARTIELLEMENT NUAGEUX (jour ou nuit)
/// =====================================================
class _PartlyCloudyScene extends StatefulWidget {
  final bool isDay;
  const _PartlyCloudyScene({required this.isDay});
  @override
  State<_PartlyCloudyScene> createState() => _PartlyCloudySceneState();
}

class _PartlyCloudySceneState extends State<_PartlyCloudyScene> with TickerProviderStateMixin {
  late final AnimationController _clouds = AnimationController(vsync: this, duration: const Duration(seconds: 180))..repeat();
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
  final List<_Cloud> _data = List.generate(3, (i) => _Cloud.random(layer: i));

  @override
  void dispose() {
    _clouds.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SceneBase(
      colors: widget.isDay
          ? const [Color(0xFF1A2030), Color(0xFF111626), Color(0xFF0A0E1A)]
          : const [Color(0xFF161B2D), Color(0xFF0E1220), Color(0xFF0A0E1A)],
      child: Stack(children: [
        // soleil ou lune partiellement caché
        Positioned(
          top: 50, right: 50,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Transform.scale(
              scale: 0.95 + _pulse.value * 0.05,
              child: widget.isDay
                  ? CustomPaint(size: const Size(80, 80), painter: _SmallSunPainter())
                  : CustomPaint(size: const Size(70, 70), painter: _MoonBgPainter()),
            ),
          ),
        ),
        // étoiles si nuit
        if (!widget.isDay)
          Positioned.fill(
            child: CustomPaint(
              painter: _StarsPainter(
                List.generate(35, (_) => _Star.random()),
                _clouds.value,
              ),
            ),
          ),
        // nuages
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _clouds,
            builder: (_, __) => CustomPaint(
              painter: _CloudsPainter(_data, _clouds.value, isDay: widget.isDay),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SmallSunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r + 8, Paint()
      ..color = const Color(0xFFE8B86E).withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
    canvas.drawCircle(c, r * 0.65, Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFFF4D49B), const Color(0xFFD4A574)],
      ).createShader(Rect.fromCircle(center: c, radius: r * 0.65)));
  }
  @override
  bool shouldRepaint(_) => false;
}

/// =====================================================
///  ☁️  NUAGEUX / COUVERT
/// =====================================================
class _CloudyScene extends StatefulWidget {
  final double density; // 0.5 nuageux, 1.0 couvert
  const _CloudyScene({required this.density});
  @override
  State<_CloudyScene> createState() => _CloudySceneState();
}

class _CloudySceneState extends State<_CloudyScene> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Cloud> _clouds;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 240))..repeat();
    final count = (5 + widget.density * 5).round();
    _clouds = List.generate(count, (i) => _Cloud.random(layer: i % 3));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.density > 0.8;
    return _SceneBase(
      colors: dark
          ? const [Color(0xFF181B26), Color(0xFF101319), Color(0xFF0A0C12)]
          : const [Color(0xFF1B1F2A), Color(0xFF12151E), Color(0xFF0A0D14)],
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _CloudsPainter(_clouds, _ctrl.value, opacity: 0.45 + widget.density * 0.25),
        ),
      ),
    );
  }
}

class _Cloud {
  double x, y, size, speed, opacity;
  _Cloud({required this.x, required this.y, required this.size, required this.speed, required this.opacity});
  factory _Cloud.random({required int layer}) {
    final r = math.Random();
    // 3 couches : avant-plan (gros, rapide), milieu, arrière-plan
    final layers = [
      (size: 180.0, speed: 1.2, y: 0.35, opacity: 0.55),
      (size: 140.0, speed: 0.85, y: 0.20, opacity: 0.4),
      (size: 220.0, speed: 0.55, y: 0.50, opacity: 0.3),
    ];
    final l = layers[layer % 3];
    return _Cloud(
      x: r.nextDouble(),
      y: l.y + (r.nextDouble() - 0.5) * 0.15,
      size: l.size + r.nextDouble() * 60 - 30,
      speed: l.speed * (0.8 + r.nextDouble() * 0.4),
      opacity: l.opacity * (0.85 + r.nextDouble() * 0.3),
    );
  }
}

class _CloudsPainter extends CustomPainter {
  final List<_Cloud> clouds;
  final double t;
  final double opacity;
  final bool isDay;
  _CloudsPainter(this.clouds, this.t, {this.opacity = 1.0, this.isDay = true});

  @override
  void paint(Canvas canvas, Size size) {
    final cloudColor = isDay ? const Color(0xFFD8D6CE) : const Color(0xFF8A8E9C);
    for (final c in clouds) {
      final actualX = ((c.x + t * c.speed) % 1.3) * size.width - 120;
      final actualY = c.y * size.height;
      _drawCloud(canvas, Offset(actualX, actualY), c.size, c.opacity * opacity, cloudColor);
    }
  }

  void _drawCloud(Canvas canvas, Offset center, double width, double op, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(op * 0.4)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.13);
    final h = width * 0.42;
    canvas.drawOval(Rect.fromCenter(center: center, width: width, height: h), paint);
    canvas.drawCircle(center + Offset(-width * 0.28, -h * 0.15), width * 0.22, paint);
    canvas.drawCircle(center + Offset(0, -h * 0.3), width * 0.27, paint);
    canvas.drawCircle(center + Offset(width * 0.25, -h * 0.1), width * 0.21, paint);
    // bord plus net
    canvas.drawOval(
      Rect.fromCenter(center: center, width: width * 0.95, height: h * 0.95),
      Paint()..color = color.withOpacity(op * 0.15),
    );
  }

  @override
  bool shouldRepaint(_CloudsPainter o) => o.t != t;
}

/// =====================================================
///  🌫️  BROUILLARD / BRUME
/// =====================================================
class _FogScene extends StatefulWidget {
  const _FogScene();
  @override
  State<_FogScene> createState() => _FogSceneState();
}

class _FogSceneState extends State<_FogScene> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SceneBase(
      colors: const [Color(0xFF1C1F26), Color(0xFF15181F), Color(0xFF0E1015)],
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(painter: _FogPainter(_ctrl.value)),
      ),
    );
  }
}

class _FogPainter extends CustomPainter {
  final double t;
  _FogPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // 5 bandes horizontales de brume à différentes hauteurs et vitesses
    final bands = [
      (y: 0.20, speed: 0.25, opacity: 0.06),
      (y: 0.40, speed: 0.35, opacity: 0.08),
      (y: 0.55, speed: 0.20, opacity: 0.07),
      (y: 0.70, speed: 0.45, opacity: 0.05),
      (y: 0.85, speed: 0.30, opacity: 0.06),
    ];
    for (final b in bands) {
      final offsetX = ((t * b.speed) % 1) * size.width;
      final paint = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40)
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0),
            Colors.white.withOpacity(b.opacity),
            Colors.white.withOpacity(b.opacity),
            Colors.white.withOpacity(0),
          ],
          stops: const [0, 0.3, 0.7, 1],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(
        Rect.fromLTWH(-offsetX, b.y * size.height - 30, size.width * 2, 60),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_FogPainter o) => o.t != t;
}

/// =====================================================
///  🌧️  PLUIE (toutes intensités)
/// =====================================================
class _RainScene extends StatefulWidget {
  final double intensity; // 0..1
  final int drops;
  const _RainScene({required this.intensity, this.drops = 70});
  @override
  State<_RainScene> createState() => _RainSceneState();
}

class _RainSceneState extends State<_RainScene> with TickerProviderStateMixin {
  late final AnimationController _rain = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  late final AnimationController _clouds = AnimationController(vsync: this, duration: const Duration(seconds: 200))..repeat();
  late final List<_Drop> _drops;
  final List<_Cloud> _cloudData = List.generate(4, (i) => _Cloud.random(layer: i % 3));
  final _rand = math.Random();

  @override
  void initState() {
    super.initState();
    _drops = List.generate(widget.drops, (_) => _Drop(
      x: _rand.nextDouble(),
      y: _rand.nextDouble(),
      speed: 0.7 + _rand.nextDouble() * 0.5,
      length: 14 + _rand.nextDouble() * (12 + widget.intensity * 14),
      opacity: 0.3 + _rand.nextDouble() * 0.4,
    ));
  }

  @override
  void dispose() {
    _rain.dispose();
    _clouds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.intensity > 0.7;
    return _SceneBase(
      colors: dark
          ? const [Color(0xFF0F1622), Color(0xFF0B1019), Color(0xFF080A12)]
          : const [Color(0xFF131B28), Color(0xFF0E141E), Color(0xFF0A0E16)],
      child: Stack(children: [
        // nuages sombres en haut
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _clouds,
            builder: (_, __) => CustomPaint(
              painter: _CloudsPainter(_cloudData, _clouds.value, opacity: 0.6, isDay: false),
            ),
          ),
        ),
        // pluie
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _rain,
            builder: (_, __) => CustomPaint(
              painter: _RainPainter(_drops, _rain.value, intensity: widget.intensity),
            ),
          ),
        ),
        // léger reflet en bas
        Positioned(
          bottom: 0, left: 0, right: 0, height: 100,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [AppColors.rain.withOpacity(0.08 * widget.intensity), Colors.transparent],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Drop {
  double x, y, speed, length, opacity;
  _Drop({required this.x, required this.y, required this.speed, required this.length, required this.opacity});
}

class _RainPainter extends CustomPainter {
  final List<_Drop> drops;
  final double t;
  final double intensity;
  _RainPainter(this.drops, this.t, {required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in drops) {
      final y = ((d.y + t * d.speed) % 1.15) * size.height - 20;
      final x = d.x * size.width;
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.transparent, AppColors.rain.withOpacity(d.opacity), Colors.transparent],
        ).createShader(Rect.fromLTWH(x - 1, y, 2, d.length))
        ..strokeWidth = 1 + intensity * 0.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, y), Offset(x, y + d.length), paint);
    }
  }

  @override
  bool shouldRepaint(_RainPainter o) => o.t != t;
}

/// =====================================================
///  ❄️  NEIGE (avec variante blizzard)
/// =====================================================
class _SnowScene extends StatefulWidget {
  final double intensity;
  final bool blizzard;
  const _SnowScene({required this.intensity, this.blizzard = false});
  @override
  State<_SnowScene> createState() => _SnowSceneState();
}

class _SnowSceneState extends State<_SnowScene> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
  late final List<_Flake> _flakes;
  final _rand = math.Random();

  @override
  void initState() {
    super.initState();
    final count = (widget.blizzard ? 90 : 45 * widget.intensity).round() + 25;
    _flakes = List.generate(count, (_) => _Flake(
      x: _rand.nextDouble(),
      y: _rand.nextDouble(),
      speed: 0.05 + _rand.nextDouble() * 0.18,
      size: 1.5 + _rand.nextDouble() * (widget.blizzard ? 1.5 : 2.5),
      wobble: _rand.nextDouble() * 2 * math.pi,
      drift: widget.blizzard ? 0.15 + _rand.nextDouble() * 0.15 : 0.02 + _rand.nextDouble() * 0.04,
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SceneBase(
      colors: widget.blizzard
          ? const [Color(0xFF131822), Color(0xFF0D1119), Color(0xFF0A0D14)]
          : const [Color(0xFF1A2030), Color(0xFF131825), Color(0xFF0C1018)],
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _SnowPainter(_flakes, _ctrl.value, blizzard: widget.blizzard),
        ),
      ),
    );
  }
}

class _Flake {
  double x, y, speed, size, wobble, drift;
  _Flake({
    required this.x, required this.y, required this.speed, required this.size,
    required this.wobble, required this.drift,
  });
}

class _SnowPainter extends CustomPainter {
  final List<_Flake> flakes;
  final double t;
  final bool blizzard;
  _SnowPainter(this.flakes, this.t, {required this.blizzard});

  @override
  void paint(Canvas canvas, Size size) {
    for (final f in flakes) {
      final y = ((f.y + t * f.speed * 8) % 1.15) * size.height - 10;
      final wobbleX = math.sin(t * 2 * math.pi + f.wobble) * (blizzard ? 60 : 20);
      final driftX = t * f.drift * size.width * (blizzard ? 4 : 1);
      final x = (f.x * size.width + wobbleX + driftX) % size.width;
      canvas.drawCircle(
        Offset(x, y), f.size,
        Paint()..color = Colors.white.withOpacity(blizzard ? 0.7 : 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(_SnowPainter o) => o.t != t;
}

/// =====================================================
///  🌨️  GRÉSIL / VERGLAS (mix pluie + neige)
/// =====================================================
class _SleetScene extends StatefulWidget {
  const _SleetScene();
  @override
  State<_SleetScene> createState() => _SleetSceneState();
}

class _SleetSceneState extends State<_SleetScene> with TickerProviderStateMixin {
  late final AnimationController _rain = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  late final AnimationController _snow = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
  late final List<_Drop> _drops;
  late final List<_Flake> _flakes;
  final _rand = math.Random();

  @override
  void initState() {
    super.initState();
    _drops = List.generate(30, (_) => _Drop(
      x: _rand.nextDouble(), y: _rand.nextDouble(),
      speed: 0.8, length: 10 + _rand.nextDouble() * 8,
      opacity: 0.3 + _rand.nextDouble() * 0.3,
    ));
    _flakes = List.generate(35, (_) => _Flake(
      x: _rand.nextDouble(), y: _rand.nextDouble(),
      speed: 0.1, size: 1.5,
      wobble: _rand.nextDouble() * 2 * math.pi,
      drift: 0.03,
    ));
  }

  @override
  void dispose() {
    _rain.dispose();
    _snow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SceneBase(
      colors: const [Color(0xFF161C28), Color(0xFF101520), Color(0xFF0A0E16)],
      child: Stack(children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _rain,
            builder: (_, __) => CustomPaint(painter: _RainPainter(_drops, _rain.value, intensity: 0.5)),
          ),
        ),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _snow,
            builder: (_, __) => CustomPaint(painter: _SnowPainter(_flakes, _snow.value, blizzard: false)),
          ),
        ),
      ]),
    );
  }
}

/// =====================================================
///  ⛈️  ORAGE (avec ou sans pluie)
/// =====================================================
class _ThunderScene extends StatefulWidget {
  final bool withRain;
  const _ThunderScene({required this.withRain});
  @override
  State<_ThunderScene> createState() => _ThunderSceneState();
}

class _ThunderSceneState extends State<_ThunderScene> with TickerProviderStateMixin {
  late final AnimationController _rain = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  late final AnimationController _clouds = AnimationController(vsync: this, duration: const Duration(seconds: 220))..repeat();
  late final AnimationController _flash = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final List<_Drop> _drops;
  final List<_Cloud> _cloudData = List.generate(5, (i) => _Cloud.random(layer: i % 3));
  Timer? _nextStrike;
  List<Offset>? _bolt;
  final _rand = math.Random();

  @override
  void initState() {
    super.initState();
    _drops = List.generate(widget.withRain ? 100 : 0, (_) => _Drop(
      x: _rand.nextDouble(), y: _rand.nextDouble(),
      speed: 0.9 + _rand.nextDouble() * 0.4,
      length: 18 + _rand.nextDouble() * 14,
      opacity: 0.4 + _rand.nextDouble() * 0.3,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleNext());
  }

  void _scheduleNext() {
    final delay = 3 + _rand.nextInt(7);
    _nextStrike = Timer(Duration(seconds: delay), _strike);
  }

  void _strike() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    final startX = (0.2 + _rand.nextDouble() * 0.6) * size.width;
    final pts = <Offset>[Offset(startX, 0)];
    double x = startX, y = 0;
    final maxY = size.height * (0.4 + _rand.nextDouble() * 0.3);
    while (y < maxY) {
      x += (_rand.nextDouble() - 0.5) * 50;
      y += 12 + _rand.nextDouble() * 22;
      pts.add(Offset(x, y));
    }
    setState(() => _bolt = pts);
    _flash.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() => _bolt = null);
      _scheduleNext();
    });
  }

  @override
  void dispose() {
    _rain.dispose();
    _clouds.dispose();
    _flash.dispose();
    _nextStrike?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SceneBase(
      colors: const [Color(0xFF0F0E1C), Color(0xFF0A0913), Color(0xFF08070F)],
      child: Stack(children: [
        // nuages sombres et denses
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _clouds,
            builder: (_, __) => CustomPaint(
              painter: _CloudsPainter(_cloudData, _clouds.value, opacity: 0.75, isDay: false),
            ),
          ),
        ),
        // pluie
        if (widget.withRain)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _rain,
              builder: (_, __) => CustomPaint(
                painter: _RainPainter(_drops, _rain.value, intensity: 0.9),
              ),
            ),
          ),
        // flash + éclair
        AnimatedBuilder(
          animation: _flash,
          builder: (_, __) {
            if (_bolt == null) return const SizedBox.shrink();
            final t = _flash.value;
            // courbe du flash : pic au début, retour
            double flashOp;
            if (t < 0.08) {
              flashOp = t / 0.08 * 0.35;
            } else if (t < 0.20) {
              flashOp = 0.35 - (t - 0.08) / 0.12 * 0.25;
            } else if (t < 0.30) {
              flashOp = 0.10 + (t - 0.20) / 0.10 * 0.15;
            } else {
              flashOp = (0.25 * (1 - (t - 0.30) / 0.70)).clamp(0.0, 0.25);
            }
            final boltOp = t < 0.25 ? (1 - t * 4).clamp(0.0, 1.0) : 0.0;
            return IgnorePointer(
              child: Stack(children: [
                Positioned.fill(
                  child: ColoredBox(color: Colors.white.withOpacity(flashOp)),
                ),
                if (boltOp > 0 && _bolt != null)
                  Positioned.fill(
                    child: CustomPaint(painter: _BoltPainter(_bolt!, boltOp)),
                  ),
              ]),
            );
          },
        ),
      ]),
    );
  }
}

class _BoltPainter extends CustomPainter {
  final List<Offset> points;
  final double opacity;
  _BoltPainter(this.points, this.opacity);
  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    // halo bleu
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF8EB4D8).withOpacity(opacity * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // coeur blanc
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withOpacity(opacity),
    );
  }
  @override
  bool shouldRepaint(_BoltPainter o) => o.opacity != opacity;
}