# MENTAL — ADMIN_PANEL_E_CREDITO_INSTITUCIONAL.md

Status: aprovado por Rhoney (dono). Parte oficial da Foundation, adicionado
durante a V2. Cobre dois pedidos relacionados a visibilidade institucional
da RhoneyInc: painel administrativo de métricas e crédito de autoria.

## 1. Painel administrativo de métricas

### 1.1 Decisão

Faz sentido existir, mas **não entra na sequência atual da V2**. É uma
ferramenta para Rhoney (dono do produto), não uma feature que melhora a
experiência do jogador — não compete pela mesma prioridade dos itens já
em ordem aprovada (`V2_KICKOFF.md` §5).

### 1.2 Por que a prioridade é baixa agora

- O dado que alimentaria o painel já está sendo coletado desde o Vertical
  Slice 01 (`attempts`, `profiles`, `subscriptions`,
  `daily_challenge_usage`) — não é captura nova, é camada de leitura sobre
  dado existente. Tecnicamente barato de implementar quando chegar a hora.
- O app ainda não tem usuário real além do próprio Rhoney testando — um
  painel de métricas hoje mostraria apenas dados de teste, sem valor real
  de decisão de produto. O valor genuíno aparece após o lançamento, com
  uso real.
- Não é dependência de nenhum item da V2 em andamento, nem nenhum item da
  V2 depende dele — pode ser tratado como trilha paralela, semelhante ao
  tratamento dado a "Google Play Readiness".

### 1.3 Quando revisitar

Recomenda-se implementar como etapa própria depois do fechamento da V2
(ou em paralelo, apenas se houver capacidade ociosa real — nunca
deslocando prioridade dos itens já em sequência aprovada).

### 1.4 Escopo de referência (para quando for implementado)

Não é especificação fechada — apenas direção inicial a refinar quando a
etapa for priorizada:
- Acesso restrito por `role = admin` (já existe no schema desde a
  Foundation) — nunca acessível a usuário comum, mesmo por engenharia
  reversa de rota.
- Métricas de leitura, nunca de escrita/edição direta de dado de jogador
  a partir do painel nesta fase inicial (edição manual de XP/progresso de
  usuário é superfície de risco — se necessário no futuro, precisa de ADR
  próprio antes de implementar).
- Sugestão de métricas iniciais: usuários ativos (diário/semanal),
  desafios respondidos por tipo, taxa de acerto por território, retenção
  D1/D7, distribuição de nível dos jogadores.
- Interface simples (web administrativa separada do app do jogador, ou
  rota protegida dentro do mesmo backend) — Claude Code deve propor a
  abordagem mais simples e barata quando a etapa for priorizada.

## 2. Crédito institucional — não em rodapé fixo do app

### 2.1 Decisão

**Não** adicionar "Criado por: RhoneyInc" (ou variação) como rodapé
permanente nas telas de jogo do MENTAL.

### 2.2 Por que — coerência com decisões já formalizadas

- `BRAND.md` já define o MENTAL como marca-filha com identidade própria,
  deliberadamente não estilizada como os produtos B2B da RhoneyInc
  (MenuFlex, VendeFlex). Um rodapé institucional permanente durante o
  core loop de jogo reintroduz a holding em primeiro plano, na direção
  oposta dessa decisão.
- `DESIGN_SYSTEM.md` §3 (Clareza Imediata) limita cada tela a no máximo 2
  níveis de hierarquia de informação visível — um rodapé fixo que não
  serve ao jogador em nenhum momento do core loop é informação
  competindo por atenção sem propósito funcional.

### 2.3 Onde o crédito institucional aparece, então

- **Tela de "Sobre"**, dentro de Configurações/Perfil — discreto, junto de
  versão do app, link de política de privacidade, e outras informações
  institucionais. Padrão comum de mercado, não interfere na experiência
  de jogo.
- **Listagem da Google Play Store** — o Play Console já exige nome de
  desenvolvedor visível (RhoneyInc/`rhoneyinc@gmail.com`) estruturalmente,
  fora do controle de design do app em si — o crédito institucional já
  fica visível ali sem necessidade de duplicar dentro do app.

### 2.4 Texto sugerido para a tela de Sobre

Não é texto final — Claude Code deve propor variação para aprovação de
Rhoney, mesma prática já usada para copy de notificações
(`NOTIFICATIONS.md` §5): algo na linha de "Um produto RhoneyInc" ou
"Desenvolvido por RhoneyInc", discreto, não como elemento de destaque
visual da tela.

## 3. Papel de cada parte

- **Rhoney**: decide quando priorizar o painel admin (Seção 1.3); aprova
  o texto final do crédito institucional na tela de Sobre.
- **Claude (arquitetura)**: garante que o painel admin, quando priorizado,
  segue o princípio de acesso restrito (Seção 1.4) e não introduz
  superfície de risco de edição direta sem ADR próprio; garante que o
  crédito institucional não vaza para nenhuma tela de jogo além de Sobre.
- **Claude Code**: não implementa nenhum dos dois itens deste documento na
  sequência atual da V2 — apenas quando explicitamente priorizado por
  Rhoney em conversa futura.
