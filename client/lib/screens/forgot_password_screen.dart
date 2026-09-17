import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

/// RECUPERACAO_DE_SENHA_E_LOGIN_V1.md §2.1 — "Esqueci minha senha".
/// Supabase Auth já oferece esse fluxo nativamente (resetPasswordForEmail):
/// expiração do link, geração/validação do token e a resposta neutra
/// quanto à existência do e-mail (nunca revela se está cadastrado) já
/// vêm de fábrica do GoTrue — nada disso precisou ser reimplementado
/// aqui. O e-mail leva de volta pro app via kMentalAuthRedirect (mesmo
/// deep link do login OAuth); main.dart detecta
/// AuthChangeEvent.passwordRecovery e abre ResetPasswordScreen.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = l10n.forgotPasswordMissingEmailError);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email, redirectTo: kMentalAuthRedirect);
    } on AuthException catch (_) {
      // Mesmo em erro (ex.: e-mail malformado rejeitado pelo GoTrue), a
      // mensagem final é a MESMA de sucesso — nunca revela se o e-mail
      // está cadastrado nem o motivo técnico da falha (doc §2.1: "resposta
      // neutra quanto à existência do e-mail no sistema").
    } catch (_) {
      // Falha de conexão de verdade também cai na mesma confirmação
      // neutra — o pior caso é o usuário tentar de novo, nunca vazar
      // informação sobre a conta.
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _sent = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.forgotPasswordTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _sent
                  ? [
                      Text(
                        l10n.forgotPasswordConfirmationMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.forgotPasswordBackToLoginButton),
                      ),
                    ]
                  : [
                      Text(
                        l10n.forgotPasswordInstructions,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: InputDecoration(labelText: l10n.loginEmailLabel),
                      ),
                      const SizedBox(height: 24),
                      if (_loading)
                        const Center(child: CircularProgressIndicator())
                      else
                        FilledButton(
                          onPressed: _submit,
                          child: Text(l10n.forgotPasswordSendButton),
                        ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, style: TextStyle(color: AppColors.error), textAlign: TextAlign.center),
                      ],
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
