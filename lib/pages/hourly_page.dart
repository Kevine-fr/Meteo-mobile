import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/common.dart';
import '../widgets/charts.dart';

class HourlyPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const HourlyPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Construit 24h en partant de l'heure actuelle, en concaténant jour 0 puis jour 1
    final today = data['forecast']['forecastday'][0]['hour'] as List;
    final tomorrow = data['forecast']['forecastday'].length > 1
        ? data['forecast']['forecastday'][1]['hour'] as List
        : <dynamic>[];
    final all = [...today, ...tomorrow];

    final nowH = DateTime.now().hour;
    final startIdx = all.indexWhere((h) {
      final t = (h['time'] as String).split(' ').last;
      return int.parse(t.split(':')[0]) == nowH;
    });
    final start = startIdx.clamp(0, all.length - 24);
    final hours24 = all.sublist(start, start + 24);

    final points = hours24.asMap().entries.map((e) => HourPoint(
          hour: int.parse((e.value['time'] as String).split(' ').last.split(':')[0]),
          temp: (e.value['temp_c'] as num).toDouble(),
          precipMm: (e.value['precip_mm'] as num).toDouble(),
          rainChance: (e.value['chance_of_rain'] as num).toInt(),
        )).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        const SectionTitle('24 prochaines heures'),

        // Graphique principal
        StaggeredEntry(
          index: 0,
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Température & pluie',
                        style: AppText.display(19, w: FontWeight.w400, italic: true)),
                    Row(children: [
                      _LegendDot(color: AppColors.accent, label: '°C'),
                      const SizedBox(width: 12),
                      _LegendDot(color: AppColors.rain, label: 'mm'),
                    ]),
                  ],
                ),
                const SizedBox(height: 12),
                HourlyChart(hours: points),
              ],
            ),
          ),
        ),

        // Heures détaillées
        const SectionTitle('Heure par heure'),
        StaggeredEntry(
          index: 1,
          child: SizedBox(
            height: 130,
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: hours24.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _HourCard(hour: hours24[i], isNow: i == 0),
            ),
          ),
        ),

        // Probabilité de pluie
        const SectionTitle('Probabilité de pluie'),
        StaggeredEntry(
          index: 2,
          child: GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 80,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(hours24.length, (i) {
                      final pct = (hours24[i]['chance_of_rain'] as num).toDouble();
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: pct / 100),
                            duration: Duration(milliseconds: 600 + i * 30),
                            curve: Curves.easeOutCubic,
                            builder: (_, t, __) => Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: t.clamp(0.02, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        AppColors.rain.withOpacity(pct / 100),
                                        AppColors.rain.withOpacity(0.2 * pct / 100),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('maintenant', style: AppText.mono(9, color: AppColors.fgFaint, letter: 0.6)),
                    Text('+6h', style: AppText.mono(9, color: AppColors.fgFaint, letter: 0.6)),
                    Text('+12h', style: AppText.mono(9, color: AppColors.fgFaint, letter: 0.6)),
                    Text('+18h', style: AppText.mono(9, color: AppColors.fgFaint, letter: 0.6)),
                    Text('+24h', style: AppText.mono(9, color: AppColors.fgFaint, letter: 0.6)),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Détail humidité / vent
        const SectionTitle('Conditions horaires'),
        StaggeredEntry(
          index: 3,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(6, (i) {
                final idx = i * 4; // toutes les 4h
                if (idx >= hours24.length) return const SizedBox.shrink();
                final h = hours24[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(children: [
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${(h['time'] as String).split(' ').last}',
                        style: AppText.mono(11, color: AppColors.fg, letter: 0.4),
                      ),
                    ),
                    WeatherIcon(code: h['condition']['code'], isDay: h['is_day'] == 1, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        h['condition']['text'],
                        style: AppText.body(12, color: AppColors.fgDim),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('💧${h['humidity']}%',
                        style: AppText.mono(10, color: AppColors.rain, letter: 0.2)),
                    const SizedBox(width: 10),
                    Text('${(h['wind_kph'] as num).round()}km/h',
                        style: AppText.mono(10, color: AppColors.fgDim, letter: 0.2)),
                  ]),
                );
              }).where((w) => w is! SizedBox).expand((w) => [w, Container(height: 1, color: AppColors.border)]).toList()..removeLast(),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 2, color: color),
      const SizedBox(width: 5),
      Text(label.toUpperCase(), style: AppText.mono(9, color: AppColors.fgDim, letter: 1.2)),
    ]);
  }
}

class _HourCard extends StatelessWidget {
  final dynamic hour;
  final bool isNow;
  const _HourCard({required this.hour, required this.isNow});

  @override
  Widget build(BuildContext context) {
    final time = (hour['time'] as String).split(' ').last;
    final rain = (hour['chance_of_rain'] as num).toInt();
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: isNow ? AppColors.accent.withOpacity(0.08) : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isNow ? AppColors.accent : AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isNow ? 'MTNT' : time.substring(0, 2) + 'h',
            style: AppText.mono(9.5, color: isNow ? AppColors.accent : AppColors.fgDim, letter: 0.8),
          ),
          const SizedBox(height: 6),
          WeatherIcon(code: hour['condition']['code'], isDay: hour['is_day'] == 1, size: 22),
          const SizedBox(height: 6),
          Text('${(hour['temp_c'] as num).round()}°',
              style: AppText.display(17, w: FontWeight.w400)),
          const SizedBox(height: 4),
          if (rain > 5)
            Text('💧$rain%', style: AppText.mono(9, color: AppColors.rain, letter: 0.2))
          else
            const SizedBox(height: 11),
        ],
      ),
    );
  }
}
