/// 应用主题配置
/// 参考 SYDF 设计系统 (sydf.cc)
library;

import 'package:flutter/material.dart';

/// 黄历吉凶等级。
///
/// 对应参考实现的 `--ds-auspice-*` 六档：大吉 / 吉 / 小吉 / 平 / 慎 / 忌。
/// 黄历、今日运势、每日一卦共用这一套语义色。
enum AuspiceLevel {
  excellent('大吉'),
  good('吉'),
  smallGood('小吉'),
  neutral('平'),
  caution('慎'),
  avoid('忌');

  const AuspiceLevel(this.label);

  final String label;
}

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

  // 语义辅助色（--ds-blue / --ds-plum / --ds-sage / --ds-gold）
  static const Color _lightBlue = Color(0xFF607C96);
  static const Color _lightBlueSoft = Color(0xFFE5EDF2);
  static const Color _lightPlum = Color(0xFF956178);
  static const Color _lightPlumSoft = Color(0xFFF1E5EA);
  static const Color _lightSage = Color(0xFF637D75);
  static const Color _lightSageSoft = Color(0xFFE4ECE9);
  static const Color _lightGold = Color(0xFFA98252);

  // 浮层与布局表面
  static const Color _lightSurfaceOverlay = Color(0xF5FFFFFF);
  static const Color _lightSidebar = Color(0xFFECEAF0);
  static const Color _lightTopbar = Color(0xFFF9F8FA);

  // 吉凶等级（--ds-auspice-*）
  static const Color _lightExcellent = Color(0xFFB52A27);
  static const Color _lightGood = Color(0xFF1F7A4D);
  static const Color _lightSmallGood = Color(0xFF167784);
  static const Color _lightNeutral = Color(0xFF5F6B7A);
  static const Color _lightCaution = Color(0xFF9A5B08);
  static const Color _lightAvoid = Color(0xFF51468A);

  // 品牌渐变（--theme-hero-*）
  static const Color _lightHeroStart = Color(0xFF67428F);
  static const Color _lightHeroMiddle = Color(0xFF8B58B1);
  static const Color _lightHeroEnd = Color(0xFFB778CF);
  static const Color _lightThemeShadow = Color(0x3D5B4184);
  
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

  static const Color _darkBlue = Color(0xFF91ADC1);
  static const Color _darkBlueSoft = Color(0xFF293943);
  static const Color _darkPlum = Color(0xFFC994A9);
  static const Color _darkPlumSoft = Color(0xFF43303A);
  static const Color _darkSage = Color(0xFF91B3AA);
  static const Color _darkSageSoft = Color(0xFF2E403B);
  static const Color _darkGold = Color(0xFFD1AD76);

  static const Color _darkSurfaceOverlay = Color(0xF726232B);
  static const Color _darkSidebar = Color(0xFF211F25);
  static const Color _darkTopbar = Color(0xFF1D1B20);

  static const Color _darkExcellent = Color(0xFFF28B82);
  static const Color _darkGood = Color(0xFF6ED29E);
  static const Color _darkSmallGood = Color(0xFF62C8D2);
  static const Color _darkNeutral = Color(0xFFB7C2CF);
  static const Color _darkCaution = Color(0xFFF0B552);
  static const Color _darkAvoid = Color(0xFFB2A4EE);

  static const Color _darkHeroStart = Color(0xFFB99ADE);
  static const Color _darkHeroMiddle = Color(0xFFC69BE7);
  static const Color _darkHeroEnd = Color(0xFFDDA9ED);
  static const Color _darkThemeShadow = Color(0x57000000);

  // ============================================
  // 布局尺寸
  // ============================================
  // 与参考实现的 CSS 变量同名同值：
  // --ds-topbar-height / --ds-page-content / --ds-sidebar-width

  /// 顶栏高度
  static const double topbarHeight = 64.0;

  /// 页面内容最大宽度（超出后内容居中留白）
  static const double pageContent = 1180.0;

  /// 侧栏固定宽度
  static const double sidebarWidth = 230.0;

  /// 侧栏展开的断点：低于此宽度改为抽屉式导航
  static const double sidebarBreakpoint = 1024.0;

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

  /// 浮层表面：下拉菜单、弹层
  static Color surfaceOverlay(BuildContext context) =>
      _isDark(context) ? _darkSurfaceOverlay : _lightSurfaceOverlay;

  /// 侧栏底色
  static Color sidebar(BuildContext context) =>
      _isDark(context) ? _darkSidebar : _lightSidebar;

  /// 顶栏底色
  static Color topbar(BuildContext context) =>
      _isDark(context) ? _darkTopbar : _lightTopbar;

  /// 品牌渐变三色（首页标题用）
  static List<Color> heroGradient(BuildContext context) => _isDark(context)
      ? const [_darkHeroStart, _darkHeroMiddle, _darkHeroEnd]
      : const [_lightHeroStart, _lightHeroMiddle, _lightHeroEnd];

  /// 品牌投影色：用于「功德箱」这类强调胶囊
  static Color themeShadow(BuildContext context) =>
      _isDark(context) ? _darkThemeShadow : _lightThemeShadow;

  /// 语义辅助色：青 / 梅 / 苔 / 金
  static Color blue(BuildContext context) =>
      _isDark(context) ? _darkBlue : _lightBlue;
  static Color plum(BuildContext context) =>
      _isDark(context) ? _darkPlum : _lightPlum;
  static Color sage(BuildContext context) =>
      _isDark(context) ? _darkSage : _lightSage;
  static Color gold(BuildContext context) =>
      _isDark(context) ? _darkGold : _lightGold;

  /// 语义辅助色对应的柔和底
  static Color blueSoft(BuildContext context) =>
      _isDark(context) ? _darkBlueSoft : _lightBlueSoft;
  static Color plumSoft(BuildContext context) =>
      _isDark(context) ? _darkPlumSoft : _lightPlumSoft;
  static Color sageSoft(BuildContext context) =>
      _isDark(context) ? _darkSageSoft : _lightSageSoft;

  /// 吉凶等级色：黄历与运势共用一套
  static Color auspice(BuildContext context, AuspiceLevel level) =>
      switch (level) {
        AuspiceLevel.excellent =>
          _isDark(context) ? _darkExcellent : _lightExcellent,
        AuspiceLevel.good => _isDark(context) ? _darkGood : _lightGood,
        AuspiceLevel.smallGood =>
          _isDark(context) ? _darkSmallGood : _lightSmallGood,
        AuspiceLevel.neutral =>
          _isDark(context) ? _darkNeutral : _lightNeutral,
        AuspiceLevel.caution =>
          _isDark(context) ? _darkCaution : _lightCaution,
        AuspiceLevel.avoid => _isDark(context) ? _darkAvoid : _lightAvoid,
      };

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
