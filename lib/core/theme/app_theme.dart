import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme_config.dart';
import '../../shared/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Gerador e gerenciador de temas do TaskTasker
class AppTheme {
  AppTheme._();

  /// Constrói um ThemeData dinâmico a partir do AppThemeData ativo
  static ThemeData createTheme(AppThemeData theme) {
    final isDark = theme.isDark;
    final brightness = isDark ? Brightness.dark : Brightness.light;

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: theme.primary,
            secondary: theme.secondary,
            tertiary: theme.accent,
            surface: theme.surface,
            error: theme.taskRed,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: theme.textPrimary,
            onError: Colors.white,
          )
        : ColorScheme.light(
            primary: theme.primary,
            secondary: theme.secondary,
            tertiary: theme.accent,
            surface: theme.surface,
            error: theme.taskRed,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: theme.textPrimary,
            onError: Colors.white,
          );

    final baseTextTheme = (isDark ? ThemeData.dark() : ThemeData.light()).textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: theme.background,
      colorScheme: colorScheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: theme.textPrimary,
        displayColor: theme.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: theme.fontStyleBase(TextStyle(
          color: theme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        )),
        iconTheme: IconThemeData(color: theme.primary),
      ),
      cardTheme: CardThemeData(
        color: theme.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.borderRadius),
          side: BorderSide(color: theme.border, width: theme.borderWidth > 0 ? theme.borderWidth : 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: theme.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: theme.fontStyleBase(TextStyle(color: theme.textMuted, fontSize: 14)),
        labelStyle: theme.fontStyleBase(TextStyle(color: theme.textSecondary, fontSize: 14)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.secondary, width: 1.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: theme.fontStyleBase(TextStyle(
          color: theme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        )),
        contentTextStyle: theme.fontStyleBase(TextStyle(
          color: theme.textSecondary,
          fontSize: 14,
        )),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.accent,
          side: BorderSide(color: theme.accent, width: 1.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: theme.divider,
        thickness: 0.5,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
    );
  }

  static ThemeData get darkTheme {
    return createTheme(AppThemeData.fromType(AppThemeType.cyberpunkDark));
  }
}
