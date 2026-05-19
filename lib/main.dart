import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  Future.wait([
    dotenv.load(fileName: "assets/config/env"),
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bg0,
    ),
  );
  runApp(const AtmosphereApp());
}

/// =====================================================
///  PALETTE — direction esthétique "Atmosphère Éditoriale"
///  dark warm-dusk avec accent ambre et bleu acier
/// =====================================================
class AppColors {
  static const bg0 = Color(0xFF0A0E1A);
  static const bg1 = Color(0xFF10182A);
  static const bg2 = Color(0xFF1A2138);
  static const fg = Color(0xFFE8E6E0);
  static const fgDim = Color(0xFF8E94A3);
  static const fgFaint = Color(0xFF4A4F5C);

  // Accents
  static const accent = Color(0xFFD4A574); // ambre chaud
  static const accent2 = Color(0xFF8EB4D8); // bleu acier
  static const rain = Color(0xFF6BA4D4);
  static const warn = Color(0xFFD9805A);
  static const good = Color(0xFF83B97C);

  // UI surfaces
  static Color border = const Color(0xFFE8E6E0).withOpacity(0.09);
  static Color borderStrong = const Color(0xFFE8E6E0).withOpacity(0.18);
  static Color card = Colors.white.withOpacity(0.035);
  static Color cardHover = Colors.white.withOpacity(0.055);
}

/// =====================================================
///  TYPOGRAPHIE — Fraunces (serif italique) + Manrope + JetBrains Mono
/// =====================================================
class AppText {
  static TextStyle display(double size, {FontWeight w = FontWeight.w300, Color? color, bool italic = false}) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: w,
        color: color ?? AppColors.fg,
        height: 1,
        letterSpacing: -0.02 * size,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      );

  static TextStyle body(double size, {FontWeight w = FontWeight.w400, Color? color}) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: w,
        color: color ?? AppColors.fg,
        letterSpacing: -0.01,
      );

  static TextStyle mono(double size, {FontWeight w = FontWeight.w400, Color? color, double letter = 0.16}) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: w,
        color: color ?? AppColors.fgDim,
        letterSpacing: letter,
      );

  static TextStyle label({Color? color}) => mono(10, color: color ?? AppColors.fgFaint, letter: 2.0);
}

class AtmosphereApp extends StatelessWidget {
  const AtmosphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Atmosphère',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg0,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.accent2,
          surface: AppColors.bg1,
        ),
        textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme).apply(
          bodyColor: AppColors.fg,
          displayColor: AppColors.fg,
        ),
        useMaterial3: true,
        splashFactory: NoSplash.splashFactory,
      ),
      home: const HomeScreen(),
    );
  }
}
