import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/common.dart';
import '../widgets/charts.dart';

class DetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const DetailsPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final current = data['current'];
    final aq = current['air_quality'] ?? {};
    final astro = data['forecast']['forecastday'][0]['astro'];
    final loc = data['location'];
    final epa = (aq['us-epa-index'] ?? 1) as int;

    final pollutants = [
      _Pollutant('PM2.5', (aq['pm2_5'] ?? 0).toDouble(), 50, 'μg/m³'),
      _Pollutant('PM10', (aq['pm10'] ?? 0).toDouble(), 100, 'μg/m³'),
      _Pollutant('O₃', (aq['o3'] ?? 0).toDouble(), 180, 'μg/m³'),
      _Pollutant('NO₂', (aq['no2'] ?? 0).toDouble(), 200, 'μg/m³'),
      _Pollutant('SO₂', (aq['so2'] ?? 0).toDouble(), 350, 'μg/m³'),
      _Pollutant('CO', (aq['co'] ?? 0).toDouble(), 10000, 'μg/m³'),
    ];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        const SectionTitle("Qualité de l'air"),

        // AQI card
        StaggeredEntry(
          index: 0,
          child: GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('INDICE EPA',
                            style: AppText.mono(10, color: AppColors.fgDim, letter: 2.0)),
                        const SizedBox(height: 4),
                        AnimatedNumber(
                          value: epa.toDouble(),
                          style: AppText.display(42, w: FontWeight.w300),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _aqiBgColor(epa).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _aqiLabel(epa),
                        style: AppText.display(15, w: FontWeight.w400, italic: true, color: _aqiBgColor(epa)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Pollutants bars
                ...pollutants.asMap().entries.map((e) {
                  final p = e.value;
                  final pct = (p.value / p.max).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      SizedBox(
                        width: 48,
                        child: Text(p.name, style: AppText.mono(10, color: AppColors.fgDim, letter: 0.4)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: pct),
                          duration: Duration(milliseconds: 800 + e.key * 80),
                          curve: Curves.easeOutCubic,
                          builder: (_, t, __) => Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: t,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.good, AppColors.accent, AppColors.warn],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 42,
                        child: Text(p.value.toStringAsFixed(1),
                            textAlign: TextAlign.right,
                            style: AppText.mono(10, color: AppColors.fg, letter: 0.2)),
                      ),
                    ]),
                  );
                }),
              ],
            ),
          ),
        ),

        // Astronomy
        const SectionTitle('Astronomie'),
        StaggeredEntry(
          index: 1,
          child: GlassCard(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              MoonVisual(
                illumination: (astro['moon_illumination'] as num).toInt(),
                phase: astro['moon_phase'],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PHASE', style: AppText.mono(10, color: AppColors.fgDim, letter: 2)),
                    const SizedBox(height: 3),
                    Text(_translatePhase(astro['moon_phase']),
                        style: AppText.display(15, w: FontWeight.w400, italic: true)),
                    const SizedBox(height: 12),
                    _AstroRow(label: 'Illumination', value: '${astro['moon_illumination']}%'),
                    _AstroRow(label: 'Lever lune', value: _t(astro['moonrise'])),
                    _AstroRow(label: 'Coucher lune', value: _t(astro['moonset'])),
                  ],
                ),
              ),
            ]),
          ),
        ),

        // Atmosphère
        const SectionTitle('Atmosphère'),

        StaggeredEntry(
          index: 2,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _IconRow(
              icon: Icons.speed_outlined,
              iconBg: AppColors.accent2.withOpacity(0.12),
              iconColor: AppColors.accent2,
              label: 'Pression atmosphérique',
              value: '${(current['pressure_mb'] as num).round()} mb',
              trailing: '↗ Stable',
              trailingColor: AppColors.good,
            ),
          ),
        ),

        StaggeredEntry(
          index: 3,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _IconRow(
              icon: Icons.water_outlined,
              iconBg: AppColors.rain.withOpacity(0.12),
              iconColor: AppColors.rain,
              label: 'Point de rosée',
              value: '${(current['dewpoint_c'] ?? _estimatedDewpoint(current)).round()} °C',
              trailing: 'Humidité ${current['humidity']}%',
              trailingColor: AppColors.fgDim,
            ),
          ),
        ),

        StaggeredEntry(
          index: 4,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _IconRow(
              icon: Icons.cloud_outlined,
              iconBg: AppColors.fgDim.withOpacity(0.12),
              iconColor: AppColors.fgDim,
              label: 'Couverture nuageuse',
              value: '${current['cloud']}%',
              trailing: _cloudLabel((current['cloud'] as num).toInt()),
              trailingColor: AppColors.fgDim,
            ),
          ),
        ),

        StaggeredEntry(
          index: 5,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _IconRow(
              icon: Icons.public_outlined,
              iconBg: AppColors.accent.withOpacity(0.12),
              iconColor: AppColors.accent,
              label: 'Fuseau horaire',
              value: loc['tz_id'] ?? '—',
              trailing: (loc['localtime'] as String).split(' ').last,
              trailingColor: AppColors.accent,
            ),
          ),
        ),

        StaggeredEntry(
          index: 6,
          child: _IconRow(
            icon: Icons.place_outlined,
            iconBg: AppColors.accent2.withOpacity(0.12),
            iconColor: AppColors.accent2,
            label: 'Coordonnées',
            value: '${(loc['lat'] as num).toStringAsFixed(2)}°, ${(loc['lon'] as num).toStringAsFixed(2)}°',
            trailing: loc['country'] ?? '',
            trailingColor: AppColors.fgDim,
          ),
        ),
      ],
    );
  }

  static String _t(String s) =>
      s.replaceAll(' AM', '').replaceAll(' PM', '').replaceAll('No moonset', '—').replaceAll('No moonrise', '—');

  static String _aqiLabel(int i) {
    const labels = ['', 'Excellent', 'Modéré', 'Sensible', 'Mauvais', 'Très mauvais', 'Dangereux'];
    return i >= 1 && i < labels.length ? labels[i] : 'Inconnu';
  }

  static Color _aqiBgColor(int i) {
    if (i <= 2) return AppColors.good;
    if (i <= 3) return AppColors.accent;
    return AppColors.warn;
  }

  static String _cloudLabel(int pct) {
    if (pct < 25) return 'Ciel dégagé';
    if (pct < 50) return 'Peu nuageux';
    if (pct < 75) return 'Nuageux';
    return 'Couvert';
  }

  static String _translatePhase(String s) {
    const map = {
      'New Moon': 'Nouvelle lune',
      'Waxing Crescent': 'Premier croissant',
      'First Quarter': 'Premier quartier',
      'Waxing Gibbous': 'Gibbeuse croissante',
      'Full Moon': 'Pleine lune',
      'Waning Gibbous': 'Gibbeuse décroissante',
      'Last Quarter': 'Dernier quartier',
      'Waning Crescent': 'Dernier croissant',
    };
    return map[s] ?? s;
  }

  static double _estimatedDewpoint(Map<String, dynamic> c) {
    final t = (c['temp_c'] as num).toDouble();
    final h = (c['humidity'] as num).toDouble();
    return t - ((100 - h) / 5);
  }
}

class _Pollutant {
  final String name;
  final double value;
  final double max;
  final String unit;
  _Pollutant(this.name, this.value, this.max, this.unit);
}

class _AstroRow extends StatelessWidget {
  final String label;
  final String value;
  const _AstroRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(),
              style: AppText.mono(9.5, color: AppColors.fgDim, letter: 1.6)),
          Text(value, style: AppText.display(13, w: FontWeight.w400)),
        ],
      ),
    );
  }
}

class _IconRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String trailing;
  final Color trailingColor;
  const _IconRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.trailing,
    required this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label.toUpperCase(),
                  style: AppText.mono(9.5, color: AppColors.fgDim, letter: 1.6)),
              const SizedBox(height: 2),
              Text(value,
                  style: AppText.display(18, w: FontWeight.w300), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Text(trailing, style: AppText.mono(10, color: trailingColor, letter: 0.2)),
      ]),
    );
  }
}
