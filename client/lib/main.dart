import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'api/session_store.dart';
import 'screens/age_gate_screen.dart';
import 'screens/home_screen.dart';

/// Ajustar para a URL real do backend Render antes de build de release.
/// Em desenvolvimento local, cada plataforma alcança "localhost" do host
/// de um jeito diferente: emulador Android usa o alias especial 10.0.2.2
/// (não é um IP real, só funciona dentro do emulador); Web e desktop
/// (Linux/macOS/Windows) usam 127.0.0.1 normalmente, porque rodam no
/// mesmo host da máquina de desenvolvimento. Detectado em runtime para o
/// mesmo código funcionar em qualquer alvo sem precisar editar na mão.
String get kApiBaseUrl {
  if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000';
  return 'http://127.0.0.1:8000';
}

void main() {
  runApp(const MentalApp());
}

class MentalApp extends StatelessWidget {
  const MentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MENTAL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B1B3A),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
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
    setState(() {
      _client = ApiClient(baseUrl: kApiBaseUrl, userId: userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final client = _client;
    if (client == null) {
      // Loading com feedback explícito (ARCHITECTURE.md §3, mitigação de
      // cold start) — nunca tela branca/travada.
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparando seu desafio...'),
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
