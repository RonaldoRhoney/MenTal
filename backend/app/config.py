import os

DATABASE_URL = os.environ.get("MENTAL_DATABASE_URL", "sqlite:///./mental_dev.db")

# ARCHITECTURE_UPDATE_I18N_READY.md: 100% do conteúdo é pt-BR no
# lançamento, mas o parâmetro de idioma já existe no endpoint de desafio
# (default aqui, nunca hardcoded no router) — popular um 2º idioma no
# futuro não deve exigir mudança de código, só novos registros de conteúdo.
DEFAULT_LANGUAGE_CODE = "pt-BR"

# SUPABASE_URL (ex.: "https://xxxx.supabase.co") ativa a validação real de
# token via JWKS (chave pública do projeto, buscada em
# {SUPABASE_URL}/auth/v1/.well-known/jwks.json — não é segredo, pode ficar
# em variável de ambiente comum). Projeto MENTAL usa assinatura assimétrica
# ES256 (ECC P-256) como chave atual, não o modelo legado de segredo
# compartilhado HS256 — confirmado no painel do projeto em 2026-08-19
# (Settings → API → JWT Keys mostra "Legacy HS256" como PREVIOUS KEY, não
# CURRENT KEY). SUPABASE_JWT_SECRET fica como fallback só para projeto que
# ainda esteja no modelo legado.
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_JWT_SECRET = os.environ.get("SUPABASE_JWT_SECRET")

# Achado de auditoria de segurança (28/08/2026): sem isso, não havia
# como o backend gerar URL assinada pro bucket de fotos (que era público
# só por essa limitação) nem excluir de verdade a conta de um usuário no
# Supabase Auth (LGPD/DIR-001 §item 5) — ambos exigem uma credencial com
# privilégio de admin, nunca a chave publishable usada pelo client.
# NUNCA logar/expor este valor; usado só em supabase_admin.py.
SUPABASE_SERVICE_ROLE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

# Achado de auditoria de segurança (28/08/2026): sem SUPABASE_URL nem
# SUPABASE_JWT_SECRET, auth.py cai no modo DEV_INSECURE (token = user_id em
# texto puro, sem verificar assinatura nenhuma) — se qualquer uma dessas
# duas env vars sumir por engano em produção (redeploy, typo, restore de
# config), o backend continuava rodando normalmente e aceitando QUALQUER
# UUID como identidade de qualquer usuário, silenciosamente. Essa flag
# precisa ser setada explicitamente pra permitir o modo inseguro — sem ela,
# auth.py recusa subir (fail loud) em vez de fail-open.
ALLOW_DEV_INSECURE_AUTH = os.environ.get("MENTAL_ALLOW_DEV_INSECURE_AUTH", "").lower() == "true"

# MENTAL-DIR-001/POL-002 (24/08/2026): MENTAL passa a ser exclusivo pra
# maiores de 18 anos — sem mais age gate multi-público nem
# child_safe_mode. Versão dos Termos aceitos no momento da confirmação
# de maioridade (POST /age-gate), registrada por usuário — só muda
# quando o texto legal dos Termos mudar de verdade, não a cada deploy.
TERMS_VERSION = "1.0"

# MONETIZATION_UPDATE_FREE_LAUNCH.md: MENTAL lança 100% gratuito. Quando
# false (default), toda checagem de "território exige assinatura" é
# ignorada em services.is_territory_unlocked — ponto único de verificação,
# nunca espalhado por múltiplos arquivos, para que ativar cobrança no
# futuro seja só mudar esta env var. Nenhuma tabela/endpoint de assinatura
# é removida — a estrutura inteira continua existindo, só não é aplicada.
MONETIZATION_ENABLED = os.environ.get("MONETIZATION_ENABLED", "false").lower() == "true"

