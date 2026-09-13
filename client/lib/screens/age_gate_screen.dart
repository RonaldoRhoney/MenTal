import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../main.dart' show kPrivacyPolicyUrl;
import '../theme/app_theme.dart';

/// MENTAL-DIR-001/POL-002 (24/08/2026): MENTAL passa a ser exclusivo
/// pra maiores de 18 anos — sai a tela de duas opções (menos/mais de 18
/// anos), entra uma confirmação única e obrigatória. Sem confirmar, o
/// botão "Continuar" nunca habilita — não existe caminho de UI que
/// avance tratando alguém como menor de idade (POL-002 §3.2).
class AgeGateScreen extends StatefulWidget {
  const AgeGateScreen({super.key, required this.client, required this.onDone});

  final ApiClient client;
  final VoidCallback onDone;

  @override
  State<AgeGateScreen> createState() => _AgeGateScreenState();
}

class _AgeGateScreenState extends State<AgeGateScreen> {
  bool _confirmed = false;
  bool _loading = false;
  String? _error;

  Future<void> _continue() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.client.confirmMajority();
      widget.onDone();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.ageGateTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                l10n.ageGateSubtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              // Redesign 13/09/2026 (mesmo padrão de cartão já aplicado
              // em profile_screen.dart: AppColors.bg2 + borda dourada
              // suave) — agrupa a confirmação/termos/botão como uma
              // unidade visual só, em vez de itens soltos flutuando na
              // tela.
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                // Material(transparency) evita o aviso do framework de
                // que o CheckboxListTile perderia o ink splash por
                // causa do Container colorido acima (mesmo ajuste já
                // feito em profile_screen.dart).
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CheckboxListTile(
                        value: _confirmed,
                        onChanged: _loading
                            ? null
                            : (value) =>
                                setState(() => _confirmed = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.ageGateCheckboxLabel),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.muted),
                          children: [
                            TextSpan(text: l10n.ageGateTermsLinkPrefix),
                            TextSpan(
                              text: l10n.ageGateTermsLinkText,
                              style: TextStyle(
                                  color: AppColors.teal,
                                  decoration: TextDecoration.underline),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => launchUrl(
                                    Uri.parse(kPrivacyPolicyUrl),
                                    mode: LaunchMode.externalApplication),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_loading)
                        const Center(child: CircularProgressIndicator())
                      else
                        FilledButton(
                          onPressed: _confirmed ? _continue : null,
                          child: Text(l10n.ageGateContinueButton),
                        ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(_error!,
                            style: TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
