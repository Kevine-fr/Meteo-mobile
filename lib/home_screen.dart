import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'api_service.dart';
import 'main.dart';
import 'pages/today_page.dart';
import 'pages/hourly_page.dart';
import 'pages/forecast_page.dart';
import 'pages/details_page.dart';
import 'widgets/common.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final WeatherService _weather = WeatherService();
  final LocationService _location = LocationService();
  final PageController _pageController = PageController();
  final TextEditingController _searchCtrl = TextEditingController();

  Map<String, dynamic>? _data;
  bool _loading = true;
  int _currentPage = 0;
  bool _searchOpen = false;
  bool _refreshing = false;
  late final AnimationController _refreshSpinCtrl;

  @override
  void initState() {
    super.initState();
    _refreshSpinCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    initializeDateFormatting('fr_FR', null).then((_) => _loadInitial());
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    Map<String, dynamic>? data;
    try {
      final pos = await _location.getCurrentPosition();
      if (pos != null) {
        data = await _weather.fetchByCoords(pos.latitude, pos.longitude);
      } else {
        data = await _weather.fetchByCity('Paris');
      }
    } catch (_) {
      try {
        data = await _weather.fetchByCity('Paris');
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    if (_refreshing || _data == null) return;
    setState(() => _refreshing = true);
    _refreshSpinCtrl.forward(from: 0);
    final loc = _data!['location'];
    try {
      final d = await _weather.fetchByCoords((loc['lat'] as num).toDouble(), (loc['lon'] as num).toDouble());
      if (!mounted) return;
      setState(() => _data = d);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _refreshing = false);
  }

  Future<void> _searchCity(String city) async {
    if (city.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final d = await _weather.fetchByCity(city.trim());
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
        _searchOpen = false;
        _searchCtrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warn,
          content: Text(e.toString(), style: AppText.body(13)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _refreshSpinCtrl.dispose();
    _pageController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Stack(children: [
        // Fond atmosphérique
        if (_data != null)
          AtmosphereBackground(
            conditionText: _data!['current']['condition']['text'],
            isDay: _data!['current']['is_day'] == 1,
          )
        else
          const ColoredBox(color: AppColors.bg0),

        // Loader
        if (_loading) const _LoaderView(),

        // Contenu principal
        if (!_loading && _data != null)
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildLocationHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      TodayPage(data: _data!),
                      HourlyPage(data: _data!),
                      ForecastPage(data: _data!),
                      DetailsPage(data: _data!),
                    ],
                  ),
                ),
                AnimatedBottomNav(
                  currentIndex: _currentPage,
                  onTap: (i) {
                    _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
              ],
            ),
          ),
      ]),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const _PulsingDot(color: AppColors.accent),
            const SizedBox(width: 10),
            Text('ATMOSPHÈRE',
                style: AppText.mono(11, color: AppColors.fgDim, letter: 2.0)),
          ]),
          Row(children: [
            _CircleButton(
              icon: _searchOpen ? Icons.close : Icons.search,
              onTap: () => setState(() => _searchOpen = !_searchOpen),
            ),
            const SizedBox(width: 8),
            _CircleButton(
              icon: Icons.refresh,
              spinning: _refreshing,
              onTap: _refresh,
              controller: _refreshSpinCtrl,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildLocationHeader() {
    final loc = _data!['location'];
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_searchOpen)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _searchCtrl,
                  style: AppText.body(14),
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _searchCity,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une ville…',
                    hintStyle: AppText.body(13, color: AppColors.fgDim),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward, color: AppColors.accent),
                      onPressed: () => _searchCity(_searchCtrl.text),
                    ),
                  ),
                ),
              ),
            Row(children: [
              Container(
                width: 5, height: 5,
                decoration: const BoxDecoration(color: AppColors.accent2, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('LOCALISATION', style: AppText.mono(9.5, color: AppColors.fgFaint, letter: 1.8)),
            ]),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (c, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(a),
                  child: c,
                ),
              ),
              child: Text.rich(
                key: ValueKey(loc['name']),
                TextSpan(
                  children: [
                    TextSpan(
                      text: loc['name'],
                      style: AppText.display(24, w: FontWeight.w400, italic: true, color: AppColors.accent),
                    ),
                    TextSpan(text: ', ', style: AppText.display(24, w: FontWeight.w300)),
                    TextSpan(text: loc['region'], style: AppText.display(24, w: FontWeight.w300)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoaderView extends StatelessWidget {
  const _LoaderView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.7, end: 1.1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [AppColors.accent, Colors.transparent],
              stops: [0.0, 0.8],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
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
      builder: (_, __) => Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.5 + 0.5 * _ctrl.value),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.4 * _ctrl.value),
              blurRadius: 10 * _ctrl.value,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool spinning;
  final AnimationController? controller;
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.spinning = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Icon(icon, size: 18, color: AppColors.fg);
    if (controller != null) {
      child = AnimatedBuilder(
        animation: controller!,
        builder: (_, c) => Transform.rotate(angle: controller!.value * 2 * 3.14159, child: c),
        child: child,
      );
    }
    return Material(
      color: AppColors.card,
      shape: CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 38, height: 38,
          child: Center(child: child),
        ),
      ),
    );
  }
}