# Limite diário: 8 (original) → 20 (decisão de Rhoney, 2026-08-19) → 24
# (MONETIZATION_UPDATE_FREE_LAUNCH.md §3, 2026-08-20). Com o lançamento
# 100% gratuito, a única função deste limite deixou de ser "incentivo a
# assinar" e passou a ser puramente hábito/retenção via streak — por isso
# o valor final é mais alto que os dois anteriores, calibrados quando o
# limite ainda carregava pressão de conversão. Continua ativo mesmo com
# MONETIZATION_ENABLED=false (não tem relação com dinheiro, é ritmo de
# uso). Centralizado aqui — nunca hardcoded em mais de um lugar.
DAILY_FREE_CHALLENGE_LIMIT = 24

# Pedido de Rhoney (2026-08-24): sem limite diário enquanto durar o
# teste fechado/informal — testadores não devem esbarrar num teto
# artificial no meio da avaliação. Mesmo padrão de MONETIZATION_ENABLED
# (env var, default "true"/ligado): em produção, setar
# DAILY_LIMIT_ENABLED=false no Render desliga a checagem sem afetar
# testes locais (que não têm essa env var, continuam com o limite real
# de 24 pra validar o comportamento de bloqueio). Religar (ou remover a
# env var) quando o teste fechado terminar e a monetização for ativada.
DAILY_LIMIT_ENABLED = os.environ.get("DAILY_LIMIT_ENABLED", "true").lower() != "false"
HINT_PENALTY_FACTOR = 0.25
STREAK_FREEZE_PER_WEEK = 1

# Decisões de implementação do Vertical Slice 01, sem dado real ainda
# (TERRITORIES.md §3 e GAMIFICATION.md §4 deixavam esses valores em
# aberto) — centralizadas aqui de propósito, a pedido de Rhoney, para
# serem achadas e ajustadas num único lugar quando houver telemetria real.
CONQUEST_XP_THRESHOLD = 200

# V2 item 11 — Conquista territorial aprofundada (V2_KICKOFF.md §6A,
# aprovado por Rhoney em 2026-08-22). Bônus fixo pago uma vez, na
# resposta exata que fecha o último território de um mundo (mesmo
# padrão de world_just_completed) — reconhece que fechar um mundo
# inteiro é um feito maior que fechar um território isolado.
WORLD_COMPLETION_BONUS_XP = 100
XP_PER_LEVEL = 100
XP_BASE_BY_DIFFICULTY = {1: 10, 2: 20, 3: 30, 4: 40, 5: 50}
XP_BASE_DEFAULT = 20

# Dificuldade adaptativa (ADAPTIVE_DIFFICULTY.md §6, fórmula em aberto na
# Foundation): janela de tentativas recentes observada e limiares de
# domínio médio que sobem/descem 1 nível de dificuldade. Estes 5 números
# não mudaram no item 6 da V2 (evolução da fórmula, V2_KICKOFF.md §2) —
# só o que "domínio" significa evoluiu, em services.pick_difficulty_for:
# de taxa de acerto binária para acerto ponderado por uso de dica
# (scoring.hint_penalty_factor). Sinal já previsto desde o Discovery
# original (ADAPTIVE_DIFFICULTY.md §2 já citava "uso de dica" como sinal
# de entrada), só não estava implementado na versão simplificada do V1.
ADAPTIVE_DIFFICULTY_WINDOW = 5
ADAPTIVE_DIFFICULTY_MIN_SAMPLE = 3
ADAPTIVE_DIFFICULTY_UP_THRESHOLD = 0.8
ADAPTIVE_DIFFICULTY_DOWN_THRESHOLD = 0.4
ADAPTIVE_DIFFICULTY_MIN_LEVEL = 1
ADAPTIVE_DIFFICULTY_MAX_LEVEL = 5

# Parental gate (MONETIZATION.md §5): correção de segurança pedida por
# Rhoney na revisão do Vertical Slice 01 — parental_gate_passed_at NÃO
# pode valer para sempre depois de passado uma vez (cenário de risco real:
# criança usa o celular do adulto meses depois, já logado, e o backend
# aceitaria a compra achando que o gate "já foi validado"). A janela é
# curta o suficiente para completar o fluxo de checkout em andamento,
# curta demais para servir de autorização permanente.
PARENTAL_GATE_VALIDITY_MINUTES = 10

