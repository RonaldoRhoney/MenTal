import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Login real via Supabase Auth (docs/02_IMPLEMENTATION/SUPABASE_SETUP.md
/// §5). Ordem decidida por Rhoney em 24/08/2026: Google, Facebook,
/// email/senha — revisada depois de MENTAL-DIR-001 (MENTAL passou a
/// ser exclusivo pra maiores de 18 anos), quando deixou de existir a
/// preocupação original de FAMILY_SAFETY.md §3.1 (criança sem conta
/// Google ficando com email/senha "enterrado" atrás de dois sociais).
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
                _GoogleButton(
                  loading: _loading,
                  onPressed: () => _signInWithProvider(OAuthProvider.google),
                  label: l10n.loginGoogleButton,
                ),
                const SizedBox(height: 12),
                _FacebookButton(
                  loading: _loading,
                  onPressed: () => _signInWithProvider(OAuthProvider.facebook),
                  label: l10n.loginFacebookButton,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão do Google seguindo as diretrizes oficiais de branding (fundo
/// claro, nunca escuro — Google exige contraste específico pro logo
/// multicolor): base branca, borda sutil, "G" pintado nas 4 cores
/// oficiais (sem depender de asset de imagem/SVG externo).
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.loading, required this.onPressed, required this.label});

  final bool loading;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F1F1F),
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          side: const BorderSide(color: Color(0xFFDADCE0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GoogleGlyph(),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "G" pintado nas 4 cores oficiais do Google (azul/vermelho/amarelo/
/// verde) via CustomPaint — sem depender de fonte de ícone nem asset
/// externo, evita o cinza monocromático de Icons.g_mobiledata que não
/// é reconhecível como a marca real.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 20, height: 20, child: CustomPaint(painter: _GoogleGlyphPainter()));
  }
}

class _GoogleGlyphPainter extends CustomPainter {
  const _GoogleGlyphPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.22;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    void arc(double startDeg, double sweepDeg, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startDeg * 3.1415926535 / 180, sweepDeg * 3.1415926535 / 180, false, paint);
    }

    // Quatro arcos formando o círculo do "G", cores oficiais do Google.
    arc(-40, 100, const Color(0xFF4285F4)); // azul
    arc(60, 90, const Color(0xFF34A853)); // verde
    arc(150, 80, const Color(0xFFFBBC05)); // amarelo
    arc(230, 90, const Color(0xFFEA4335)); // vermelho

    // Barra horizontal do "G" (traço característico), na cor azul.
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.48, size.height * 0.42, size.width * 0.46, strokeWidth * 0.85),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Botão do Facebook seguindo o branding oficial: fundo no azul da
/// marca (#1877F2), ícone e texto em branco.
class _FacebookButton extends StatelessWidget {
  const _FacebookButton({required this.loading, required this.onPressed, required this.label});

  final bool loading;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: const Icon(Icons.facebook, color: Colors.white, size: 24),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1877F2),
          disabledBackgroundColor: const Color(0xFF1877F2).withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
    );
  }
}
