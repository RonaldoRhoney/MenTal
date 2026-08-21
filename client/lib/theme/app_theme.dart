import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens e ThemeData únicos do MENTAL — DESIGN_SYSTEM.md.
///
/// Fonte de verdade visual: nenhuma cor ou fonte deve ser hardcoded tela
/// por tela (DESIGN_SYSTEM.md §9, "Claude Code") — toda tela consome
/// estes tokens via `Theme.of(context)` ou as constantes `AppColors`.
///
/// Fontes via `google_fonts` (Fraunces, Inter, JetBrains Mono): decisão
/// de implementação, não do documento original — a alternativa seria
/// empacotar os arquivos .ttf localmente. google_fonts baixa e cacheia a
/// fonte na primeira execução (precisa de rede na primeira vez); embutir
/// os arquivos seria offline-first mas exigiria baixar/versionar os
/// binários de fonte manualmente. Escolhido por ser mais rápido de
/// implementar neste Vertical Slice — revisar antes de um build de
/// release se offline-first no primeiro uso for um requisito real.
class AppColors {
  const AppColors._();

  static const bg = Color(0xFF111013);
  static const bg2 = Color(0xFF17161A);
  static const gold = Color(0xFFE2BE6E);
  static const teal = Color(0xFF3FA796);
  static const ink = Color(0xFF3A3560);
  static const bone = Color(0xFFEDE7DA);
  static const muted = Color(0xFF8A8578);
  static const success = teal;
  static const warning = gold;
  // Terracota, não vermelho vivo — vermelho sinaliza urgência/perigo, o
  // que contradiz o Princípio de Não-Humilhação (DESIGN_SYSTEM.md §1).
  static const error = Color(0xFFC96A5A);
}

class AppTheme {
  const AppTheme._();

  static ThemeData get themeData {
    final baseTextTheme = TextTheme(
      // Fraunces: wordmark, títulos de tela, nome de território, nível.
      headlineSmall: GoogleFonts.fraunces(
        color: AppColors.bone,
        fontWeight: FontWeight.w600,
        fontSize: 24,
      ),
      titleLarge: GoogleFonts.fraunces(
        color: AppColors.bone,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      // Inter: corpo de texto, botões, labels — legibilidade em qualquer tamanho.
      bodyLarge: GoogleFonts.inter(color: AppColors.bone, fontSize: 16),
      bodyMedium: GoogleFonts.inter(color: AppColors.bone, fontSize: 16),
      bodySmall: GoogleFonts.inter(color: AppColors.muted, fontSize: 16),
      labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.bg,
        primary: AppColors.gold,
        onPrimary: AppColors.bg,
        secondary: AppColors.teal,
        onSecondary: AppColors.bg,
        error: AppColors.error,
        onError: AppColors.bone,
        onSurface: AppColors.bone,
      ),
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.bone,
        elevation: 0,
        titleTextStyle: GoogleFonts.fraunces(
          color: AppColors.bone,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      cardTheme: const CardThemeData(color: AppColors.bg2),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.bg,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.bone,
          side: const BorderSide(color: AppColors.muted),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.teal,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: GoogleFonts.inter(color: AppColors.muted, fontSize: 16),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.muted)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gold)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.gold : AppColors.muted,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.gold),
    );
  }

  /// Estilo "metadado técnico" (JetBrains Mono) — DESIGN_SYSTEM.md §2:
  /// streak, XP numérico, nunca em texto de leitura corrida.
  static TextStyle technicalStyle({Color color = AppColors.bone, double fontSize = 16}) {
    return GoogleFonts.jetBrainsMono(color: color, fontSize: fontSize, fontWeight: FontWeight.w500);
  }
}
