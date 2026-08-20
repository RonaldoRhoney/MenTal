# MENTAL — MONETIZATION.md

Status: aprovado por Rhoney (dono). Parte oficial da Foundation.
Modelo: **Freemium com paywall de progressão** — não é "app pago desde o início".

## 1. Princípio

O MENTAL nasce gratuito e joga bem. Ninguém paga por algo que nunca
experimentou. A conversão em receita acontece no ponto em que o jogador já
está engajado e quer **continuar conquistando** — nunca como barreira de
entrada.

O paywall não deve ser percebido como "pague para estudar" ou "pague para
usar o app". Deve ser percebido como parte do jogo: **conquiste o próximo
território**. A linguagem de cobrança usa a mesma metáfora de território e
conquista já definida no `PRODUCT_PRINCIPLES.md` — dinheiro entra dentro da
fantasia do jogo, não interrompe ela.

## 2. Estrutura Free vs. Pago

### Free (sempre disponível, sem limite de tempo de uso do app em si)
- Territórios iniciais completos e jogáveis sem restrição (quantidade exata a
  definir na Foundation — sugestão inicial: os 2 primeiros territórios do V1:
  Palavras e Números).
- Limite de desafios por dia (sugestão inicial: 8-10/dia). O limite reseta
  diariamente e reforça o hábito (streak) sem custar dinheiro.
- XP, nível e progresso sempre visíveis e acumulando normalmente — inclusive
  em territórios travados, para que o jogador veja o que está perdendo.
- Ranking e ranking de amigos sempre visíveis.

### Assinatura mensal (valor inicial de referência: R$ 9,90/mês — a validar
com Rhoney antes do lançamento, não é definitivo)
- Desafios ilimitados por dia.
- Todos os territórios liberados, incluindo os avançados (Lógica,
  Conhecimento, e os que entrarem em V2).
- Dicas extras (quantidade maior de dicas progressivas por desafio).
- Selo visual de assinante no perfil (cosmético, não funcional — não criar
  vantagem competitiva injusta no ranking, apenas identidade visual).

### Fora de escopo do V1 (mas a arquitetura deve prever)
- Compra avulsa de território específico (em vez de assinatura completa).
- Moeda virtual (explicitamente fora de escopo até V2, conforme já definido
  no `MENTAL_KICKOFF.md`).

## 3. Regra técnica inegociável

**O cliente (Flutter/Android) nunca decide o que está liberado.** Da mesma
forma que o cliente nunca calcula Score ou XP, ele também nunca decide se um
território está desbloqueado ou se o limite diário de desafios foi atingido.
O backend (FastAPI) é a única autoridade sobre:
- Status de assinatura ativa do usuário.
- Quais territórios estão liberados para aquele usuário.
- Contagem de desafios consumidos no dia.

Isso evita que alguém "destrave" o app via engenharia reversa do cliente.

## 4. Meio de pagamento

- **Google Play Billing** é o único meio de cobrança dentro do app. Qualquer
  link externo de pagamento (Pix direto, Stripe fora do fluxo do Play) viola
  a política da Google Play Store e pode levar à remoção do app.
- O backend precisa validar o recibo de compra do Google Play Billing
  (server-side receipt validation) antes de liberar qualquer conteúdo — nunca
  confiar apenas na confirmação local do cliente.

## 5. Compliance obrigatória — público misto (criança a idoso)

Isso conecta diretamente com o `FAMILY_SAFETY.md` já aprovado:

- **Parental gate obrigatório** antes de qualquer fluxo de compra ser
  iniciado. Um desafio simples (ex: operação matemática) que uma criança
  pequena dificilmente resolve sozinha, exigido antes de abrir a tela de
  assinatura ou confirmar pagamento. Isso é exigência da política do Google
  Play para apps de público misto/infantil com compras, não uma escolha
  opcional.
- Nenhuma peça de UI pode pressionar ou manipular emocionalmente uma criança
  a comprar (sem personagem implorando, sem "só mais essa vez", sem timer de
  urgência agressivo). Isso viola tanto a política do Google quanto o
  princípio de não-humilhação/não-manipulação já definido no produto.
- Preço e cobrança devem ser claros, sem "compra acidental" — confirmação
  explícita sempre antes de cobrar.

## 6. Impacto no restante da Foundation (a formalizar)

- `DATA_MODEL.md`: adicionar tabela/campo de status de assinatura por
  usuário (ativa, expirada, cancelada), e mapeamento de qual território
  exige assinatura.
- `API_CONTRACT.md`: adicionar endpoints de:
  - Consulta de status de assinatura do usuário.
  - Validação de recibo de compra (Google Play Billing server-side).
  - Contagem/consumo do limite diário de desafios gratuitos.
- `SECURITY.md`: cobrir validação server-side de recibo e proteção contra
  replay de recibo de compra.

## 7. Papel de cada parte

- **Rhoney**: define e aprova o valor final da assinatura e a régua exata de
  quais territórios ficam free vs. pagos antes do lançamento.
- **Claude (arquitetura)**: garante que nenhuma decisão de monetização vaze
  para o cliente, e que o parental gate é implementado como requisito do V1
  assim que a tela de assinatura existir — não como ajuste de última hora.
- **Claude Code**: implementa a lógica de limite/desbloqueio inteiramente no
  backend. O paywall na V1 pode ser apenas a UI + o bloqueio funcional; a
  integração real com Google Play Billing pode entrar em uma etapa dedicada
  posterior, mas o modelo de dados já nasce pronto para isso.
