import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../widgets/common.dart';
import '../widgets/charts.dart';

class ForecastPage extends StatefulWidget {
  final Map<String, dynamic> data;
  const ForecastPage({super.key, required this.data});

  @override
  State<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {
  int _expanded = 0;

  static const _joursFr = [
    'Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi',
  ];

  @override
  Widget build(BuildContext context) {
    final days = widget.data['forecast']['forecastday'] as List;
    final allMin = days.map((d) => (d['day']['mintemp_c'] as num).toDouble()).reduce((a, b) => a < b ? a : b);
    final allMax = days.map((d) => (d['day']['maxtemp_c'] as num).toDouble()).reduce((a, b) => a > b ? a : b);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        SectionTitle('${days.length} jours à venir'),

        ...days.asMap().entries.map((e) {
          final i = e.key;
          final d = e.value;
          final date = DateTime.parse(d['date']);
          final dayName = i == 0 ? "Aujourd'hui" : (i == 1 ? "Demain" : _joursFr[date.weekday % 7]);
          final shortDate = DateFormat('d MMM', 'fr_FR').format(date);
          final mn = (d['day']['mintemp_c'] as num).toDouble();
          final mx = (d['day']['maxtemp_c'] as num).toDouble();
          final lowPct = (mn - allMin) / (allMax - allMin);
          final highPct = (mx - allMin) / (allMax - allMin);

          return StaggeredEntry(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DayCard(
                day: d,
                title: dayName,
                date: shortDate,
                expanded: _expanded == i,
                onTap: () => setState(() => _expanded = _expanded == i ? -1 : i),
                lowPct: lowPct.clamp(0.0, 1.0),
                highPct: highPct.clamp(0.0, 1.0),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  final Map<String, dynamic> day;
  final String title;
  final String date;
  final bool expanded;
  final VoidCallback onTap;
  final double lowPct;
  final double highPct;
  const _DayCard({
    required this.day,
    required this.title,
    required this.date,
    required this.expanded,
    required this.onTap,
    required this.lowPct,
    required this.highPct,
  });

  @override
  Widget build(BuildContext context) {
    final d = day['day'];
    final astro = day['astro'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: expanded ? AppColors.accent : AppColors.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  // Date
                  SizedBox(
                    width: 96,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: AppText.display(17, w: FontWeight.w400, italic: true)),
                        const SizedBox(height: 2),
                        Text(date.toUpperCase(),
                            style: AppText.mono(9.5, color: AppColors.fgDim, letter: 1.2)),
                      ],
                    ),
                  ),
                  // Icone + texte
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        WeatherIcon(code: d['condition']['code'], size: 28, color: AppColors.accent),
                        const SizedBox(height: 4),
                        Text(
                          d['condition']['text'],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(11, color: AppColors.fgDim),
                        ),
                      ],
                    ),
                  ),
                  // Range
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    child: Row(children: [
                      SizedBox(
                        width: 28,
                        child: Text('${(d['mintemp_c'] as num).round()}°',
                            style: AppText.display(15, color: AppColors.rain), textAlign: TextAlign.center),
                      ),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Stack(children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: highPct - lowPct),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOutCubic,
                                builder: (_, w, __) => Padding(
                                  padding: EdgeInsets.only(left: lowPct * 70),
                                  child: FractionallySizedBox(
                                    widthFactor: w,
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [AppColors.rain, AppColors.accent, AppColors.warn],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text('${(d['maxtemp_c'] as num).round()}°',
                            style: AppText.display(15, color: AppColors.warn), textAlign: TextAlign.center),
                      ),
                    ]),
                  ),
                ]),

                // EXPANDED DETAILS
                AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  child: expanded
                      ? Column(
                          children: [
                            const SizedBox(height: 14),
                            Container(height: 1, color: AppColors.border),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _DetailBox(label: 'Pluie', value: '${d['daily_chance_of_rain']}%'),
                                _DetailBox(label: 'Précip.', value: '${d['totalprecip_mm']} mm'),
                                _DetailBox(label: 'Vent max', value: '${(d['maxwind_kph'] as num).round()} km/h'),
                                _DetailBox(label: 'Humidité', value: '${d['avghumidity']}%'),
                                _DetailBox(label: 'Visibilité', value: '${(d['avgvis_km'] as num).round()} km'),
                                _DetailBox(label: 'UV', value: '${d['uv']}'),
                                _DetailBox(label: 'Lever soleil', value: _t(astro['sunrise'])),
                                _DetailBox(label: 'Coucher soleil', value: _t(astro['sunset'])),
                                _DetailBox(label: 'Lune', value: '${astro['moon_phase']}'),
                                _DetailBox(label: 'Illumination', value: '${astro['moon_illumination']}%'),
                              ],
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _t(String s) =>
      s.replaceAll(' AM', '').replaceAll(' PM', '').replaceAll('No moonset', '—').replaceAll('No moonrise', '—');
}

class _DetailBox extends StatelessWidget {
  final String label;
  final String value;
  const _DetailBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 60) / 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: AppText.mono(8.5, color: AppColors.fgFaint, letter: 1.4)),
          const SizedBox(height: 3),
          Text(value, style: AppText.display(14, w: FontWeight.w400)),
        ],
      ),
    );
  }
}