# V2 item 8 — Notificações (NOTIFICATIONS.md). Provedor: Firebase Cloud
# Messaging — verificado contra a régua Zero-Cost antes de integrar
# (skill zero-cost-api, 2026-08-21): FCM é ZERO_COST com certeza, não só
# "gratuito com limite" — funciona inteiro no plano Spark (sem cartão
# cadastrado), sem taxa por mensagem, sem limite de volume, em qualquer
# plano (Spark ou Blaze). Credencial fica só em variável de ambiente,
# nunca commitada — conteúdo é o JSON completo da conta de serviço do
# Firebase (Project Settings → Service Accounts → Generate new private
# key), não um caminho de arquivo (mais simples de configurar no Render).
FIREBASE_SERVICE_ACCOUNT_JSON = os.environ.get("FIREBASE_SERVICE_ACCOUNT_JSON")

# Liga o agendador em background (verifica inatividade 24h/48h e
# ultrapassagem de ranking a cada NOTIFICATION_CHECK_INTERVAL_MINUTES).
# Default false — nunca roda durante os testes (pytest) nem durante
# desenvolvimento local casual, só quando explicitamente ligado (mesmo
# padrão de MONETIZATION_ENABLED: ponto único de verificação, nunca
# espalhado). O processo do backend já fica acordado 24/7 via UptimeRobot
# (ARCHITECTURE.md) — nenhum serviço novo de agendamento externo precisa
# existir só para isso.
NOTIFICATION_SCHEDULER_ENABLED = os.environ.get("NOTIFICATION_SCHEDULER_ENABLED", "false").lower() == "true"
NOTIFICATION_CHECK_INTERVAL_MINUTES = 30

# V2 item 9 — Contador de passos (STEP_COUNTER_MOVIMENTO.md §4). Bônus de
# XP escalonado por faixa de passos no ciclo de 24h — "quanto mais andou,
# proporcionalmente mais ganha, sem teto rígido". MOVEMENT_XP_BASE é
# parâmetro único de configuração (nunca hardcoded no cliente, mesma
# autoridade central de XP_BASE_BY_DIFFICULTY); os múltiplos por faixa são
# fixos por definição do documento, não precisam de ajuste futuro como o
# valor base precisa. Faixas em ordem decrescente de piso — a primeira
# cujo piso for atingido decide o multiplicador (15000+ não tem teto:
# 999999 passos ainda cai na mesma faixa x4).
MOVEMENT_XP_BASE = 20
MOVEMENT_STEP_TIERS = [
    (15000, 4),
    (10000, 3),
    (5000, 2),
    (2000, 1),
    (0, 0),
]
# Ciclo de 24h (§2). Uma coleta final feita durante o ciclo seguinte ainda
# vale para o ciclo que acabou de fechar — janela de graça de mais 24h
# para reagir ao relatório antes dos passos serem perdidos de vez (§2:
# "antes do próximo ciclo avançar" — interpretado como "antes do ciclo
# seguinte TAMBÉM fechar", não no instante exato da virada, senão o
# relatório de fim de ciclo nunca teria tempo real de ser útil).
MOVEMENT_CYCLE_HOURS = 24
MOVEMENT_COLLECTION_GRACE_HOURS = 24
# Sanidade contra bug de cliente (não é anti-cheat rígido — o próprio
# desenho de faixas sem teto já limita o ganho de qualquer valor
# absurdo à mesma faixa máxima): nenhuma coleta única aceita mais que
# isso em um só request. ~28 passos/segundo sustentado por 24h — não é
# um limite realista de caminhada, só um teto contra valor claramente
# corrompido (ex.: overflow, campo em branco). Passos negativos entram
# a partir do schema Pydantic (Field(ge=0)), não daqui.
MOVEMENT_MAX_STEPS_PER_COLLECTION = 2_500_000
# Achado real de produção (31/08/2026, MENTAL_MOVIMENTO_REFORMULACAO.md
# §2 e auditoria de segurança do mesmo dia): sensor de passos do
# aparelho de um usuário começou a reportar leituras corrompidas, e a
# auto-coleta (a cada ~20s) foi somando cada leitura sem nenhum teto
# ACUMULADO por ciclo — o teto acima é só por chamada, então uma
# sequência de deltas "plausíveis" isoladamente inflou o ciclo para
# ~165.000 passos em minutos, convertendo isso em MentalCoins reais
# (mentalcoins.py, marco de 1000 passos = 5 moedas, sem teto próprio).
# Este teto é um CLAMP (trava o valor aceito no que falta pro teto),
# nunca uma rejeição — preserva o teste já existente de que um único
# valor absurdo numa chamada (ex.: 999.999) ainda deve render XP da
# faixa máxima normalmente (bem abaixo de MOVEMENT_STEP_TIERS[0]=15000);
# só a soma ACUMULADA do ciclo passa a ter limite.
#
# Reduzido de 150.000 pra 60.000 em 03/09/2026 (achado real, teste no
# aparelho de Rhoney): mesmo com o clamp acima já existindo, um ciclo
# corrompido conseguiu chegar EXATAMENTE nos 150.000 (não em ~165.000
# como o incidente original) — ou seja, 150k ainda era alto o
# suficiente pra um sensor com defeito/loop de auto-coleta bater o
# teto sem soar como corrupção óbvia, e poluiu a média/total exibidos
# no gráfico "Últimos 7 dias" da Home (61.624 passos/dia de média — o
# gráfico "elegante e rico em detalhes" pedido não faz sentido em cima
# de dado corrompido). 60.000 continua muito acima de qualquer
# caminhada humana real (a maratona mais longa do mundo tem ~40k
# passos) e continua acima de MOVEMENT_STEP_TIERS[0]=15000, então o
# comportamento de "faixa máxima de XP alcançável" continua intacto —
# só reduz o tamanho do estrago quando o sensor falha de novo.
MOVEMENT_MAX_STEPS_PER_CYCLE = 60_000

