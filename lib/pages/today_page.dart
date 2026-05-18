import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/common.dart';
import '../widgets/charts.dart';

class TodayPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const TodayPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final current = data['current'];
    final today = data['forecast']['forecastday'][0];
    final day = today['day'];
    final astro = today['astro'];

    // sun arc progress
    final now = DateTime.now();
    final sr = _parseHM(astro['sunrise']);
    final ss = _parseHM(astro['sunset']);
    final nowMin = now.hour * 60 + now.minute;
    final p = ((nowMin - sr) / (ss - sr)).clamp(0.0, 1.0);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        // --- HERO TEMPERATURE ---
        StaggeredEntry(
          index: 0,
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.fg, AppColors.fgDim],
                  ).createShader(r),
                  child: AnimatedNumber(
                    value: (current['temp_c'] as num).toDouble(),
                    decimals: 0,
                    style: AppText.display(110, w: FontWeight.w200, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text('°C', style: AppText.display(28, w: FontWeight.w300, color: AppColors.fgDim)),
                ),
              ],
            ),
          ),
        ),
        StaggeredEntry(
          index: 1,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              current['condition']['text'],
              style: AppText.display(22, w: FontWeight.w400, italic: true),
            ),
          ),
        ),
        StaggeredEntry(
          index: 2,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(children: [
              Text('Ressenti ', style: AppText.mono(11, color: AppColors.fgDim, letter: 0.5)),
              Text('${(current['feelslike_c'] as num).round()}°',
                  style: AppText.mono(11, color: AppColors.accent, letter: 0.5)),
              const SizedBox(width: 10),
              Container(width: 16, height: 1, color: AppColors.borderStrong),
              const SizedBox(width: 10),
              Text('mis à jour ${(current['last_updated'] as String).split(' ').last}',
                  style: AppText.mono(11, color: AppColors.fgDim, letter: 0.5)),
            ]),
          ),
        ),

        // --- MIN / MAX ---
        StaggeredEntry(
          index: 3,
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(children: [
              _MinMax(label: 'MIN', value: (day['mintemp_c'] as num).round(), color: AppColors.rain),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.rain, AppColors.accent, AppColors.warn]),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              _MinMax(label: 'MAX', value: (day['maxtemp_c'] as num).round(), color: AppColors.warn),
            ]),
          ),
        ),

        // --- STATS GRID ---
        const SectionTitle('Conditions actuelles'),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            StaggeredEntry(
              index: 4,
              child: StatTile(
                icon: Icons.water_drop_outlined,
                label: 'Humidité',
                value: (current['humidity'] as num).toDouble(),
                unit: '%',
                subtitle: 'Rosée ${(current['dewpoint_c'] ?? 6).round()}°',
              ),
            ),
            StaggeredEntry(
              index: 5,
              child: StatTile(
                icon: Icons.air,
                label: 'Vent',
                value: (current['wind_kph'] as num).toDouble(),
                unit: 'km/h',
                subtitle: 'Rafales ${(current['gust_kph'] as num).round()}',
              ),
            ),
            StaggeredEntry(
              index: 6,
              child: StatTile(
                icon: Icons.speed_outlined,
                label: 'Pression',
                value: (current['pressure_mb'] as num).toDouble(),
                unit: 'mb',
                subtitle: 'Stable',
              ),
            ),
            StaggeredEntry(
              index: 7,
              child: StatTile(
                icon: Icons.visibility_outlined,
                label: 'Visibilité',
                value: (current['vis_km'] as num).toDouble(),
                unit: 'km',
                subtitle: _visLabel((current['vis_km'] as num).toDouble()),
              ),
            ),
            StaggeredEntry(
              index: 8,
              child: GlassCard(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      const Icon(Icons.wb_sunny_outlined, size: 12, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text('INDICE UV',
                          style: AppText.mono(9.5, color: AppColors.fgDim, letter: 1.8)),
                    ]),
                    const SizedBox(height: 4),
                    Center(child: UVGauge(uv: (current['uv'] as num).toDouble())),
                  ],
                ),
              ),
            ),
            StaggeredEntry(
              index: 9,
              child: StatTile(
                icon: Icons.umbrella_outlined,
                label: 'Précipitations',
                value: (day['totalprecip_mm'] as num).toDouble(),
                unit: 'mm',
                decimals: 1,
                subtitle: '${day['daily_chance_of_rain']}% de chance',
              ),
            ),
          ],
        ),

        // --- BOUSSOLE VENT ---
        const SizedBox(height: 10),
        StaggeredEntry(
          index: 10,
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(children: [
              WindCompass(degrees: (current['wind_degree'] as num).toDouble()),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DIRECTION DU VENT',
                        style: AppText.mono(9.5, color: AppColors.fgDim, letter: 1.8)),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(current['wind_dir'], style: AppText.display(24, w: FontWeight.w400, italic: true)),
                        const SizedBox(width: 8),
                        Text('· ${current['wind_degree']}°',
                            style: AppText.body(13, color: AppColors.fgDim)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Le vent souffle vers ${_oppositeDir(current['wind_dir'])}',
                        style: AppText.mono(10, color: AppColors.fgFaint, letter: 0.6)),
                  ],
                ),
              ),
            ]),
          ),
        ),

        // --- SUN ARC ---
        const SizedBox(height: 12),
        StaggeredEntry(
          index: 11,
          child: GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.light_mode_outlined, size: 12, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text('COURSE DU SOLEIL',
                      style: AppText.mono(9.5, color: AppColors.fgDim, letter: 1.8)),
                ]),
                const SizedBox(height: 8),
                SunArc(progress: p),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SunTime(label: 'Lever', value: _cleanTime(astro['sunrise'])),
                    _SunTime(label: 'Coucher', value: _cleanTime(astro['sunset']), align: TextAlign.right),
                  ],
                ),
              ],
            ),
          ),
        ),

        // --- ALERTES ---
        if ((data['alerts']?['alert'] as List?)?.isNotEmpty == true) ...[
          const SectionTitle('Alertes'),
          ...((data['alerts']['alert'] as List).asMap().entries.map((e) => StaggeredEntry(
                index: 12 + e.key,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(
                    child: Row(children: [
                      const Icon(Icons.warning_amber, color: AppColors.warn),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          e.value['headline'] ?? e.value['event'] ?? 'Alerte',
                          style: AppText.body(13, color: AppColors.fg),
                        ),
                      ),
                    ]),
                  ),
                ),
              ))),
        ],
      ],
    );
  }

  static int _parseHM(String s) {
    s = s.replaceAll(RegExp(r'(AM|PM)'), '').trim();
    final parts = s.split(':');
    if (parts.length < 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String _cleanTime(String s) =>
      s.replaceAll(' AM', '').replaceAll(' PM', '').replaceAll('No moonset', '—').replaceAll('No moonrise', '—');

  static String _visLabel(double km) {
    if (km >= 10) return 'Excellente';
    if (km >= 5) return 'Bonne';
    if (km >= 2) return 'Limitée';
    return 'Faible';
  }

  static String _oppositeDir(String d) {
    const opp = {
      'N': 'S', 'NNE': 'SSO', 'NE': 'SO', 'ENE': 'OSO',
      'E': 'O', 'ESE': 'ONO', 'SE': 'NO', 'SSE': 'NNO',
      'S': 'N', 'SSW': 'NNE', 'SW': 'NE', 'WSW': 'ENE',
      'W': 'E', 'WNW': 'ESE', 'NW': 'SE', 'NNW': 'SSE',
      // FR
      'SSO': 'NNE', 'SO': 'NE', 'OSO': 'ENE', 'O': 'E',
      'ONO': 'ESE', 'NO': 'SE', 'NNO': 'SSE',
    };
    return opp[d] ?? d;
  }
}

class _MinMax extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _MinMax({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppText.label()),
        const SizedBox(height: 2),
        Text('$value°', style: AppText.display(20, w: FontWeight.w400, color: color)),
      ],
    );
  }
}

class _SunTime extends StatelessWidget {
  final String label;
  final String value;
  final TextAlign align;
  const _SunTime({required this.label, required this.value, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align == TextAlign.right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.mono(10, color: AppColors.fgDim, letter: 0.6)),
        const SizedBox(height: 2),
        Text(value, style: AppText.body(13, w: FontWeight.w500)),
      ],
    );
  }
}
