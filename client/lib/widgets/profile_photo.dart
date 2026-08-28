import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Foto de perfil real (revisão 27/08/2026 — USER_PROFILE.md §3.1) — substitui
/// o antigo catálogo de avatares emoji (avatars.dart, removido). photoUrl
/// chega do backend já filtrado pela moderação fail-closed
/// (services.public_photo_url): só é não-nulo quando aprovado, então este
/// widget nunca decide visibilidade sozinho, só renderiza o que a API
/// mandou. Sem foto (ou moderação ainda pendente/rejeitada), mostra um
/// ícone de pessoa neutro — nunca quebra o layout.
///
/// Fundo `AppColors.bg` (mais escuro que `bg2`) no estado vazio: achado
/// real do redesign de 26/08/2026 — o avatar antigo usava `bg2` sobre um
/// card que também é `bg2`, ficando invisível por falta de contraste.
class ProfilePhotoCircle extends StatelessWidget {
  const ProfilePhotoCircle({super.key, this.photoUrl, this.size = 36});

  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bg,
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.35)),
      ),
      child: photoUrl != null
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.person, size: size * 0.55, color: AppColors.muted),
            )
          : Icon(Icons.person, size: size * 0.55, color: AppColors.muted),
    );
  }
}