# V2 item 15 — Palavras Relâmpago (PALAVRAS_RELAMPAGO.md, aprovado
# 2026-08-22). Múltipla escolha com tempo regressivo. Generalizado em
# 2026-08-22 (CONHECIMENTO_EXPANSAO_GERAL.md §2) pra deixar de ser
# exclusivo de Palavras: mesmo mecanismo agora também usado pelo
# conteúdo geral de Conhecimento (nesse caso, formato único e
# obrigatório, nunca opcional como em Palavras). Nome genérico de
# propósito — não é mais um recurso de um território só.
#
# RELAMPAGO_TEMPO_20S_UNIVERSAL.md (aprovado, 02/09/2026): janela ÚNICA
# de 20s pra TODO desafio Relâmpago, substituindo os valores variados
# por nível (antes: mais difícil = menos tempo, 12/10/7s) — o volume de
# conteúdo curado nas fases V3.1-V3.5 gerou perguntas mais longas do
# que o tempo original comportava pra leitura, mesmo sabendo a
# resposta. Continua um dict por nível (não um int solto) só pra não
# quebrar a assinatura de quem já usa `.get(difficulty_level)` — mas os
# 3 valores agora são idênticos de propósito. A fórmula de bônus de
# velocidade (compute_speed_bonus_xp) é baseada em FRAÇÃO do tempo, não
# em segundos absolutos — recalibra sozinha pra escala nova, nenhuma
# mudança de fórmula foi necessária.
TIMED_MULTIPLE_CHOICE_TIME_LIMIT_SECONDS = {1: 20, 2: 20, 3: 20}
# Só se aplica ao modo OPCIONAL de Palavras (mode=relampago) — nível
# fácil nunca entra nesse modo lá, decisão fechada na spec original.
# Conhecimento não tem esse piso: todo nível já usa o formato com tempo,
# incluindo fácil, porque ali o formato é obrigatório, não opcional.
PALAVRAS_RELAMPAGO_MIN_DIFFICULTY_LEVEL = 2

