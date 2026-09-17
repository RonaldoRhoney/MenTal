import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// RECUPERACAO_DE_SENHA_E_LOGIN_V1.md §2.1 — aberto por main.dart quando
/// o Supabase entrega AuthChangeEvent.passwordRecovery (usuário tocou no
/// link do e-mail de redefinição). A sessão ativa neste momento é uma
/// sessão de recuperação temporária, só válida pra chamar
/// auth.updateUser — nunca deve ser tratada como um login normal (main.dart
/// intercepta esse evento ANTES de _updateClientFromSession, então o app
/// nunca entra direto na Home com essa sessão). Depois de trocar a senha
/// com sucesso, `onDone` desloga essa sessão temporária e volta pro
/// LoginScreen — o usuário entra de novo, já com a senha nova.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    // Mesmo mínimo que o próprio Supabase Auth já exige server-side
    // (6 caracteres) — valida aqui só pra dar o erro na hora, sem
    // esperar o round-trip de rede pra descobrir a mesma coisa.
    if (password.length < 6) {
      setState(() => _error = l10n.resetPasswordTooShortError);
      return;
    }
    if (password != confirm) {
      setState(() => _error = l10n.resetPasswordMismatchError);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: password));
      if (mounted) setState(() => _done = true);
    } on AuthException catch (_) {
      // Sessão de recuperação expirada/já usada é o caso mais comum de
      // falha aqui (link antigo reaberto, ou já usado uma vez) — mesma
      // mensagem pros dois, sem detalhar motivo técnico do GoTrue.
      if (mounted) setState(() => _error = l10n.resetPasswordExpiredLinkError);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.resetPasswordExpiredLinkError);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _finish() async {
    // A sessão de recuperação nunca deve continuar valendo como se fosse
    // um login normal — desloga antes de devolver o controle a main.dart,
    // que volta pro LoginScreen (onDone).
    await Supabase.instance.client.auth.signOut();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      // Sem "voltar" no meio do fluxo — a sessão de recuperação não deve
      // vazar pra nenhuma outra tela do app antes de virar uma senha nova
      // de verdade ou o usuário desistir explicitamente (mesmo princípio
      // do Age Gate obrigatório, WillPopScope/PopScope já usado ali).
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.resetPasswordTitle), automaticallyImplyLeading: false),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _done
                    ? [
                        Text(
                          l10n.resetPasswordSuccessMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(onPressed: _finish, child: Text(l10n.loginSignInButton)),
                      ]
                    : [
                        Text(
                          l10n.resetPasswordInstructions,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(labelText: l10n.resetPasswordNewPasswordLabel),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmController,
                          obscureText: true,
                          decoration: InputDecoration(labelText: l10n.resetPasswordConfirmPasswordLabel),
                        ),
                        const SizedBox(height: 24),
                        if (_loading)
                          const Center(child: CircularProgressIndicator())
                        else
                          FilledButton(onPressed: _submit, child: Text(l10n.resetPasswordSubmitButton)),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(_error!, style: TextStyle(color: AppColors.error), textAlign: TextAlign.center),
                        ],
                      ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
