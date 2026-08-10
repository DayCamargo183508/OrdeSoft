import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de colores centralizada para OrderSoft POS
class AppColors {
  AppColors._();

  // Primarios
  static const Color primary = Color(0xFF1A1F2E);
  static const Color primaryLight = Color(0xFF2C3E6B);
  static const Color primaryDark = Color(0xFF0E1219);

  // Acento / Acción
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentLight = Color(0xFFFF8C5A);
  static const Color accentDark = Color(0xFFE55A25);

  // Semánticos
  static const Color success = Color(0xFF2ECC71);
  static const Color successLight = Color(0xFFD4F5E4);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFFEF3CD);
  static const Color error = Color(0xFFE74C3C);
  static const Color errorLight = Color(0xFFFDDEDE);
  static const Color info = Color(0xFF3498DB);
  static const Color infoLight = Color(0xFFD5EAF8);

  // Estados de mesa
  static const Color mesaLibre = Color(0xFF27AE60);
  static const Color mesaLibreLight = Color(0xFFC8EFD8);
  static const Color mesaOcupada = Color(0xFFE74C3C);
  static const Color mesaOcupadaLight = Color(0xFFFDDEDE);
  static const Color mesaUnida = Color(0xFF8E44AD);
  static const Color mesaUnidaLight = Color(0xFFEDD8F8);
  static const Color mesaSeleccionada = Color(0xFF2980B9);
  static const Color mesaSeleccionadaLight = Color(0xFFD5EAF8);

  // Superficies
  static const Color surface = Color(0xFFF8F9FD);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfacePanel = Color(0xFFF1F3F8);
  static const Color surfaceInput = Color(0xFFF5F6FA);

  // Texto
  static const Color textPrimary = Color(0xFF1A1F2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // Bordes y divisores
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // Overlay
  static const Color overlayDark = Color(0x80000000);
  static const Color overlayLight = Color(0x1AFFFFFF);
}

/// Jerarquía tipográfica de OrderSoft
class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayLarge = GoogleFonts.outfit(
    fontSize: 48, fontWeight: FontWeight.w800,
    color: AppColors.textOnDark, letterSpacing: -1.0, height: 1.1,
  );
  static TextStyle displayMedium = GoogleFonts.outfit(
    fontSize: 36, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.5, height: 1.2,
  );
  static TextStyle headingLarge = GoogleFonts.outfit(
    fontSize: 24, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.3,
  );
  static TextStyle headingMedium = GoogleFonts.outfit(
    fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static TextStyle headingSmall = GoogleFonts.outfit(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static TextStyle priceLarge = GoogleFonts.outfit(
    fontSize: 28, fontWeight: FontWeight.w800,
    color: AppColors.accent, letterSpacing: -0.5,
  );
  static TextStyle priceMedium = GoogleFonts.outfit(
    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.accent,
  );
  static TextStyle priceSmall = GoogleFonts.outfit(
    fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.success,
  );
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.5,
  );
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.5,
  );
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.4,
  );
  static TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, letterSpacing: 0.1,
  );
  static TextStyle labelMedium = GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary, letterSpacing: 0.1,
  );
  static TextStyle labelSmall = GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.textMuted, letterSpacing: 0.2,
  );
  static TextStyle numpad = GoogleFonts.outfit(
    fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static TextStyle mesaNumero = GoogleFonts.outfit(
    fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textOnDark,
  );
  static TextStyle mesaEstado = GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w500,
    color: AppColors.textOnDark, letterSpacing: 0.3,
  );
  static TextStyle snackbar = GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textOnDark,
  );
}

/// Breakpoints del sistema responsivo
class AppBreakpoints {
  AppBreakpoints._();

  static const double mobile = 600;
  static const double tablet = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= mobile && w < tablet;
  }
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet;
}

/// Constantes de espaciado
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Constantes de radio de borde
class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(full));
}

/// Sombras estándar
class AppShadows {
  AppShadows._();
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A1A1F2E), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x051A1F2E), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x141A1F2E), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> bottomBar = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, -3)),
  ];
}

/// ThemeData global de OrderSoft
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnDark,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.textOnDark,
      secondary: AppColors.accent,
      onSecondary: AppColors.textOnDark,
      secondaryContainer: const Color(0xFFFFEDE6),
      onSecondaryContainer: AppColors.accentDark,
      tertiary: AppColors.success,
      onTertiary: AppColors.textOnDark,
      error: AppColors.error,
      onError: AppColors.textOnDark,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.divider,
      shadow: const Color(0x1A1A1F2E),
      scrim: AppColors.overlayDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        headlineLarge: AppTextStyles.headingLarge,
        headlineMedium: AppTextStyles.headingMedium,
        headlineSmall: AppTextStyles.headingSmall,
        titleLarge: AppTextStyles.headingMedium,
        titleMedium: AppTextStyles.headingSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: const Color(0x331A1F2E),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textOnDark,
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnDark),
        actionsIconTheme: const IconThemeData(color: AppColors.textOnDark),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textOnDark,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textMuted,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceInput,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.buttonRadius,
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.buttonRadius,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.buttonRadius,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.buttonRadius,
          borderSide: BorderSide(color: AppColors.error),
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        labelStyle: AppTextStyles.labelMedium,
        errorStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfacePanel,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.border,
        labelStyle: AppTextStyles.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.chipRadius),
        side: BorderSide.none,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: AppTextStyles.snackbar,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
        elevation: 4,
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 13),
        labelColor: AppColors.textOnDark,
        unselectedLabelColor: const Color(0xB3FFFFFF),
        indicatorColor: AppColors.accent,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surfacePanel,
        selectedIconTheme: const IconThemeData(color: AppColors.accent, size: 24),
        unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
        selectedLabelTextStyle: GoogleFonts.inter(
          color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 12,
        ),
        unselectedLabelTextStyle: GoogleFonts.inter(
          color: AppColors.textSecondary, fontWeight: FontWeight.w400, fontSize: 12,
        ),
        indicatorColor: const Color(0x1AFF6B35),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider, thickness: 1, space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs,
        ),
        titleTextStyle: AppTextStyles.bodyLarge,
        subtitleTextStyle: AppTextStyles.bodySmall,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textOnDark,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceCard,
        elevation: 8,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
        titleTextStyle: AppTextStyles.headingMedium,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        circularTrackColor: AppColors.border,
      ),
    );
  }
}
