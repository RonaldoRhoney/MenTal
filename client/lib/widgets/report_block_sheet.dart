import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Denunciar/bloquear (auditoria de conformidade Google Play, 29/08/2026,
/// item 6 — "UGC precisa de mecanismo de bloqueio, além da denúncia").
/// A denúncia (POST /social/report) já existia no backend desde
/// 28/08/2026, mas nenhuma tela do app chamava — bottom sheet
/// compartilhado entre as telas que já expõem user_id de outro jogador
/// (hoje só Amigos; Ranking/Batalhas deliberadamente não expõem
/// user_id, ver RankingEntry/BattleOut).
///
/// Mostra um resultado (SnackBar) e devolve `true` se um bloqueio foi
/// aplicado (quem chamou pode recarregar a lista, já que bloquear
/// remove qualquer amizade existente no backend).
Future<bool> showReportBlockSheet(
  BuildContext context, {
  required ApiClient client,
  required String targetUserId,
  required String targetNickname,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.bg2,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.muted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: AppColors.gold),
            title: Text(l10n.reportUserOption),
            onTap: () => Navigator.of(sheetContext).pop('report'),
          ),
          ListTile(
            leading: const Icon(Icons.block_outlined, color: AppColors.error),
            title: Text(l10n.blockUserOption),
            onTap: () => Navigator.of(sheetContext).pop('block'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return false;

  if (action == 'report') {
    final reason = await _promptReportReason(context);
    if (reason == null || reason.trim().isEmpty || !context.mounted) return false;
    try {
      await client.reportUser(reportedUserId: targetUserId, reason: reason.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.reportUserSuccessMessage)));
      }
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
    return false;
  }

  final confirmed = await _confirmBlock(context, targetNickname);
  if (confirmed != true || !context.mounted) return false;
  try {
    await client.blockUser(targetUserId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.blockUserSuccessMessage(targetNickname))));
    }
    return true;
  } on ApiException catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    return false;
  }
}

Future<String?> _promptReportReason(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.bg2,
      title: Text(l10n.reportUserDialogTitle),
      content: TextField(
        controller: controller,
        maxLength: 500,
        maxLines: 3,
        autofocus: true,
        decoration: InputDecoration(hintText: l10n.reportUserDialogHint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.cancelButton)),
        FilledButton(onPressed: () => Navigator.of(dialogContext).pop(controller.text), child: Text(l10n.reportUserDialogSendButton)),
      ],
    ),
  );
}

Future<bool?> _confirmBlock(BuildContext context, String targetNickname) async {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.bg2,
      title: Text(l10n.blockUserDialogTitle),
      content: Text(l10n.blockUserDialogMessage(targetNickname)),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancelButton)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.blockUserOption),
        ),
      ],
    ),
  );
}
