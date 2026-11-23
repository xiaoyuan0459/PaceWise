import 'package:material_ui/material_ui.dart';

/// 品牌橙；Android 12+ 有动态取色时会被系统色替换。
const Color brandSeed = Color(0xFFF97316);

ThemeData buildLightTheme(ColorScheme? dynamicScheme) {
  return _theme(
    dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: brandSeed,
          brightness: Brightness.light,
        ),
  );
}

ThemeData buildDarkTheme(ColorScheme? dynamicScheme) {
  return _theme(
    dynamicScheme ??
        ColorScheme.fromSeed(seedColor: brandSeed, brightness: Brightness.dark),
  );
}

ThemeData _theme(ColorScheme scheme) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainer,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
