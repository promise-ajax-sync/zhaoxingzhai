/// 应用主题配置
/// 参考 SYDF 设计系统 (sydf.cc)
library;

import 'package:flutter/material.dart';

class AppTheme {
  // 私有构造函数
  AppTheme._();

  // ============================================
  // 颜色系统 - 浅色主题
  // ============================================
  
  // 画布和表面
  static const Color _lightCanvas = Color(0xFFF3F2F5);
  static const Color _lightSurface = Color(0xFFFBFAFC);
  static const Color _lightSurfaceRaised = Color(0xFFFFFFFF);
  static const Color _lightSurfaceMuted = Color(0xFFF0EFF3);
  
  // 文本
  static const Color _lightTextPrimary = Color(0xFF2E2B36);
  static const Color _lightTextSecondary = Color(0xFF6A6572);
  static const Color _lightTextTertiary = Color(0xFF77717F);
  
  // 线条
  static const Color _lightLine = Color(0xFFDFDCE4);
  static const Color _lightLineStrong = Color(0xFFCBC6D0);
  
  // 主色调
  static const Color _lightAccent = Color(0xFF8368AB);
  static const Color _lightAccentStrong = Color(0xFF694C96);
  static const Color _lightAccentSoft = Color(0xFFE9E2F2);
  
  // 功能色
  static const Color _lightDanger = Color(0xFFA65364);
  static const Color _lightSuccess = Color(0xFF55796E);
  
  // ============================================
  // 颜色系统 - 深色主题
  // ============================================
  
  static const Color _darkCanvas = Color(0xFF1C1A20);
  static const Color _darkSurface = Color(0xFF242128);
  static const Color _darkSurfaceRaised = Color(0xFF2A272F);
  static const Color _darkSurfaceMuted = Color(0xFF302D35);
  
  static const Color _darkTextPrimary = Color(0xFFEEEAF2);
  static const Color _darkTextSecondary = Color(0xFFBBB4C2);
  static const Color _darkTextTertiary = Color(0xFF8F8896);
  
  static const Color _darkLine = Color(0xFF413D46);
  static const Color _darkLineStrong = Color(0xFF55505B);
  
  static const Color _darkAccent = Color(0xFFAA88CC);
  static const Color _darkAccentStrong = Color(0xFFC2A3DF);
  static const Color _darkAccentSoft = Color(0xFF3B3147);
  
  static const Color _darkDanger = Color(0xFFD08B9A);
  static const Color _darkSuccess = Color(0xFF8EB9AA);

  // ============================================
  // 间距系统
  // ============================================
  
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space5 = 20.0;
  static const double space6 = 24.0;
  static const double space7 = 32.0;
  static const double space8 = 40.0;
  static const double space9 = 48.0;

  // ============================================
  // 圆角系统
  // ============================================
  
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusRound = 999.0;

  // ============================================
  // 动画时长
  // ============================================
  
  static const Duration motionInstant = Duration(milliseconds: 120);
  static const Duration motionFast = Duration(milliseconds: 160);
  static const Duration motionBase = Duration(milliseconds: 220);
  static const Duration motionSlow = Duration(milliseconds: 280);

  // ============================================
  // 语义色访问器
  // ============================================
  // ThemeData 只覆盖了 Material 认得的槽位，下面这些是 syDF 设计系统
  // 里另有语义、但 Material 没有对应槽位的 token（强线条、柔和强调底、
  // 成功色）。页面直接引用它们，避免散落的 withOpacity 硬编码。

  /// 强线条：分隔感比普通线条更重的场景
  static Color lineStrong(BuildContext context) => _isDark(context)
      ? _darkLineStrong
      : _lightLineStrong;

  /// 柔和强调底：选中态背景、标签底
  static Color accentSoft(BuildContext context) =>
      _isDark(context) ? _darkAccentSoft : _lightAccentSoft;

  /// 成功色：正向结论
  static Color success(BuildContext context) =>
      _isDark(context) ? _darkSuccess : _lightSuccess;

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ============================================
  // 浅色主题
  // ============================================
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightCanvas,
      
      // 颜色方案
      colorScheme: const ColorScheme.light(
        surface: _lightSurface,
        primary: _lightAccent,
        secondary: _lightAccentStrong,
        error: _lightDanger,
        onSurface: _lightTextPrimary,
        onPrimary: Colors.white,
      ),
      
      // 卡片主题
      cardTheme: CardThemeData(
        color: _lightSurfaceRaised,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: _lightLine, width: 1),
        ),
      ),
      
      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightAccentStrong,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: space4, vertical: space4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          minimumSize: const Size(0, 38),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightTextSecondary,
          side: const BorderSide(color: _lightLine),
          padding: const EdgeInsets.symmetric(horizontal: space4, vertical: space4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          minimumSize: const Size(0, 38),
        ),
      ),
      
      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: _lightLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: _lightLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: _lightAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space4,
          vertical: space3,
        ),
      ),
      
      // 文本主题
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w600,
          color: _lightTextPrimary,
          height: 1.35,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _lightTextPrimary,
          height: 1.35,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _lightTextPrimary,
          height: 1.35,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: _lightTextPrimary,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: _lightTextPrimary,
          height: 1.6,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          color: _lightTextSecondary,
          height: 1.6,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _lightTextPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _lightTextSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          color: _lightTextTertiary,
        ),
      ),
      
      // 分割线主题
      dividerTheme: const DividerThemeData(
        color: _lightLine,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ============================================
  // 深色主题
  // ============================================
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkCanvas,
      
      colorScheme: const ColorScheme.dark(
        surface: _darkSurface,
        primary: _darkAccent,
        secondary: _darkAccentStrong,
        error: _darkDanger,
        onSurface: _darkTextPrimary,
        onPrimary: Color(0xFF1D1823),
      ),
      
      cardTheme: CardThemeData(
        color: _darkSurfaceRaised,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: _darkLine, width: 1),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkAccentStrong,
          foregroundColor: const Color(0xFF1D1823),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: space4, vertical: space4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          minimumSize: const Size(0, 38),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkTextSecondary,
          side: const BorderSide(color: _darkLine),
          padding: const EdgeInsets.symmetric(horizontal: space4, vertical: space4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          minimumSize: const Size(0, 38),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: _darkLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: _darkLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: _darkAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: space4,
          vertical: space3,
        ),
      ),
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
          height: 1.35,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
          height: 1.35,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
          height: 1.35,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: _darkTextPrimary,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: _darkTextPrimary,
          height: 1.6,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          color: _darkTextSecondary,
          height: 1.6,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _darkTextPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _darkTextSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          color: _darkTextTertiary,
        ),
      ),
      
      dividerTheme: const DividerThemeData(
        color: _darkLine,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
