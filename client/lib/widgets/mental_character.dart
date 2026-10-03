import 'package:flutter/material.dart';

/// MENTAL_PERSONAGEM_MASCOTE_V1.md — o personagem "Mental" (robô
/// companheiro com "miolo" de cérebro/sinapse). V1 é imagem estática com
/// crossfade entre poses, não animação com rig (§6.2 do documento: o rig
/// de verdade via Rive exige o editor deles, uma ferramenta visual que
/// não dá pra operar por código — fica para quando esse trabalho manual
/// estiver pronto). Decisão de escopo de Rhoney (03/10/2026).
///
/// §1 do documento — regra permanente: o personagem É o app
/// personificado, nunca tem nome próprio diferente de "Mental". Qualquer
/// fala/texto que o represente deve soar como "o Mental falando".
enum MentalCharacterExpression {
  /// Estado padrão — navegação comum, sem evento específico.
  felizNeutro,

  /// Chamando atenção pra um elemento (dica, botão novo, orientação).
  apontando,

  /// Resposta correta, confirmação.
  okPositivo,

  /// Resposta incorreta — tom suave, nunca zombeteiro ou humilhante
  /// (mesmo princípio de MENTAL_ESPECIFICACAO_FLUXO_PROGRESSAO_MAPA_
  /// RANKING_FEEDBACK_V1.1.md).
  negativoSuave,

  /// Carregamento/processamento (ex.: MENTAL LINGO processando a
  /// pergunta por voz).
  pensando,

  /// Conquista de Desafio, Relâmpago ou Mundo inteiro.
  comemorando,

  /// Boas-vindas, primeiro acesso.
  acenando,

  /// App ocioso por tempo prolongado, ou carregamento mais longo.
  dormindo,
}

extension on MentalCharacterExpression {
  String get _assetName {
    switch (this) {
      case MentalCharacterExpression.felizNeutro:
        return 'feliz_neutro';
      case MentalCharacterExpression.apontando:
        return 'apontando';
      case MentalCharacterExpression.okPositivo:
        return 'ok_positivo';
      case MentalCharacterExpression.negativoSuave:
        return 'negativo_suave';
      case MentalCharacterExpression.pensando:
        return 'pensando';
      case MentalCharacterExpression.comemorando:
        return 'comemorando';
      case MentalCharacterExpression.acenando:
        return 'acenando';
      case MentalCharacterExpression.dormindo:
        return 'dormindo';
    }
  }
}

/// Desenha o personagem Mental na expressão pedida, com crossfade suave
/// ao trocar de [expression] — nunca troca abruptamente de imagem.
/// Respeita "reduzir movimento" do sistema (troca instantânea nesse caso,
/// mesmo princípio já usado em pulse_in.dart).
class MentalCharacter extends StatelessWidget {
  const MentalCharacter({
    super.key,
    this.expression = MentalCharacterExpression.felizNeutro,
    this.size = 120,
  });

  final MentalCharacterExpression expression;
  final double size;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final image = Image.asset(
      'assets/character/${expression._assetName}.png',
      key: ValueKey(expression),
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
    if (reduceMotion) return image;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: image,
    );
  }
}
