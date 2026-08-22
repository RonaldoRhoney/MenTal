# MENTAL — V2: KICKOFF

Status: aprovado por Rhoney (dono). Autoriza o início da V2 após fechamento
completo e validado da V1.1 (core loop, território, progresso, ranking,
streak, design system, i18n-ready, monetização desligada por decisão).

## 1. Contexto — por que V2 agora

Rhoney decidiu avançar direto para V2 em vez de pausar para publicação
imediata do V1.1. Registro de ressalva técnica (não bloqueante): o V1.1
ainda não foi validado com usuário real fora do próprio Rhoney — construir
profundidade adicional (V2) sobre uma base ainda não testada em campo é um
risco assumido conscientemente, não uma recomendação técnica. Seguimos com
o mesmo rigor de sempre: nada implementado sem documentação prévia, nada
avançado sem apresentação e aprovação.

## 2. Escopo da V2 (conforme `docs/02_ROADMAP/V2.md` original)

Do pacote de Discovery original, a V2 cobre:

- 🌎 Mundos completos (agrupamento de territórios em unidades maiores)
- 🏰 Conquista territorial (a mecânica já existe na V1.1 — V2 aprofunda
  com progressão entre territórios dentro de um "mundo")
- ⚔️ Disputa territorial (interação entre jogadores por território —
  **precisa de ADR antes de implementar**, ver Seção 4)
- 🧠 Dificuldade adaptativa (já existe versão simplificada desde o
  Vertical Slice 01 — `ADAPTIVE_DIFFICULTY.md` §6 — V2 evolui a fórmula
  com mais sinal de comportamento real, não reescreve do zero)
- 👁️ Desafios visuais (novo tipo de desafio, além dos 4 atuais)
- 📖 Textos (interpretação/inferência, novo tipo de desafio)
- 🧩 Enigmas/charadas (novo tipo de desafio)
- 🎓 Conteúdo educacional avançado (aprofundamento de curadoria, não muda
  a regra já fixada de curadoria manual, sem geração automática por IA)
- ⚔️ Batalha assíncrona (mencionada no `IMPLEMENTATION_PLAN.md` original
  como V1.2 — reavaliar se entra nesta V2 ou fica para depois, ver Seção 4)
- 👥 Amigos (necessário para "ranking de amigos", já registrado como gap
  aberto desde o Vertical Slice 01)
- 🏅 Conquistas/badges (sistema de conquista além do território)
- 📊 Estatísticas (visão mais detalhada de desempenho por categoria)
- 🔔 Notificações (streak, convite, marco de progresso)

## 3. Regras que continuam valendo, sem exceção

Mesmas regras estruturais de todo o projeto até aqui — a V2 não abre
exceção para nenhuma delas:

1. O backend continua sendo a única autoridade sobre XP, score, desbloqueio,
   assinatura, e agora também sobre qualquer resultado de disputa
   territorial ou batalha — o cliente nunca decide vencedor, nunca calcula
   pontuação de confronto.
2. `MONETIZATION_ENABLED` continua `false` por padrão — nenhuma feature de
   V2 pode assumir monetização ativa nem introduzir cobrança nova sem
   passar antes por decisão explícita de Rhoney.
3. `FAMILY_SAFETY.md` se aplica a toda feature nova, principalmente:
   - Disputa territorial e batalha assíncrona envolvem interação entre
     jogadores — qualquer troca de mensagem, nome exibido, ou visibilidade
     de outro jogador deve respeitar a mesma regra de anonimização para
     menor já aplicada ao ranking.
   - Notificações não podem usar linguagem de urgência agressiva
     (`PRODUCT_PRINCIPLES.md` — não-manipulação), mesmo sendo mecanismo de
     retenção.
4. `DESIGN_SYSTEM.md` se aplica a toda tela nova desde a criação — sem
   retrofit, mesma disciplina do V1.1.
5. Novos tipos de desafio (visual, texto, enigma) seguem a mesma exigência
   de curadoria de conteúdo real e suficiente antes de considerar a feature
   fechada — não repetir o padrão de "poucos itens" que já foi risco uma
   vez.
6. `ARCHITECTURE_UPDATE_I18N_READY.md` continua valendo — novo conteúdo
   (mesmo em português) deve nascer com `language_code` corretamente
   atribuído, sem regressão da estrutura i18n-ready já implementada.
7. Nenhuma funcionalidade fora do escopo desta lista deve ser implementada
   sem ADR (ver `MENTAL_KICKOFF.md`, regra 12 original) — se o Claude Code
   identificar necessidade de algo não previsto, documenta e pergunta, não
   assume.

## 4. Decisões que precisam de Rhoney antes de começar a implementação

Não iniciar código de nenhum destes três itens sem resposta:

1. **Disputa territorial** — qual é a mecânica real? (ex.: jogador com mais
   XP naquele território "toma" o território de outro jogador — como isso
   é comunicado sem soar hostil, dado o princípio de não-humilhação?)
   Precisa de um `TERRITORY_DISPUTE.md` dedicado antes de codar, com o
   mesmo rigor de revisão que os documentos anteriores tiveram.