# V3.2 (V3/V3.2_TECNOLOGIA.md §3.4) — Pausa para Aprender: "quantidade
# pequena e FIXA de XP por leitura concluída... não deve ser um atalho
# de XP fácil". Fixo e único (não varia por dificuldade/território) —
# claramente menor que o XP_BASE_BY_DIFFICULTY de um Relâmpago
# respondido certo, propositalmente.
LEARNING_PAUSE_XP_REWARD = 5
# Achado de auditoria de segurança M2 (05/09/2026): sem piso de tempo,
# /complete concedia XP sem nenhuma prova de leitura real — bem abaixo
# do tempo de leitura de qualquer texto curado, só bloqueia conclusão
# instantânea de script.
LEARNING_PAUSE_MIN_READ_SECONDS = 3

# Territórios onde o formato com tempo é OBRIGATÓRIO e único (nunca
# depende de mode=relampago) — Conhecimento (CONHECIMENTO_EXPANSAO_
# GERAL.md) e agora Cores (V3.0.1_DESAFIO_CORES.md, 29/08/2026): um
# desafio de atenção/velocidade de leitura só faz sentido cronometrado,
# em qualquer nível, incluindo fácil.
ALWAYS_TIMED_TERRITORIES = {"conhecimento", "cores", "curiosidade_relampago"}
# V3.5 (V3.5_CURIOSIDADE_RELAMPAGO.md, aprovado) — o próprio doc descreve
# a charada "no formato Relâmpago (timer curto, ~10 segundos)" como a
# natureza do desafio, não um modo opcional (mesmo raciocínio de
# Conhecimento/Cores acima).

# Bônus de velocidade (PALAVRAS_RELAMPAGO.md §4): responder nos primeiros
# 30% do tempo disponível vale o bônus máximo (até +100% do xp_base do
# desafio); responder depois de 70% do tempo consumido não perde o
# acerto, só não ganha bônus. Entre os dois, o bônus decai linearmente —
# nunca penaliza quem responde mais devagar dentro do tempo, só premia
# quem for mais rápido (mesma filosofia do bônus de passos do item 9).
# Generalizado junto com TIMED_MULTIPLE_CHOICE_TIME_LIMIT_SECONDS acima.
TIMED_MULTIPLE_CHOICE_SPEED_BONUS_MAX_MULTIPLIER = 1.0
TIMED_MULTIPLE_CHOICE_SPEED_BONUS_FAST_FRACTION = 0.3
TIMED_MULTIPLE_CHOICE_SPEED_BONUS_SLOW_FRACTION = 0.7

# Jogos de Palavras — Fase 1: Caça-palavras (V3.3, arquitetura aprovada
# 30/08/2026: grade variável por dificuldade + bônus de velocidade).
# XP base reaproveita scoring.xp_base_for(difficulty_level), igual a
# qualquer desafio normal — só o bônus de velocidade é próprio daqui:
# achado sob o limite de segundos (por dificuldade, maior grade = mais
# tempo) paga um bônus fixo, sem curva linear como o MCQ cronometrado
# (aqui não existe "tempo limite" que se possa estourar, só velocidade a
# premiar — nunca penaliza quem demora mais, só o oposto de MCQ_ e sem
# curva por não ter um teto de tempo natural como o timer do MCQ).
WORD_PUZZLE_FAST_COMPLETION_SECONDS = {1: 60, 2: 90, 3: 120}
WORD_PUZZLE_SPEED_BONUS_MULTIPLIER = 0.5
# Achado de auditoria de segurança M2 (05/09/2026): um script que chama
# GET /next, copia `words` direto pra `found_words` e chama /complete em
# ~50ms sempre ganhava xp_base + bônus de velocidade — piso de sanidade
# análogo ao MOVEMENT_MAX_STEPS_PER_CYCLE de Movimento. Bem abaixo do
# menor WORD_PUZZLE_FAST_COMPLETION_SECONDS (60s) pra nunca incomodar um
# jogador real rápido, só bloquear conclusão fisicamente implausível.
WORD_PUZZLE_MIN_COMPLETION_SECONDS = 3

