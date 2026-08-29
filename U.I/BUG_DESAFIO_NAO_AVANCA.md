# MENTAL — BUG CRÍTICO: Desafio não avança após resposta

**Status:** Prioridade máxima — bloqueia o uso normal do app, reportado por testadores no teste fechado.
**Tipo:** Correção de bug, não é feature nova.

---

## 1. Descrição do problema

Ao responder qualquer desafio (independente de território/categoria), seja acertando ou errando a resposta, a tela **não avança para o próximo desafio/pergunta**. O usuário permanece na mesma tela, presa no mesmo desafio, sem conseguir progredir no nível.

Isso está impedindo o uso normal do app — testadores reportaram o problema em qualquer pergunta, não é um caso isolado de um território específico.

## 2. Investigação necessária

Peço que você investigue e corrija a causa raiz, cobrindo pelo menos estas hipóteses (pode haver mais de uma envolvida):

1. **Fluxo de navegação pós-resposta:** o callback/handler que deveria disparar a transição para o próximo desafio após o usuário responder (seja pelo fluxo padrão ou pelo fluxo de Feedback Pós-Nível, já que ele foi adicionado recentemente e pode ter interferido nesse fluxo) — verificar se está sendo chamado, e se está, se a navegação de fato ocorre.
2. **Estado da tela não sendo resetado:** verificar se o widget/tela do desafio está reconstruindo com o novo desafio mas mantendo estado antigo (ex: resposta já marcada, timer zerado, flags de "já respondido" não resetadas) — isso pode fazer parecer que "voltou pro mesmo lugar" quando na verdade tecnicamente trocou de desafio mas a tela renderiza como se nada tivesse mudado.
3. **Regressão recente:** este bug pode ter sido introduzido por alguma mudança recente — verificar especificamente se está relacionado à implementação do **Feedback Pós-Nível** (adicionado recentemente) ou aos ajustes de bug relacionados a ele que pedimos (o feedback estava disparando após cada resposta em vez de só ao final do nível — se a correção desse bug anterior alterou o fluxo de navegação, pode ter introduzido este problema novo).
4. **Erro silencioso:** verificar se há alguma exception sendo engolida no fluxo de submissão de resposta (ex: chamada à API de registro de tentativa falhando silenciosamente, sem o app tratar o erro nem seguir em frente) — isso incluiria checar logs do backend em produção durante o período em que os testadores reportaram o problema.

## 3. Escopo do teste antes de considerar corrigido

Antes de dar como resolvido, validar manualmente (não só testes automatizados) o fluxo completo em pelo menos:
- Resposta correta em um território do Mundo da Linguagem.
- Resposta correta em um território do Mundo da Mente Lógica.
- Resposta incorreta em qualquer território.
- Uso de dica antes de responder, seguido de resposta (garantir que o fluxo de penalidade por dica não interfere na navegação).
- Fluxo completo de um nível inteiro até o Feedback Pós-Nível aparecer corretamente ao final (não a cada resposta).

## 4. Critério de aceite

- Usuário consegue completar um nível inteiro, desafio após desafio, sem travar em nenhuma tela.
- Comportamento correto tanto em acerto quanto em erro.
- Testes automatizados existentes (backend e Flutter) continuam passando, e adicionar cobertura de teste específica para este fluxo (resposta → avanço de tela) para evitar regressão futura.
- `flutter analyze` limpo.

## 5. Observação

Por favor, ao identificar a causa raiz, me explique brevemente o que causou o problema antes de aplicar a correção — preciso entender se foi uma regressão da mudança do Feedback Pós-Nível ou algo não relacionado, para eu avaliar se há outros pontos do app que merecem revisão pelo mesmo motivo.
