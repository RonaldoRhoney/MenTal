import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api/api_client.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/age_gate_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/push_service.dart';
import 'theme/app_theme.dart';

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
  bool _ageGateDone = false;
  late final Stream<AuthState> _authStateStream;

  @override
  void initState() {
    super.initState();
    _authStateStream = Supabase.instance.client.auth.onAuthStateChange;
    _updateClientFromSession(Supabase.instance.client.auth.currentSession);
  }

  // Reconstrói o ApiClient sempre que a sessão muda — login, logout, e
  // também AuthChangeEvent.tokenRefreshed (o SDK renova o JWT sozinho
  // antes de expirar; sem isso o client ficaria preso ao token antigo
  // numa sessão longa).
  void _updateClientFromSession(Session? session) {
    final accessToken = session?.accessToken;
    setState(() {
      _client = accessToken == null ? null : ApiClient(baseUrl: kApiBaseUrl, accessToken: accessToken);
      if (accessToken == null) _ageGateDone = false;
    });
    if (accessToken != null) {
      // Fire-and-forget: registro de push nunca deve atrasar a navegação
      // pro Age Gate/Home (PushService já é resiliente a qualquer falha).
      PushService.instance.initializeAndRegister(_client!);
    }
  }

  @override
  Widget build(BuildContext context) {
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

        if (!_ageGateDone) {
          return AgeGateScreen(
            client: client,
            onDone: () => setState(() => _ageGateDone = true),
          );
        }

        return HomeScreen(client: client);
      },
    );
  }
}