# Meta diária opcional definida pelo usuário (STEP_COUNTER_MOVIMENTO.md
# §4, extensão pedida por Rhoney em 2026-08-21): ultrapassar a PRÓPRIA
# meta paga este bônus extra, uma vez por ciclo, além do bônus por faixa
# de MOVEMENT_STEP_TIERS — recompensa superar o que a pessoa se propôs,
# não o volume absoluto (que a faixa já cobre).
# MentalCoins por passo (29/08/2026, pedido de Rhoney): "a cada 1000
# passos = 5 MentalCoins" — por marco cruzado dentro do ciclo (app/
# movement.py), independente da faixa de XP acima.
MOVEMENT_STEPS_PER_MENTALCOIN = 1000
MOVEMENT_MENTALCOINS_PER_MILESTONE = 5

MOVEMENT_GOAL_BONUS_XP = 50
# Achado de auditoria de segurança (28/08/2026): só validava "maior que
# zero" — uma meta de 1 passo garantia o bônus com esforço zero, todo
# ciclo. Piso alinhado com o menor patamar real de MOVEMENT_STEP_TIERS
# (2000 passos já rende o multiplicador mínimo x1 ali) — abaixo disso a
# "meta" deixa de significar qualquer esforço de verdade.
MOVEMENT_MIN_DAILY_GOAL_STEPS = 2000

# Checkpoints intradiários (STEP_COUNTER_MOVIMENTO.md §4, extensão pedida
# por Rhoney em 2026-08-21): divide as 24h do ciclo em partes iguais.
# Cada uma das PARTS-1 primeiras janelas fechadas (a última coincide com
# o fim do próprio ciclo — já coberto pelo bônus por faixa de
# MOVEMENT_STEP_TIERS, pagar de novo ali seria bônus duplicado pelo
# mesmo feito) paga um bônus extra usando a MESMA fórmula/faixas de
# MOVEMENT_STEP_TIERS, só com os limiares escalados pela fração de tempo
# decorrida (ex.: em 4 partes, no checkpoint de 6h — 1/4 do dia — os
# limiares valem 1/4 do normal: 500/1.250/2.500/3.750).
MOVEMENT_CHECKPOINT_PARTS = 4

# Recompensa por compartilhar desempenho (pedido de Rhoney, 2026-08-22).
# Valor fixo e modesto de propósito — o app NÃO tem como confirmar que o
# compartilhamento via OS share sheet foi concluído (share_plus só
# confirma que o sheet foi aberto sem erro), então o valor precisa ser
# pequeno o bastante para não valer a pena "farmar" mesmo num cenário de
# falso positivo. Comparação: um acerto simples de nível fácil já paga
# 10 XP (scoring.xp_base_for) — este bônus fica na mesma ordem de
# grandeza de UM acerto, nunca de vários, e só uma vez por dia.
SHARE_XP_REWARD = 15

# Recompensa do botão de convidar amigos pra baixar o app (pedido de
# Rhoney), distinta da recompensa de compartilhar conquista acima —
# maior que SHARE_XP_REWARD e paga também em MentalCoins, de propósito:
# convidar gente nova pro app é um ato de valor diferente (crescimento
# de base de jogadores) do que compartilhar a própria conquista.
APP_INVITE_XP_REWARD = 20
APP_INVITE_MENTALCOINS_REWARD = 5

# V2 item 14 — Batalha assíncrona (ASYNC_BATTLE.md §3/§4, aprovado
# 2026-08-22). Limite é sobre desafios ENVIADOS por dia (não recebidos),
# mesmo padrão de reset de DAILY_FREE_CHALLENGE_LIMIT. Bônus de vitória
# modesto de propósito — perto de um acerto de nível médio (20 XP),
# nunca um múltiplo alto, pra não virar a forma dominante de ganhar XP.
BATTLE_DAILY_SEND_LIMIT = 3

