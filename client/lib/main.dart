import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api/api_client.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/age_gate_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/mandatory_onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_splash_screen.dart';
import 'services/push_service.dart';
import 'theme/app_theme.dart';
import 'widgets/game_background.dart';

/// Produção (Render) por padrão — qualquer build normal (incluindo os
/// builds de release/AAB pra loja) fala com o backend real. Pra
/// desenvolvimento local contra o backend rodando na própria máquina,
/// sobrescrever com --dart-define=API_BASE_URL=http://127.0.0.1:8000
/// (dispositivo físico via USB precisa de `adb reverse tcp:8000 tcp:8000`
/// rodado antes; emulador usa o alias `10.0.2.2` em vez de 127.0.0.1).
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://mental-api-n37u.onrender.com',
);

/// docs/02_IMPLEMENTATION/SUPABASE_SETUP.md — projeto real do MENTAL.
/// anonKey NÃO é segredo (protegida por RLS no banco, feita pra ficar
/// embutida no app) — a URL e a chave juntas só permitem o que as
/// policies do Supabase já autorizam.
const String kSupabaseUrl = 'https://daogwiqwqplcvehdhksf.supabase.co';
const String kSupabasePublishableKey = 'sb_publishable_-91P1bkCU4bGLEGPJ84l_A_CPqCRZys';

/// MENTAL-DIR-001 (24/08/2026): hospedagem definitiva em domínio próprio
/// (mental.rhoneyinc.com) continua sendo responsabilidade de Rhoney, fora
/// do escopo técnico do Claude Code (MENTAL-POL-002 §8) — trocar por essa
/// URL quando ela existir. Até lá, hospedado via GitHub Pages (branch
/// `gh-pages`, gratuito, sem risco de cobrança) só pra desbloquear a
/// submissão no Google Play, que exige uma URL pública real já agora.
const String kPrivacyPolicyUrl = 'https://ronaldorhoney.github.io/MenTal/';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Sem google-services.json (ex.: build local sem o arquivo do
    // Firebase) o app continua funcionando normalmente — notificações
    // push são reforço, nunca requisito (mesmo princípio de
    // PushService).
  }
  await Supabase.initialize(url: kSupabaseUrl, publishableKey: kSupabasePublishableKey);
  runApp(const MentalApp());
}

class MentalApp extends StatelessWidget {
  const MentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MENTAL',
      debugShowCheckedModeBanner: false,
      // ARCHITECTURE_UPDATE_I18N_READY.md: arquitetura i18n-ready desde já
      // (delegates + supportedLocales), mas lançamento é 100% pt-BR — sem
      // seletor de idioma na UI, sem conteúdo em outro idioma ainda.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // DESIGN_SYSTEM.md: tema único e centralizado — nenhuma tela define
      // cor ou fonte própria (lib/theme/app_theme.dart é a fonte única).
      theme: AppTheme.themeData,
      // Fundo com profundidade em todo o app (pedido de Rhoney,
      // 29/08/2026: "esse fundo tod escuro está muito fora do escopo de
      // um game") — um único ponto de aplicação via builder, em vez de
      // repetir o gradiente tela por tela. Cada Scaffold continua com
      // backgroundColor transparente (AppTheme.themeData) pra deixar o
      // gradiente aparecer por trás.
      builder: (context, child) => GameBackground(child: child ?? const SizedBox.shrink()),
      home: const AppEntryPoint(),
    );
  }
}

