import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'api/api_client.dart';
import 'api/session_store.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/age_gate_screen.dart';
import 'screens/home_screen.dart';
import 'services/push_service.dart';
import 'theme/app_theme.dart';

/// Ajustar para a URL real do backend Render antes de build de release.
///
/// Em desenvolvimento local, 127.0.0.1 funciona para Web e desktop
/// (mesmo host da máquina de desenvolvimento) e para **dispositivo Android
/// físico conectado via USB com `adb reverse tcp:8000 tcp:8000`** rodado
/// antes de abrir o app (o reverse faz o 127.0.0.1 do celular apontar de
/// volta para o 127.0.0.1 do notebook via USB).
///
/// Only emulador Android usa o alias especial `10.0.2.2` em vez de
/// 127.0.0.1 (não é um IP real, só existe dentro do emulador, sem precisar
/// de adb reverse) — não é o caso coberto aqui porque a validação deste
/// slice foi feita em dispositivo físico, não emulador. Se um dia alguém
/// rodar em emulador, trocar manualmente ou usar --dart-define.
const String kApiBaseUrl = 'http://127.0.0.1:8000';

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

/// Ponto de entrada: resolve sessão local (modo DEV_INSECURE, ver
/// api_client.dart) e decide entre Age Gate e Home. Fora do escopo deste
/// Vertical Slice: splash screen com sequência de marca (BRAND.md) e login
/// real via Supabase Auth — este widget resolve só o mínimo necessário
/// para exercitar o core loop completo.
class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  ApiClient? _client;
  bool _ageGateDone = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final userId = await SessionStore().getOrCreateUserId();
    final client = ApiClient(baseUrl: kApiBaseUrl, userId: userId);
    setState(() {
      _client = client;
    });
    // Fire-and-forget: registro de push nunca deve atrasar a navegação
    // pro Age Gate/Home (PushService já é resiliente a qualquer falha).
    PushService.instance.initializeAndRegister(client);
  }

  @override
  Widget build(BuildContext context) {
    final client = _client;
    if (client == null) {
      // Loading com feedback explícito (ARCHITECTURE.md §3, mitigação de
      // cold start) — nunca tela branca/travada.
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.preparingChallenge),
            ],
          ),
        ),
      );
    }

    if (!_ageGateDone) {
      return AgeGateScreen(
        client: client,
        onDone: () => setState(() => _ageGateDone = true),
      );
    }

    return HomeScreen(client: client);
  }
}
