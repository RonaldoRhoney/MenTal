import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/theme_mode_service.dart';

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
///
/// Claro/escuro (29/08/2026, pedido de Rhoney: botão de alternância na
/// Home) — cada token virou um getter que resolve pro tom ativo em
/// ThemeModeService.instance, em vez de `static const`. Mantém a mesma
/// sintaxe de uso em toda a UI (`AppColors.gold` continua funcionando
/// sem tocar nenhuma tela) — só deixou de ser compile-time constant,
/// então qualquer `const` que envolvia um valor de AppColors precisou
/// virar não-const (o valor agora depende de estado em runtime).
class AppColors {
  const AppColors._();

  static bool get _isDark => ThemeModeService.instance.isDark;

  static Color get bg => _isDark ? const Color(0xFF111013) : const Color(0xFFFAF7F0);
  static Color get bg2 => _isDark ? const Color(0xFF17161A) : const Color(0xFFF0EAD9);
  static Color get gold => _isDark ? const Color(0xFFE2BE6E) : const Color(0xFFAD7A2E);
  static Color get teal => _isDark ? const Color(0xFF3FA796) : const Color(0xFF1F7A6C);
  static Color get ink => const Color(0xFF3A3560);
  static Color get bone => _isDark ? const Color(0xFFEDE7DA) : const Color(0xFF2B2620);
  static Color get muted => _isDark ? const Color(0xFF8A8578) : const Color(0xFF6B6558);
  static Color get success => teal;
  static Color get warning => gold;
  // Terracota, não vermelho vivo — vermelho sinaliza urgência/perigo, o
  // que contradiz o Princípio de Não-Humilhação (DESIGN_SYSTEM.md §1).
  static Color get error => _isDark ? const Color(0xFFC96A5A) : const Color(0xFFA8503D);

  // Paleta de gamificação (pedido de Rhoney, 29/08/2026): reforço visual
  // de vitória/conquista no card de progresso da Home — verde de
  // sucesso + roxo de "nível/rank", complementando o dourado (conquista)
  // já existente, sem substituir os tokens base usados no resto do app.
  static Color get victory => _isDark ? const Color(0xFF4FBF7A) : const Color(0xFF2E8F5A);
  static Color get purple => _isDark ? const Color(0xFF9B7FE0) : const Color(0xFF6B4FC2);

  // Ponto de "profundidade" do gradiente radial de fundo
  // (widgets/game_background.dart) — no escuro é o roxo original
  // (U.I/MOVIMENTO_REDESIGN_V1.md §2); no claro vira um dourado bem
  // suave (achado real testando o toggle, 29/08/2026: deixar o roxo
  // escuro fixo criava uma mancha escura estranha no topo da tela clara).
  static Color get bgGlow => _isDark ? const Color(0xFF241640) : const Color(0xFFF3E7CE);
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

    final isDark = ThemeModeService.instance.isDark;
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      // Transparente de propósito (pedido de Rhoney, 29/08/2026: fundo
      // com profundidade em vez de preto sólido) — o gradiente de fundo
      // real vem do MaterialApp.builder (main.dart, GameBackground),
      // aplicado uma única vez atrás de toda a árvore de telas.
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: isDark
          ? ColorScheme.dark(
              surface: AppColors.bg,
              primary: AppColors.gold,
              onPrimary: AppColors.bg,
              secondary: AppColors.teal,
              onSecondary: AppColors.bg,
              error: AppColors.error,
              onError: AppColors.bone,
              onSurface: AppColors.bone,
            )
          : ColorScheme.light(
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
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.bone,
        elevation: 0,
        titleTextStyle: GoogleFonts.fraunces(
          color: AppColors.bone,
          fontWeight: FontWeight.w600,
          fontSize: 20,
          // A altura de linha padrão da Fraunces (fonte serifada) tem
          // mais "leading" do que o Material espera pra centralizar o
          // título junto com o ícone de voltar — sem isso o texto fica
          // visivelmente mais baixo que a seta. height:1.0 remove esse
          // espaço extra e alinha os dois.
          height: 1.0,
        ),
      ),
      cardTheme: CardThemeData(color: AppColors.bg2),
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
          side: BorderSide(color: AppColors.muted),
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
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.muted)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.gold)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.gold : AppColors.muted,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: AppColors.gold),
      // Transição de tela única e centralizada (29/08/2026, pedido de
      // Rhoney: "aberturas, fechamentos, transições suaves, elegantes e
      // dinâmicas") — pageTransitionsTheme troca a transição de TODO
      // Navigator.push(MaterialPageRoute(...)) do app de uma vez, sem
      // precisar tocar nenhuma das dezenas de telas que já chamam isso.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SmoothPageTransitionsBuilder(),
          TargetPlatform.iOS: _SmoothPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Estilo "metadado técnico" (JetBrains Mono) — DESIGN_SYSTEM.md §2:
  /// streak, XP numérico, nunca em texto de leitura corrida. `color`
  /// nulo (em vez de default = AppColors.bone) porque um valor default
  /// de parâmetro precisa ser compile-time constant, e AppColors.bone
  /// deixou de ser const (agora resolve pro tom ativo em runtime).
  // Cache por (cor, tamanho) — achado real de performance (29/08/2026,
  // Rhoney: "telas saltando/lentas" no aparelho real): technicalStyle é
  // chamado dezenas de vezes por tela (XP, streak, qualquer texto
  // "técnico" do app), e cada chamada de GoogleFonts.jetBrainsMono(...)
  // refaz um lookup no registro interno do pacote — nada caro isolado,
  // mas somado a cada rebuild (inclusive rebuilds frequentes como a
  // tela de Movimento durante uma caminhada) tem custo real num
  // aparelho de entrada. Memoizar devolve a MESMA instância de
  // TextStyle pra cada combinação já vista, sem custo de novo lookup.
  static final Map<(Color, double), TextStyle> _technicalStyleCache = {};

  static TextStyle technicalStyle({Color? color, double fontSize = 16}) {
    final resolvedColor = color ?? AppColors.bone;
    final key = (resolvedColor, fontSize);
    return _technicalStyleCache[key] ??=
        GoogleFonts.jetBrainsMono(color: resolvedColor, fontSize: fontSize, fontWeight: FontWeight.w500);
  }
}

/// Transição única do app (29/08/2026, pedido de Rhoney: "transições
/// suaves, elegantes e dinâmicas") — fade + leve deslizar de baixo pra
/// cima na entrada (mesma curva easeOutCubic já usada nas animações de
/// XP/gráficos do app, pra manter uma única "linguagem de movimento"),
/// com a tela de trás esmaecendo de leve durante a transição em vez de
/// ficar estática — sensação de profundidade, não só um corte seco.
class _SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const _SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final entering = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    // Esmaece esta tela quando ELA vira a "de trás" (outra sendo
    // empurrada por cima) — dá a sensação de profundidade/camadas em
    // vez de um corte seco entre as duas.
    final recedingBehind = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.85).animate(recedingBehind),
      child: FadeTransition(
        opacity: entering,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero).animate(entering),
          child: child,
        ),
      ),
    );
  }
}