# V4 item 1 — Torcida (PERFIL_PUBLICO_E_TORCIDA_V1.md §4, TORCIDA_
# MULTIPLA_V2.md §3): "limite razoável... a definir com Claude Code".
# Mesma ordem de grandeza de outros limites diários de interação social
# do app (BATTLE_DAILY_SEND_LIMIT=3, mas Torcida é um toque só, sem
# custo de resposta do outro lado — cabe um teto mais alto). Agregado
# entre os 4 tipos de ícone (§3: "sem limite diferenciado por tipo"),
# por (remetente, destinatário), reseta à meia-noite (mesmo padrão de
# DAILY_FREE_CHALLENGE_LIMIT).
# Achado de auditoria de segurança CRÍTICO (05/09/2026): GET
# /challenges/{id}/reattempt não verificava que o usuário de fato tinha
# errado aquele desafio antes — aceitava qualquer challenge_id, e o
# is_review em POST /answer devolve correct_answer/explanation sem
# nunca consumir limite diário nem gerar XP. Isso transformava o
# endpoint num oráculo de respostas de custo zero, ilimitado, para
# qualquer desafio do banco (mesmo um nunca servido ao usuário).
# REGRA_REVISAO_ERROS_FIM_RODADA.md define "rodada" como conceito só de
# sessão do client (não existe round_id no servidor) — a aproximação
# server-side mais forte e verificável é exigir um Attempt real e
# recente deste usuário neste challenge com is_correct=False.
REVIEW_REATTEMPT_MAX_AGE_HOURS = 6

# Achado de auditoria de segurança M1 (05/09/2026): nenhum endpoint
# tinha rate limiting — combinado com C1 (já corrigido), permitia varrer
# automaticamente todo o banco de conteúdo. Limites generosos o
# suficiente pra nunca incomodar uma pessoa jogando normal (um humano
# não resolve/erra 30 desafios em 60s), mas baixos o bastante pra
# inviabilizar automação em loop apertado.
RATE_LIMIT_ANSWER_SUBMIT = (30, 60.0)
RATE_LIMIT_REATTEMPT = (10, 60.0)
RATE_LIMIT_SEARCH = (20, 60.0)
RATE_LIMIT_HINT = (30, 60.0)
RATE_LIMIT_BATTLE_CREATE = (10, 60.0)
RATE_LIMIT_BATTLE_MY_CHALLENGE = (20, 60.0)
RATE_LIMIT_MOVEMENT_COLLECT = (30, 60.0)
RATE_LIMIT_WORD_PUZZLE_COMPLETE = (10, 60.0)
RATE_LIMIT_LEARNING_PAUSE_COMPLETE = (10, 60.0)

TORCIDA_DAILY_LIMIT_PER_TARGET = 10
TORCIDA_REACTION_TYPES = ("vibracao", "balao", "coracao", "joinha")
BATTLE_WIN_BONUS_XP = 30

# MentalCoins — moeda de prestígio semanal (U.I/MENTALCOINS_V1.md).
# Ciclo: segunda-feira 08:00 até domingo 23:59:59, horário de Brasília.
# Apuração roda no fechamento via o mesmo agendador em background já
# usado para notificações (app/scheduler.py) — nenhum serviço novo de
# cron precisa existir só para isto. Default false pelo mesmo motivo de
# NOTIFICATION_SCHEDULER_ENABLED: nunca roda em teste/dev casual.
MENTALCOINS_SCHEDULER_ENABLED = os.environ.get("MENTALCOINS_SCHEDULER_ENABLED", "false").lower() == "true"
MENTALCOINS_TIMEZONE = "America/Sao_Paulo"
# §3.1 — ranking diário de XP, repetido a cada um dos 7 dias do ciclo.
MENTALCOINS_XP_DAILY_REWARDS = [10, 5, 3]
# §3.2 — ranking de passos da semana. Usa o número absoluto de passos
# dados, independente da meta diária configurável de cada usuário.
MENTALCOINS_STEPS_WEEK_CHAMPION_REWARD = 20
MENTALCOINS_STEPS_DAY_RECORD_REWARD = 10
