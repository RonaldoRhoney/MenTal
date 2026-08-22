import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mental/main.dart';

void main() {
  setUpAll(() async {
    // supabase_flutter usa shared_preferences pra persistir a sessão
    // localmente — precisa de mock mesmo sem nenhum dado real.
    SharedPreferences.setMockInitialValues({});
    // Login real via Supabase Auth (docs/02_IMPLEMENTATION/SUPABASE_SETUP.md
    // §5): AppEntryPoint chama Supabase.instance diretamente, então o SDK
    // precisa estar inicializado mesmo em teste — URL/chave fake, nenhuma
    // chamada de rede acontece só de inicializar (só ao chamar signIn/signUp).
    await Supabase.initialize(url: 'https://fake.supabase.co', publishableKey: 'fake-key');
  });

  testWidgets('sem sessão, app mostra a tela de login (nunca tela em branco)', (tester) async {
    await tester.pumpWidget(const MentalApp());
    await tester.pump();

    // MENTAL (BRAND.md §1: nome nunca aparece sozinho, sem o slogan por
    // perto, em nenhum primeiro contato) e o formulário de e-mail/senha.
    expect(find.text('MENTAL'), findsOneWidget);
    expect(find.text('Mental é quem conquista com a mente.'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
  });
}
