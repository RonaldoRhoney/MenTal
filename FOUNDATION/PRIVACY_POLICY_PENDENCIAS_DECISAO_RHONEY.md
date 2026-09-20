# Política de Privacidade — pendências que dependem de decisão de Rhoney

Origem: auditoria completa de 20/09/2026 (agente de arquitetura/privacidade). O que era **fato verificável** já foi aplicado em
`PRIVACY_POLICY.md` e `store_assets/mental-privacidade.html` (exclusão pelo app, MentalCoins como sink, dados de uso/token FCM/passos,
Render/Facebook/GitHub Pages, Estado obrigatório, respostas no mural). Abaixo ficou só o que **não pode ser escrito sem sua decisão** —
nada disto foi publicado. Recomenda-se revisão jurídica (a própria `MENTAL-POL-003` já diz isso).

## 1. Ranking mostra passos e saldo de MentalCoins (achado A3)
Hoje `GET /ranking` expõe `total_steps` e `mentalcoins_balance` dos 50 primeiros a qualquer usuário autenticado, e o Hall da Fama expõe
nome real + métrica. A política diz que passos são "usados exclusivamente para a gamificação" e não lista saldo/passos como públicos.
**Decida:** (a) manter e declarar, ou (b) remover as duas colunas do Ranking.
Se (a), texto sugerido para §2.5: "**Ranking e Hall da Fama** — no Ranking (global ou entre amigos), qualquer usuário autenticado vê, para os 50 primeiros e para
você mesmo: nome real, foto pública, nível, XP, sequência de dias, mundos completos, número de conquistas, **saldo de MentalCoins e total de passos**.
O Hall da Fama semanal mostra nome real e a marca conquistada (ex.: passos da semana) dos vencedores." E trocar em §2.3 "usada exclusivamente para a
funcionalidade de gamificação por movimento" por "usada para a gamificação por movimento e exibida no Ranking e no Hall da Fama (ver 2.5)".

## 2. Seção nova "Bases legais e responsáveis" (LGPD)
Não existe na política publicada. Rascunho (preencher os campos entre colchetes):
> **Controlador:** [Ronaldo Martins (RhoneyInc), Belém/PA — confirmar razão social]. **Encarregado pelo tratamento de dados:** rhoneyinc@gmail.com. Responderemos às suas solicitações em até [15] dias.
> **Bases legais (LGPD, art. 7º):** execução de contrato (conta, progresso, ranking, funcionalidades sociais); consentimento (foto de perfil, sensor de passos, notificações push, nome real público — revogável em Ajustes ou por e-mail); legítimo interesse (segurança da conta, prevenção a fraude/abuso, moderação de denúncias); obrigação legal, quando aplicável (Marco Civil da Internet).
> **Transferência internacional:** os provedores (Supabase, Render, Google/Firebase) podem processar dados fora do Brasil ([confirmar região do Supabase e do Render]), com as salvaguardas do art. 33 da LGPD.

## 3. §8 Direitos do usuário — lista completa
Trocar a lista atual por: confirmação e acesso; correção; anonimização, bloqueio ou eliminação de dados desnecessários; portabilidade; eliminação dos dados tratados com consentimento; informação sobre com quem compartilhamos; informação sobre a possibilidade de não consentir e suas consequências; revogação do consentimento; oposição; revisão de decisões automatizadas (dificuldade adaptativa e ranking); reclamação perante a ANPD (gov.br/anpd).

## 4. Retenção
- Prazo de retenção de **backups** do provedor após a exclusão: [confirmar no Supabase].
- Política para **contas inativas**: [definir ou remover a menção].
- O prazo "até 30 dias" da exclusão por e-mail foi mantido só para o canal e-mail (a LGPD não fixa esse prazo); confirme se quer prometê-lo.
- A retenção de 30 dias das notificações só é cumprida se `NOTIFICATION_SCHEDULER_ENABLED=true` no Render — **confirme a variável**.

## 5. Termos de Uso
Não há Termos publicados (`TERMS_VERSION = "1.0"` só registra o aceite da política). O rascunho está em `MENTAL-POL-003` §2. Decida se publica junto (e sobe
`TERMS_VERSION` para `1.1`, com novo aceite).

## 6. Play Console
Registrar em `store_assets/DATA_SAFETY.md` o que foi declarado (passos/fitness, foto, nome, ID de dispositivo FCM, conteúdo gerado pelo usuário, exclusão pelo app e pela web) e decidir a categoria de "localização" para cidade/estado digitados. `LISTING_TEXT.md` ainda diz "Grátis pra começar, com desafios extras via assinatura" — contradiz "100% gratuito, sem anúncios" (MONETIZATION_ENABLED=false).
