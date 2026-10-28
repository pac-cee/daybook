import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const ink = Color(0xFF17191B);
const accent = Color(0xFF3E6D8C);
const muted = Color(0xFF62666B);
const canvas = Color(0xFFF7F7F7);
const line = Color(0xFFE8E9EA);
const blueWash = Color(0xFFEDF3F7);

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: canvas,
  colorScheme:
      ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
      ).copyWith(
        primary: accent,
        secondary: accent,
        surface: Colors.white,
        onSurface: ink,
        error: ink,
        surfaceContainerHighest: const Color(0xFFF0F1F2),
      ),
  fontFamily: '.SF Pro Text',
  appBarTheme: const AppBarTheme(
    backgroundColor: canvas,
    foregroundColor: ink,
    elevation: 0,
    centerTitle: false,
  ),
  dividerTheme: const DividerThemeData(color: line, thickness: 1),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF3F4F5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.all(16),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
  snackBarTheme: const SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: ink,
  ),
);

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = Colors.white,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: line),
    ),
    child: child,
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, this.icon, {super.key});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: muted),
      const SizedBox(width: 7),
      Flexible(
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.25,
            color: muted,
          ),
        ),
      ),
    ],
  );
}

IconData weatherIcon(int code, {bool isDay = true}) => switch (code) {
  0 => isDay ? CupertinoIcons.sun_max : CupertinoIcons.moon_stars,
  1 || 2 => isDay ? CupertinoIcons.cloud_sun : CupertinoIcons.cloud_moon,
  3 => CupertinoIcons.cloud,
  45 || 48 => CupertinoIcons.cloud_fog,
  51 || 53 || 55 || 56 || 57 => CupertinoIcons.cloud_drizzle,
  61 || 63 || 65 || 66 || 67 || 80 || 81 || 82 => CupertinoIcons.cloud_rain,
  71 || 73 || 75 || 77 || 85 || 86 => CupertinoIcons.snow,
  95 || 96 || 99 => CupertinoIcons.cloud_bolt_rain,
  _ => CupertinoIcons.question_circle,
};
String shortDate(DateTime date) =>
    '${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]} ${date.day}';