2. **Batalha assíncrona** — entra nesta V2 ou fica para depois? Se entrar,
   qual é o formato (mesmo desafio para dois jogadores, comparando tempo/
   acerto)? Também precisa de documento dedicado antes de codar.
3. **Amigos** — como se adiciona um amigo no MENTAL? Por nickname/código de
   convite (reaproveitando a infraestrutura de deep link de convite já
   existente), ou outro mecanismo? Isso desbloqueia o ranking de amigos que
   ficou pendente desde o Vertical Slice 01.

## 5. Ordem sugerida de implementação (a validar com Claude — arquitetura)

Antes de escrever código, Claude Code deve propor uma sequência (qual das
12 features do Escopo, Seção 2, vem primeiro) com justificativa técnica —
não implementar todas em paralelo. Sugestão inicial a discutir: começar por
itens que não dependem de decisão pendente (Seção 4) — ex.: badges/
conquistas, estatísticas, notificações, novos tipos de desafio — e deixar
disputa territorial, batalha e amigos para depois que os 3 documentos
dedicados da Seção 4 estiverem aprovados.

## 6. Processo — mesma disciplina de sempre

```
Este kickoff → documentos dedicados (Seção 4) → Foundation da V2
→ implementação por feature, uma de cada vez → apresentação e validação
→ próxima feature
```

Não implementar a V2 inteira de uma vez. Cada feature listada na Seção 2
deve ser tratada como um Vertical Slice próprio: implementada, testada
contra infraestrutura real, apresentada, aprovada — só então a próxima.

## 6A. Ordem de implementação aprovada (2026-08-21)

Ajustada por Rhoney a partir da proposta inicial de Claude Code:

1. 🏅 Badges/Conquistas
2. 🧩 Enigmas/charadas
3. 📖 Textos (interpretação)
4. 👁️ Desafios visuais
5. 📊 Estatísticas — **movida pra depois dos 3 tipos de desafio novos**
   (item 4), para a tela nascer completa cobrindo todos os tipos de uma
   vez, em vez de precisar revisão a cada tipo novo adicionado.
6. 🧠 Dificuldade adaptativa evoluída
7. 🎓 Conteúdo educacional avançado — **critério de fechamento definido
   antecipadamente, não é mais tarefa contínua sem fim**: cada território
   ativo (os 4 originais + os novos criados pelos itens 2-4) precisa ter
   **no mínimo 15 desafios, com pelo menos 4 por nível de dificuldade
   (1-3)** antes deste item ser considerado fechado. Mesmo piso já
   atingido pelos 4 territórios originais no V1.1 (12-13 cada — ajustar
   para 15 quando este item for executado).
8. 🔔 Notificações (avaliar serviço contra Zero-Cost API antes de integrar)
   — **✅ fechado e em produção (2026-08-22)**. FCM confirmado ZERO_COST,
   SDK real integrado no client, push validado ponta a ponta em
   dispositivo real (Moto G22) e contra o Supabase/Render de produção.
9. 🚶 Contador de passos & movimento — spec completa em
   `STEP_COUNTER_MOVIMENTO.md` (aprovado 2026-08-21). Ciclo de 24h
   âncorado no horário do usuário, sensor nativo `TYPE_STEP_COUNTER`,
   conversão de passos em XP bônus escalonado por faixa (parâmetro no
   backend, nunca hardcoded no cliente), sem ranking de passos (evita
   comparação humilhante), copy final a validar com Rhoney antes de
   produção. — **✅ fechado e em produção (2026-08-22)**. Extensões
   aprovadas durante a implementação: meta diária pessoal opcional
   (bônus extra ao superar) e checkpoints intradiários (4 partes de 6h,
   bônus proporcional). Arquitetura de contagem: "catch-up ao reabrir o
   app" (decisão de Rhoney) em vez de serviço em segundo plano com
   notificação fixa.
10. 🌎 Mundos completos — **✅ fechado e em produção (2026-08-22)**. 2
    mundos aprovados: Mundo da Linguagem (palavras/textos/enigmas) e
    Mundo da Mente Lógica (números/lógica/visual/conhecimento). "Mundo
    completo" sempre derivado em tempo real, nunca armazenado.
11. 🏰 Conquista territorial aprofundada (depende do item 10) — **✅
    fechado e em produção (2026-08-22)**. Bônus fixo de 100 XP + 2
    badges por mundo, 100% reaproveitando a infra de badges do item 1 —
    nenhum badge extra para "todos os mundos" (já coberto pelo
    "Colecionador").

Grupo 2, só após os documentos dedicados da Seção 4:
12. 👥 Amigos — **✅ fechado e em produção (2026-08-22)**. Tabela
    `friendships` N:N (deliberadamente separada de invite_conversions,
    que é 1:1 pra métrica de crescimento), reaproveitando o MESMO
    invite_code/deep link já existente. Ranking de amigos fechado
    (gap deixado desde o Vertical Slice 01 — `scope=friends` agora
    filtra de verdade). Privacidade pra menor: feature disponível igual
    pra todo mundo, só anonimiza identidade (mesmo padrão do ranking
    geral), nunca bloqueada por child_safe_mode. Extensão pedida por
    Rhoney no mesmo dia: botão "Compartilhar" em toda celebração
    (território/mundo/nível/badge/meta de passos) e botão "Indicar" na
    tela de Amigos, via `share_plus` (ZERO_COST, Intent nativo do SO).
