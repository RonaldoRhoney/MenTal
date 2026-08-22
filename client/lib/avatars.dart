import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

/// USER_PROFILE.md (aprovado): avatares pré-definidos e ilustrados, nunca
/// upload de foto real — risco de moderação/identificação de menor num
/// público misto. Catálogo fixo de 8 emoji (Unicode padrão, nunca gerado
/// por IA), tema natureza/animais coerente com o gerador de apelidos já
/// existente no backend (Coruja, Raposa, Lontra...), sem forçar uma
/// correspondência 1:1 exata entre avatar e apelido sorteado.
const Map<String, String> kAvatarEmoji = {
  'owl': '🦉',
  'fox': '🦊',
  'otter': '🦦',
  'turtle': '🐢',
  'parrot': '🦜',
  'dolphin': '🐬',
  'butterfly': '🦋',
  'bee': '🐝',
};

/// Círculo simples com o emoji do avatar — mesmo lugar visual onde o
/// nickname já aparece (Amigos, Ranking, Batalhas), conforme USER_PROFILE.md
/// §4: "Avatar: visível onde o nickname aparece". Sem avatar escolhido,
/// mostra um círculo neutro vazio (nunca quebra o layout).
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({super.key, required this.avatarId, this.size = 36});

  final String? avatarId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final emoji = avatarId != null ? kAvatarEmoji[avatarId] : null;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.bg2, shape: BoxShape.circle),
      child: emoji != null ? Text(emoji, style: TextStyle(fontSize: size * 0.55)) : null,
    );
  }
}
