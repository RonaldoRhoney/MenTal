import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Login real via Supabase Auth (docs/02_IMPLEMENTATION/SUPABASE_SETUP.md
/// §5, FAMILY_SAFETY.md §3.1). Ordem de método decidida por Rhoney:
/// 1) Google, 2) email/senha, 3) Facebook — a ordem de exibição não pode
/// significar fricção extra pra quem não tem conta Google, então
/// email/senha fica igualmente visível, nunca enterrado.
///
/// Google e Facebook usam signInWithOAuth (fluxo via navegador do
/// sistema, nunca SDK nativo) — não depende de SHA-1 de nenhuma keystore
/// específica, só do deep link de callback registrado no
/// AndroidManifest.xml e cadastrado em Supabase Dashboard → Authentication
/// → URL Configuration → Redirect URLs.
///
/// Esta tela não decide se a sessão foi criada — quem ouve
/// authStateChanges (main.dart) decide a navegação. Aqui só dispara o
/// login (OAuth ou signInWithPassword/signUp) e mostra erro/confirmação.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _signUpMode = false;
  bool _loading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static const _oauthRedirect = 'com.rhoneyinc.mental://login-callback';

  Future<void> _signInWithProvider(OAuthProvider provider) async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      // launchMode padrão (externalApplication) abre o navegador do
      // sistema — depois do login, o Supabase redireciona de volta pro
      // app pelo deep link (AndroidManifest.xml). authStateChanges em
      // main.dart navega sozinho quando a sessão chegar.
      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: _oauthRedirect,
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Erro de conexão. Tente de novo.');
    } finally {
      // Não desliga o loading aqui de propósito: o navegador do sistema
      // assume a tela; quando o usuário voltar (login concluído ou
      // cancelado), o widget é reconstruído do zero pela navegação real
      // de main.dart, ou o app volta a este mesmo estado se cancelou —
      // nesse caso reativar o formulário é o certo.
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = l10n.loginMissingFieldsError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      if (_signUpMode) {
        final response = await auth.signUp(email: email, password: password);
        // "Confirm email" está ligado no projeto (SUPABASE_SETUP.md §1.5)
        // — signUp não retorna sessão ativa até o link do e-mail ser
        // clicado. main.dart navega sozinho quando a sessão de fato
        // existir (authStateChanges); aqui só avisa o próximo passo.
        if (response.session == null && mounted) {
          setState(() => _info = l10n.loginCheckEmailMessage);
        }
      } else {
        await auth.signInWithPassword(email: email, password: password);
        // Sucesso: authStateChanges em main.dart navega sozinho.
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Erro de conexão. Tente de novo.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // BRAND.md §1: o nome nunca aparece sozinho, sem o slogan
                // por perto, em nenhum primeiro contato.
                Text(
                  l10n.loginTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.loginSlogan,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 40),
                OutlinedButton.icon(
                  onPressed: _loading ? null : () => _signInWithProvider(OAuthProvider.google),
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: Text(l10n.loginGoogleButton),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(l10n.loginOrDivider, style: const TextStyle(color: AppColors.muted)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: l10n.loginEmailLabel),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.loginPasswordLabel),
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else
                  FilledButton(
                    onPressed: _submit,
                    child: Text(_signUpMode ? l10n.loginSignUpButton : l10n.loginSignInButton),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                            _signUpMode = !_signUpMode;
                            _error = null;
                            _info = null;
                          }),
                  child: Text(_signUpMode ? l10n.loginToggleToSignIn : l10n.loginToggleToSignUp),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
                ],
                if (_info != null) ...[
                  const SizedBox(height: 8),
                  Text(_info!, style: const TextStyle(color: AppColors.teal), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _loading ? null : () => _signInWithProvider(OAuthProvider.facebook),
                  icon: const Icon(Icons.facebook_outlined, size: 22),
                  label: Text(l10n.loginFacebookButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