13. ⚔️ Disputa territorial — **✅ fechado e validado por API real
    (2026-08-22)**, aparelho físico temporariamente desconectado no
    momento do fechamento — confirmação visual em tela pendente na
    próxima sessão com o dispositivo. Spec completa em
    `TERRITORY_DISPUTE.md`. Critério de "detentor" confirmado: XP
    acumulado por território (`UserTerritoryProgress.xp_in_territory`,
    já existente — nunca um dado novo, sempre derivado, nunca
    armazenado, mesmo princípio de "mundo completo"). Duas decisões
    fechadas nesta implementação: (1) escopo é só entre amigos
    confirmados, NUNCA global — mesma razão do item 14, evita a
    dinâmica de "perder território pra um estranho"; (2) assumir um
    território não paga bônus de XP extra (seria "rico fica mais rico",
    já que o próprio XP é o critério de disputa). Detentor anterior
    recebe notificação com tom de convite, nunca de derrota ("Fulano
    assumiu X. Bora reconquistar? 💪"). Validado via API real com dois
    usuários reais e amigos confirmados: B ultrapassou o XP de A em
    Palavras, `territory_detentor_gained`/`dethroned_nickname` corretos
    dos dois lados, `GET /progress` simétrico (os dois veem o mesmo
    detentor). 123/123 testes de backend e 29/29 de cliente passando.
14. ⚔️ Batalha assíncrona — **✅ fechado e em produção (2026-08-22)**.
    Spec completa em `ASYNC_BATTLE.md`. Tabela `battles` nova; cada lado
    responde um desafio DIFERENTE do mesmo território/nível (nunca o
    mesmo, evita cola). A resposta em si reaproveita 100% o já existente
    POST /challenges/{id}/answer (nenhum cálculo de XP duplicado) — um
    hook aditivo (`services.maybe_resolve_battle_side`) correlaciona os
    dois lados e decide o vencedor quando ambos já responderam. Tempo de
    resposta medido a partir do momento em que CADA lado abre o próprio
    desafio (`*_served_at`), não da criação da batalha — evita penalizar
    sempre o desafiado só por responder depois (fluxo é assíncrono de
    propósito). Limite de 3 desafios enviados/dia por usuário; bônus de
    30 XP pro vencedor. Decisão de Rhoney (2026-08-22): nickname aparece
    normalmente nas notificações de batalha mesmo em child_safe_mode
    (os dois já são amigos confirmados via item 12, diferente do ranking
    geral). Validado no aparelho real com dois usuários reais (fluxo
    completo: criar batalha → responder na hora → oponente responde
    depois → resultado exibido pros dois lados).
15. ⚡ Palavras Relâmpago — **✅ fechado e em produção (2026-08-22)**.
    Spec completa em `PALAVRAS_RELAMPAGO.md`: múltipla escolha com tempo
    regressivo escalonado por nível, disponível só em médio/difícil,
    convive com o formato digitado atual, bônus de velocidade calculado
    100% no servidor, tratamento suave pra timeout (nunca conta como
    erro comum). Implementado fora da ordem original (14→13→15) a
    pedido de Rhoney, que autorizou adiantá-lo enquanto decidia o
    formato da Batalha assíncrona.

Extensão registrada no mesmo dia (2026-08-22), fora da lista original:
recompensa de XP por compartilhar uma conquista (POST
/social/share-reward) — XP fixo, teto de 1x por dia civil, já que o app
não confirma se o compartilhamento via OS share sheet foi de fato
concluído.

Grupo 2 fechado por completo em 2026-08-22 (itens 12, 13, 14, 15 todos
✅). Falta só a confirmação visual em tela do item 13 quando o
aparelho físico reconectar (validação por API real já feita).

## 7. Papel de cada parte

- **Rhoney**: decide as pendências da Seção 4 antes de qualquer código
  relacionado a elas; aprova a ordem de implementação proposta.
- **Claude (arquitetura)**: revisa os documentos dedicados de disputa
  territorial e batalha antes de virarem instrução; garante que nenhuma
  regra da Seção 3 é violada por feature nova.
- **Claude Code**: propõe ordem de implementação, implementa uma feature
  por vez, apresenta e aguarda aprovação antes de avançar para a próxima —
  não avança sozinho pela lista da Seção 2.

## 8. Pendências de manutenção registradas (não bloqueiam o V2)

- **`datetime.utcnow()` depreciado** — usado em todo o backend
  (models.py, services.py, routers). Python vai remover essa API numa
  versão futura (substituto: `datetime.now(datetime.UTC)`). Não quebra
  nada hoje, mas precisa ser resolvido **antes da submissão à Play
  Store** — registrar como item de manutenção pré-lançamento, não
  durante a V2.
