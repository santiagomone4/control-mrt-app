import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ==============================================================
  // PALETA DE COLORES OFICIAL (Civil & Topografía MRT)
  // 1. Autoridad & Confianza: #112B4F (Deep Navy)
  // 2. Agua & Precisión:      #4C9F55 (Cyan Blue)  ← imagen real
  // 3. Naturaleza & Crecim.:  #F3F1EC (Warm Sand)
  // 4. Suelo & Base:          #3E4144 (Charcoal Slate)
  // 5. Datos & Estructura:    #5BACC3 (Steel Blue)
  // ==============================================================
  static const Color autoridadNavy   = Color(0xFF112B4F);
  static const Color precisionCyan   = Color(0xFF4C9F55); // Verde de la paleta
  static const Color naturalezaGreen = Color(0xFF4C9F55); // alias
  static const Color sueloWarm       = Color(0xFFF3F1EC);
  static const Color sueloDark       = Color(0xFFDEDAD0);
  static const Color sueloBorder     = Color(0xFFD4CFC2);
  static const Color datosCharcoal   = Color(0xFF3E4144);
  static const Color steelBlue       = Color(0xFF5BACC3);
  static const Color surfaceWhite    = Color(0xFFFFFFFF);

  // Estados de Control de Obra / Topografía
  static const Color colorOk          = Color(0xFF4C9F55); // Verde paleta
  static const Color colorRellenar    = Color(0xFF5BACC3); // Steel blue
  static const Color colorCortar      = Color(0xFFC53030); // Rojo rasante
  static const Color colorBaseTerreno = Color(0xFF6D4C41); // Tierra
  static const Color colorCoronamiento= Color(0xFF112B4F); // Navy
  static const Color colorPerfilIdeal = Color(0xFFC53030);

  static const Color primaryDark = autoridadNavy;

  // ---- Text Styles con Google Fonts ----
  static TextStyle heading(double size, {Color color = Colors.white, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.ibmPlexSans(fontSize: size, color: color, fontWeight: weight, letterSpacing: 0.3);

  static TextStyle body(double size, {Color color = const Color(0xFF3E4144), FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.roboto(fontSize: size, color: color, fontWeight: weight);

  static ThemeData get outdoorHighContrastTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.roboto().fontFamily,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: autoridadNavy,
        onPrimary: Colors.white,
        secondary: steelBlue,
        onSecondary: Colors.white,
        error: colorCortar,
        onError: Colors.white,
        background: sueloWarm,
        onBackground: datosCharcoal,
        surface: surfaceWhite,
        onSurface: datosCharcoal,
      ),
      scaffoldBackgroundColor: sueloWarm,
      appBarTheme: AppBarTheme(
        backgroundColor: autoridadNavy,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
        titleTextStyle: GoogleFonts.ibmPlexSans(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: steelBlue,
        unselectedLabelColor: const Color(0xFF9AB3CF),
        indicatorColor: steelBlue,
        labelStyle: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w700, fontSize: 12.5, letterSpacing: 0.4),
        unselectedLabelStyle: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w600, fontSize: 12),
      ),
      cardTheme: CardTheme(
        color: surfaceWhite,
        elevation: 2,
        shadowColor: const Color(0x15112B4F),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: sueloBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: autoridadNavy,
          foregroundColor: Colors.white,
          elevation: 2,
          minimumSize: const Size.fromHeight(48),
          textStyle: GoogleFonts.ibmPlexSans(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: GoogleFonts.ibmPlexSans(color: datosCharcoal, fontWeight: FontWeight.w600, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: sueloBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: sueloBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: steelBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
