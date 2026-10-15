import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF0A1A1A);
  static const backgroundDarker = Color(0xFF081515);
  static const surface = Color(0xFF112222);
  static const surfaceVariant = Color(0xFF1A2E2E);
  static const surfaceElevated = Color(0xFF1E3333);
  static const cardBorder = Color(0xFF2A4040);
  static const inputBorder = cardBorder;
  static const inputBorderFocused = primary;
  static const chipBorder = Color(0xFF3A5555);
  static const primary = Color(0xFFE8A838);
  static const primaryDark = Color(0xFFD4942E);
  static const primaryLight = Color(0xFFF5C462);
  static const primarySurface = Color(0x1AE8A838);
  static const onPrimary = Color(0xFF1A1A0A);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFB0C4C4);
  static const textTertiary = Color(0xFF7A9494);
  static const textGold = primary;
  static const textOnDark = Color(0xFFCCDDDD);
  static const categoryLiveMusic = primary;
  static const categoryCulture = Color(0xFFCC66CC);
  static const categoryFamily = Color(0xFFFF6B8A);
  static const categoryWellness = Color(0xFF66CC99);
  static const categoryFoodDrink = Color(0xFFFF8C42);
  static const chipIconMusic = Color(0xFFE85555);
  static const chipIconFamily = categoryFamily;
  static const chipIconWellness = categoryWellness;
  static const chipIconCulture = Color(0xFF5599CC);
  static const chipIconFood = categoryFoodDrink;
  static const moodHalloween = chipIconMusic;
  static const moodBudget = categoryWellness;
  static const moodNightlife = categoryFamily;
  static const moodCandlelight = primary;
  static const star = primary;
  static const success = categoryWellness;
  static const error = chipIconMusic;
  static const warning = Color(0xFFFFAA33);
  static const info = chipIconCulture;
  static const divider = Color(0xFF1E3535);
  static const dividerLight = Color(0xFF253D3D);
  static const navInactive = textTertiary;
  static const navActive = primary;
  static const navBarBg = Color(0xFF0D1E1E);
  static const overlay = Color(0xCC000000);
  static const overlayLight = Color(0x66000000);
  static const imageGradientStart = Colors.transparent;
  static const imageGradientEnd = Color(0xCC0A1A1A);
  static const shadowColor = Color(0x33000000);
  static const trendingBadgeBg = Color(0xFF1A3030);
  static const trendingNumber = success;
  static const eventOriginalBorder = primary;
}

abstract final class AppDimensions {
  static const s2 = 2.0,
      s4 = 4.0,
      s6 = 6.0,
      s8 = 8.0,
      s10 = 10.0,
      s12 = 12.0,
      s16 = 16.0,
      s20 = 20.0,
      s24 = 24.0,
      s32 = 32.0,
      s40 = 40.0,
      s48 = 48.0,
      s56 = 56.0,
      s64 = 64.0,
      s80 = 80.0;
  static const pagePaddingMobile = 20.0,
      pagePaddingTablet = 40.0,
      pagePaddingDesktop = 80.0,
      pagePaddingWide = 120.0;
  static const radiusSmall = 8.0,
      radiusMedium = 12.0,
      radiusLarge = 16.0,
      radiusXLarge = 20.0,
      radiusRound = 100.0;
  static const appBarHeight = 64.0,
      webNavBarHeight = 72.0,
      bottomNavHeight = 72.0,
      searchBarHeight = 52.0,
      chipHeight = 40.0,
      buttonHeightLarge = 52.0,
      buttonHeightMedium = 44.0;
  static const eventCardWidth = 260.0,
      eventCardImageHeight = 180.0,
      heroCarouselHeight = 420.0,
      heroCarouselHeightDesktop = 500.0,
      moodCardHeight = 200.0,
      categoryTileHeight = 56.0,
      thumbnailSize = 64.0,
      mapPreviewHeight = 180.0,
      maxContentWidth = 1440.0;
  static const borderWidth = 1.0,
      borderWidthThick = 1.5,
      borderWidthFocused = 2.0;
  static const iconSmall = 16.0, iconMedium = 20.0, iconLarge = 24.0;
  static const avatarSmall = 36.0, avatarMedium = 48.0, avatarLarge = 64.0;
  static double pagePadding(double width) => width <= 450
      ? 20
      : width <= 800
      ? 40
      : width <= 1920
      ? 80
      : 120;
}

abstract final class AppShadows {
  static const cardShadow = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const elevatedShadow = [
    BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const modalShadow = [
    BoxShadow(color: Color(0x4D000000), blurRadius: 32, offset: Offset(0, -8)),
  ];
}

abstract final class AppGradients {
  static const imageOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xCC0A1A1A)],
    stops: [.3, 1],
  );
  static const appBarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF081515), Color(0x000A1A1A)],
  );
  static const primaryGradient = LinearGradient(
    colors: [AppColors.primary, AppColors.primaryLight],
  );
}

abstract final class AppTypography {
  static const label = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
    color: AppColors.primary,
  );
  static const heroTitle = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.3,
    color: Colors.white,
  );
  static const sectionTitle = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: Colors.white,
  );
  static const cardTitle = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: Colors.white,
  );
  static const body = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 14,
    height: 1.6,
    color: AppColors.textSecondary,
  );
  static const small = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 12,
    height: 1.5,
    color: AppColors.textTertiary,
  );
  static const category = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
  );
  static const button = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static const priceLarge = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );
  static const priceSmall = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const rating = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.star,
  );
  static const link = TextStyle(
    fontFamily: 'DM Sans',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
}

abstract final class AppDecorations {
  static final card = BoxDecoration(
    color: AppColors.surface,
    border: Border.all(color: AppColors.cardBorder),
    borderRadius: BorderRadius.circular(16),
    boxShadow: AppShadows.cardShadow,
  );
  static final input = BoxDecoration(
    color: AppColors.surface,
    border: Border.all(color: AppColors.inputBorder),
    borderRadius: BorderRadius.circular(12),
  );
}

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'DM Sans',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      surface: AppColors.surface,
      onSurface: Colors.white,
      secondary: AppColors.primary,
      error: AppColors.error,
    ),
    textTheme: const TextTheme(
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.small,
      titleMedium: AppTypography.cardTitle,
      headlineMedium: AppTypography.sectionTitle,
    ),
    dividerColor: AppColors.divider,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundDarker,
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: AppTypography.body.copyWith(color: AppColors.textTertiary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: _inputBorder(AppColors.inputBorder),
      enabledBorder: _inputBorder(AppColors.inputBorder),
      focusedBorder: _inputBorder(AppColors.primary, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(44, 52),
        foregroundColor: AppColors.onPrimary,
        backgroundColor: AppColors.primary,
        textStyle: AppTypography.button,
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 48),
        foregroundColor: Colors.white,
        textStyle: AppTypography.button.copyWith(fontSize: 14),
        side: const BorderSide(color: AppColors.cardBorder),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        foregroundColor: AppColors.primary,
        textStyle: AppTypography.link,
      ),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: Colors.transparent,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(fontFamily: 'DM Sans', fontSize: 14),
      side: BorderSide(color: AppColors.chipBorder),
      shape: StadiumBorder(),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceElevated,
      modalBarrierColor: AppColors.overlay,
      constraints: BoxConstraints(maxWidth: 650),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: AppColors.surfaceElevated,
    ),
  );
  static OutlineInputBorder _inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
}