/// Ponto de entrada: ouve a sessão real do Supabase Auth (login via
/// LoginScreen) e decide entre Login, Age Gate e Home. Sem sessão, nunca
/// chama nenhum endpoint do backend — só depois de autenticado é que um
/// ApiClient (com o accessToken real) é construído.
class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  ApiClient? _client;
  // Achado real (2026-08-26): a tela de confirmação de maioridade
  // aparecia a cada login, mesmo pra quem já tinha confirmado antes —
  // esse estado só existia em memória, nunca era checado contra o
  // backend. Agora é tri-state: null = ainda checando GET /profile,
  // true = já confirmou antes (pula a tela), false = precisa confirmar
  // agora (só na primeira vez por conta).
  bool? _ageConfirmed;
  String? _ageCheckError;
  // Cadastro mínimo obrigatório (26/08/2026) — mesmo tri-state e mesma
  // chamada GET /profile do age gate, checando onboarding_completed_at.
  bool? _onboardingCompleted;
  // Splash de boas-vindas: uma vez por sessão de login, nunca de novo
  // enquanto a mesma sessão continuar ativa (ex.: navegar entre telas,
  // voltar do background).
  bool _welcomeSplashDone = false;
  bool _splashDone = false;
  late final Stream<AuthState> _authStateStream;
  String? _lastAccessToken;

  @override
  void initState() {
    super.initState();
    _authStateStream = Supabase.instance.client.auth.onAuthStateChange;
    _updateClientFromSession(Supabase.instance.client.auth.currentSession);
  }

  // Reconstrói o ApiClient quando a sessão muda de verdade — login,
  // logout, e também AuthChangeEvent.tokenRefreshed (o SDK renova o JWT
  // sozinho antes de expirar; sem isso o client ficaria preso ao token
  // antigo numa sessão longa).
  //
  // Achado real em teste informal (2026-08-23): o StreamBuilder chama
  // este método a cada evento do onAuthStateChange, e alguns desses
  // eventos repetem o MESMO accessToken (não é sempre um token novo).
  // Sem a checagem abaixo, cada repetição registrava o push de novo
  // (PushService.initializeAndRegister, que também reassina
  // onTokenRefresh.listen sem cancelar o anterior) — visto em produção
  // como um loop de POST /notifications/register-token quase 1x/segundo,
  // saturando o pool de conexões do banco e travando outras requisições
  // (ex.: /challenges/next) por falta de conexão livre.
  void _updateClientFromSession(Session? session) {
    final accessToken = session?.accessToken;
    if (accessToken == _lastAccessToken) return;
    _lastAccessToken = accessToken;
    setState(() {
      _client = accessToken == null ? null : ApiClient(baseUrl: kApiBaseUrl, accessToken: accessToken);
      _ageConfirmed = null;
      _ageCheckError = null;
      _onboardingCompleted = null;
      _welcomeSplashDone = false;
    });
    if (accessToken != null) {
      // Fire-and-forget: registro de push nunca deve atrasar a navegação
      // pro Age Gate/Home (PushService já é resiliente a qualquer falha).
      // addPostFrameCallback garante que já existe uma árvore de widgets
      // montada com Navigator (initializeAndRegister agora pode abrir um
      // diálogo de priming, auditoria de conformidade Google Play,
      // 29/08/2026, item 4) — chamar direto do initState, antes do
      // primeiro frame, quebraria isso.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) PushService.instance.initializeAndRegister(_client!, context);
      });
      _checkProfileStatus(_client!);
    }
  }

  Future<void> _checkProfileStatus(ApiClient client) async {
    try {
      final profile = await client.getProfile();
      if (!mounted || client != _client) return;
      setState(() {
        _ageConfirmed = profile['age_confirmed_at'] != null;
        _onboardingCompleted = profile['onboarding_completed_at'] != null;
      });
    } on ApiException catch (e) {
      if (!mounted || client != _client) return;
      setState(() => _ageCheckError = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    // BRAND.md §3: sequência de splash (wordmark → slogan) sempre roda
    // primeiro, uma única vez por abertura do app — antes de qualquer
    // decisão de Login/Age Gate/Home.
    if (!_splashDone) {
      return SplashScreen(onDone: () => setState(() => _splashDone = true));
    }
    return StreamBuilder<AuthState>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // build() não é o lugar de chamar setState, mas aqui é seguro:
          // só reconstrói o ApiClient quando o accessToken de fato mudou
          // (ver _updateClientFromSession), StreamBuilder já filtra
          // rebuilds desnecessários pela própria natureza do stream.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateClientFromSession(snapshot.data!.session);
          });
        }

        final client = _client;
        if (client == null) {
          return const LoginScreen();
        }

        final l10n = AppLocalizations.of(context)!;

        final ageCheckError = _ageCheckError;
        if (ageCheckError != null) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(ageCheckError, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() => _ageCheckError = null);
                        _checkProfileStatus(client);
                      },
                      child: Text(l10n.tryAgainButton),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final ageConfirmed = _ageConfirmed;
        if (ageConfirmed == null) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l10n.preparingChallenge),
                  ],
                ),
              ),
            ),
          );
        }

        if (!ageConfirmed) {
          return AgeGateScreen(
            client: client,
            onDone: () => setState(() => _ageConfirmed = true),
          );
        }

        final onboardingCompleted = _onboardingCompleted;
        if (onboardingCompleted == null) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l10n.preparingChallenge),
                  ],
                ),
              ),
            ),
          );
        }

        if (!onboardingCompleted) {
          return MandatoryOnboardingScreen(
            client: client,
            onDone: () => setState(() => _onboardingCompleted = true),
          );
        }

        if (!_welcomeSplashDone) {
          return WelcomeSplashScreen(onDone: () => setState(() => _welcomeSplashDone = true));
        }

        return HomeScreen(client: client);
      },
    );
  }
}
