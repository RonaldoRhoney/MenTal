# MENTAL — PRODUCT_PRINCIPLES.md

Status: rascunho de Discovery, para aprovação de Rhoney.

Estes princípios são critério de aceite de qualquer tela, fluxo ou peça de
UI entregue no MENTAL — não são sugestão estética.

## 1. Clareza Imediata (vinculante, já definido no kickoff)

> Toda tela deve comunicar sua função em menos de 2 segundos de olhar, sem
> depender de leitura de texto. Um elemento tem prioridade visual clara por
> vez. Poucos elementos muito bem executados > muitos elementos que cabem.

Fonte: `MENTAL_KICKOFF.md` §7. Reproduzido aqui porque é o princípio mais
citado nas decisões de tela ao longo deste pacote de Discovery.

Consequência prática que já nasce daqui: nenhuma tela do V1 deve ter mais de
uma ação primária competindo por atenção (ex.: home tem "Novo desafio" como
CTA único, não "Novo desafio" + "Ver ranking" + "Convidar amigo" todos do
mesmo tamanho).

## 2. Justiça de resultado (não-negociável)

O jogador precisa poder confiar que seu resultado é real e não manipulável
— nem pelo próprio app (bug), nem por terceiros (engenharia reversa do
cliente). Por isso o backend é autoridade única sobre score, XP, progresso e
desbloqueio (`MENTAL_KICKOFF.md` §2, `MONETIZATION.md` §3). Isso não é só
uma decisão técnica — é parte da proposta de valor: conquista que não pode
ser confiada não vale a pena compartilhar.

## 3. Não-humilhação, não-manipulação

Já citado em `MONETIZATION.md` §5 no contexto de paywall, mas vale como
princípio geral de produto, não só de cobrança:
- Nenhuma peça de UI usa culpa, urgência agressiva ou personagem implorando
  para induzir ação (compra, retenção, convite).
- Erro do jogador (resposta errada) é tratado como parte natural do
  aprendizado, nunca como fracasso constrangedor — linguagem de feedback
  neutra ou encorajadora, nunca sarcástica ou de deboche, mesmo com humor
  leve de marca.
- Isso vale com peso redobrado dado o público misto incluindo crianças
  (ver `FAMILY_SAFETY.md`).

## 4. Gratuito-primeiro, paywall de progressão

O produto precisa ser bom e completo o suficiente no modo gratuito para
gerar hábito antes de qualquer cobrança aparecer. Paywall nunca é barreira
de entrada — é o que aparece quando o jogador já quer mais
(`MONETIZATION.md` §1). Isso também é princípio de design de tela: a
primeira sessão do jogador não pode ser interrompida por oferta de
assinatura.

## 5. Ressignificação como tese de marca, não detalhe

A escolha do nome MENTAL (`BRAND.md` §1) não é um detalhe de naming — é a
tese do produto. Toda comunicação (dentro e fora do app) reforça que "usar a
mente para conquistar" é o significado pretendido. Isso influencia tom de
voz: confiante, não debochado; competente, não arrogante.

## 6. Segurança de menor como arquitetura, não feature

Reforço do princípio final do kickoff (§11): a segurança de dados de menores
nunca é tratada como algo a adicionar depois. Qualquer decisão de produto
que crie tensão com isso (ex.: um mecanismo de crescimento que dependa de
compartilhar mais dado) perde para a segurança, sem exceção — precisa de
ADR explícito se algum dia parecer necessário reabrir essa prioridade.

## 7. Simplicidade de manutenção antes de sofisticação técnica

Quando duas abordagens resolvem o mesmo problema de produto, a mais simples
de manter vence — mesmo espírito já usado no kickoff para o card de
compartilhamento (§6: "Claude Code deve propor a abordagem mais simples e
de menor custo de manutenção"). Isso vale para todo o V1, não só ali.
