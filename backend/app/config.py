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
# REGRA_OFICIAL_GAMIFICACAO_MENTAL.md item 1.2 (19/09/2026, Fase 1 —
# recalibração de ações que já existem, aprovado por Rhoney): mapeia os
# 4 níveis nomeados do documento (Fácil/Média/Difícil/Muito Difícil) aos
# 5 níveis numéricos já existentes — 1:1 até o nível 4, e o nível 5
# (sem categoria própria no documento) paga o mesmo valor de "Muito
# Difícil". A fórmula de penalidade por dica (scoring.py, -25%/dica) e o
# bônus de velocidade do Relâmpago continuam aplicando sobre este
# valor-base, sem mudança de lógica — só a escala mudou.
XP_BASE_BY_DIFFICULTY = {1: 3, 2: 5, 3: 7, 4: 10, 5: 10}
XP_BASE_DEFAULT = 5

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
# pra TODO desafio Relâmpago, substituindo os valores variados por nível
# (antes: mais difícil = menos tempo, 12/10/7s). Continua um dict por
# nível (não um int solto) só pra não quebrar a assinatura de quem já
# usa `.get(difficulty_level)` — mas os 3 valores continuam idênticos de
# propósito. A fórmula de bônus de velocidade (compute_speed_bonus_xp) é
# baseada em FRAÇÃO do tempo, não em segundos absolutos — recalibra
# sozinha pra qualquer escala, nenhuma mudança de fórmula é necessária
# quando esse valor muda.
#
# 20s → 60s (pedido de Rhoney, 18/09/2026): mesmo com a janela única de
# 20s, o volume de conteúdo curado (V3.1-V3.5, Curiosidade Relâmpago
# incluída) já tinha perguntas longas demais pra ler com atenção e
# responder com conhecimento real nesse tempo — 20s ainda empurrava o
# jogador pra "suposição desesperada" em vez de leitura+compreensão da
# pergunta antes de responder. Um minuto decrescente resolve isso sem
# abandonar o formato cronometrado (que continua existindo de propósito,
# só deixa de ser hostil ao próprio conteúdo que o app já cura).
TIMED_MULTIPLE_CHOICE_TIME_LIMIT_SECONDS = {1: 60, 2: 60, 3: 60}
# Só se aplica ao modo OPCIONAL de Palavras (mode=relampago) — nível
# fácil nunca entra nesse modo lá, decisão fechada na spec original.
# Conhecimento não tem esse piso: todo nível já usa o formato com tempo,
# incluindo fácil, porque ali o formato é obrigatório, não opcional.
PALAVRAS_RELAMPAGO_MIN_DIFFICULTY_LEVEL = 2

# Selo "Novo" em desafios (06/09/2026, pedido de Rhoney) — quantos dias
# depois de Challenge.created_at o desafio ainda é considerado "novo" e
# ganha destaque na tela de desafio (services.is_challenge_new). Depois
# desse prazo, vira conteúdo normal — nunca "novo" para sempre.
NEW_CONTENT_BADGE_WINDOW_DAYS = 30

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

# MUNDO_IDIOMAS_CONSTELACAO_PALAVRAS_V1.md (19/09/2026) — etapa
# complementar automática ao final de todo Desafio do Mundo dos
# Idiomas. Valor validado com Rhoney: igual a uma resposta correta de
# dificuldade Média (XP_BASE_BY_DIFFICULTY[2]=20 — mas aqui é um valor
# FIXO e próprio, não reaproveita a fórmula de dificuldade, mesmo
# espírito de LEARNING_PAUSE_XP_REWARD acima), só na 1ª conclusão
# correta por (usuário, desafio) — nunca atalho de XP fácil repetindo o
# mesmo desafio. NÃO respeita nenhum teto diário agregado: o teto de
# 150 XP/dia da Regra Oficial (REGRA_OFICIAL_GAMIFICACAO_MENTAL.md
# item 6) ainda não existe como mecanismo no código — construir isso
# fica fora do escopo desta mecânica específica.
WORD_CONSTELLATION_XP_REWARD = 5

# Territórios do Mundo dos Idiomas que usam TTS (idioma_voices.dart, no
# client, é o espelho desta lista) — registro explícito, nunca inferido
# do texto do prompt, mesmo espírito de SUBMUNDO_BLOCK_IDS/ALWAYS_TIMED_
# TERRITORIES já usados no projeto. Libras fica de fora de propósito:
# não tem TTS nem "palavra escrita" pra reconstruir por peças.
IDIOMA_TERRITORY_IDS = {
    "ingles_basico", "ingles_intermediario", "ingles_avancado",
    "espanhol_basico", "espanhol_intermediario", "espanhol_avancado",
    "frances_basico", "frances_intermediario", "frances_avancado",
}

# Territórios onde o formato com tempo é OBRIGATÓRIO e único (nunca
# depende de mode=relampago) — Conhecimento (CONHECIMENTO_EXPANSAO_
# GERAL.md) e agora Cores (V3.0.1_DESAFIO_CORES.md, 29/08/2026): um
# desafio de atenção/velocidade de leitura só faz sentido cronometrado,
# em qualquer nível, incluindo fácil.
ALWAYS_TIMED_TERRITORIES = {"conhecimento", "cores", "curiosidade_relampago"}

# V6 — Mundo dos Valores (05/09/2026): oposto de ALWAYS_TIMED_
# TERRITORIES acima — "cápsula de texto + perguntas" exige NUNCA
# cronometrado, mesmo se o client pedir mode=relampago (backend é a
# única autoridade, nunca confia no client pra isso). Fonte do próprio
# conteúdo curado: "NAO e Relampago, sem timer, sem penalidade de
# velocidade" — ler um texto de economia contra o relógio contraria o
# propósito de compreensão de leitura.
NEVER_TIMED_TERRITORY_IDS = {
    "bolsa", "criptomoedas", "cenario_global", "financas_dia_a_dia",
    # V7 — Mundo do Trânsito (06/09/2026): mesmo formato "cápsula de
    # texto + perguntas", mesmo motivo — sem timer, sem penalidade de
    # velocidade (fonte do conteúdo curado, ver Mundo_do_Transito/*.json).
    "educacao_legislacao", "historia_curiosidades", "transportes_terrestres",
    "economia_transito", "prevencao_seguranca",
    # Mundo da Gastronomia (07/09/2026): mesmo formato "cápsula de texto
    # + perguntas", mesmo motivo.
    "gastro_mundo", "gastro_brasil", "gastro_norte_nordeste",
    "gastro_centrooeste_sudeste", "gastro_sul_fusao",
    # Mundo dos Oceanos (07/09/2026): mesmo formato "cápsula de texto +
    # perguntas", mesmo motivo.
    "oceano_mundo", "oceano_vida_marinha", "oceano_profundezas",
    "oceano_clima", "oceano_brasil",
    # Mundo Acima de Nós/Espaço (07/09/2026): mesmo formato "cápsula de
    # texto + perguntas", mesmo motivo.
    "espaco_universo", "espaco_planetas", "espaco_estrelas",
    "espaco_exploracao", "espaco_brasil",
}
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
# REGRA_OFICIAL_GAMIFICACAO_MENTAL.md item 2.1 (19/09/2026, Fase 1,
# aprovado): recalibrado de 5 pra 1 MentalCoin por marco de 1000 passos.
# XP de Movimento (faixas/meta/checkpoint abaixo) mantido como está —
# decisão explícita de Rhoney, o documento só recalibra o MentalCoin.
MOVEMENT_STEPS_PER_MENTALCOIN = 1000
MOVEMENT_MENTALCOINS_PER_MILESTONE = 1

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
# falso positivo. REGRA_OFICIAL_GAMIFICACAO_MENTAL.md item 3.4
# (19/09/2026, Fase 1, aprovado): recalibrado de 15 pra 2 — mesma ação,
# a nova escala de XP_BASE_BY_DIFFICULTY (3-10) tornou 15 desproporcional.
SHARE_XP_REWARD = 2

# Recompensa do botão de convidar amigos pra baixar o app (pedido de
# Rhoney), distinta da recompensa de compartilhar conquista acima —
# maior que SHARE_XP_REWARD e paga também em MentalCoins, de propósito:
# convidar gente nova pro app é um ato de valor diferente (crescimento
# de base de jogadores) do que compartilhar a própria conquista.
# REGRA_OFICIAL_GAMIFICACAO_MENTAL.md item 4.2 (19/09/2026, Fase 1,
# aprovado): recalibrado de 20→2 XP e 5→1 MentalCoin, mesma ação.
APP_INVITE_XP_REWARD = 2
APP_INVITE_MENTALCOINS_REWARD = 1

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
# Auditoria de segurança pré-lançamento mundial (17/09/2026, achado
# M4): busca de usuário por nome e leitura de perfil público nunca
# tiveram teto — dava pra varrer prefixos automaticamente e coletar
# user_id/nome real/foto/nível em massa. Mesma janela de RATE_LIMIT_
# SEARCH (busca de conteúdo), generosa o bastante pro uso normal (um
# usuário digitando/corrigindo um nome).
RATE_LIMIT_USER_SEARCH = (20, 60.0)
RATE_LIMIT_PUBLIC_PROFILE_VIEW = (30, 60.0)
RATE_LIMIT_HINT = (30, 60.0)
RATE_LIMIT_BATTLE_CREATE = (10, 60.0)
RATE_LIMIT_BATTLE_MY_CHALLENGE = (20, 60.0)
RATE_LIMIT_MOVEMENT_COLLECT = (30, 60.0)
RATE_LIMIT_WORD_PUZZLE_COMPLETE = (10, 60.0)
RATE_LIMIT_LEARNING_PAUSE_COMPLETE = (10, 60.0)
# Achados 2.1/2.2 da AUDITORIA_COMPLETA_PRE_PRODUCAO_V1.md (11/09/2026):
# /social/report e /profile/{id}/follow não tinham nenhum limite —
# flood de denúncia contra um alvo, ou de solicitações de follow.
RATE_LIMIT_REPORT = (10, 60.0)
RATE_LIMIT_FOLLOW = (30, 60.0)
# Auditoria de segurança pré-lançamento mundial (17/09/2026): pedido de
# amizade por user_id (busca por nome) nunca teve limite — diferente de
# Torcida/Batalha/convite de Movimento, que já tinham teto diário por
# alvo. Sem isso, um usuário podia varrer resultados de busca e
# disparar pedido (cada um gera push pro alvo) pra um número
# arbitrário de estranhos em sequência. Mesma janela de FOLLOW acima,
# ação de mesma natureza (social, sem aceite prévio necessário pra
# notificar o alvo).
RATE_LIMIT_FRIEND_REQUEST = (30, 60.0)

TORCIDA_DAILY_LIMIT_PER_TARGET = 10
TORCIDA_REACTION_TYPES = ("vibracao", "balao", "coracao", "joinha")

# Achado 2.1 da auditoria (11/09/2026): mesmo raciocínio de teto diário
# por (denunciante, denunciado) já usado em Torcida — sem isso, um
# usuário sozinho pode fazer a fila de GET /admin/reports virar ruído
# só denunciando a mesma pessoa repetidamente.
REPORT_DAILY_LIMIT_PER_TARGET = 5

# Pedido de Rhoney (05/09/2026) — convite pra ligar o Movimento, mesma
# área do Perfil Público. Teto BEM mais baixo que Torcida de propósito:
# é um convite pessoal e mais "pesado" que uma reação rápida, não faz
# sentido mandar várias vezes no mesmo dia pro mesmo alvo.
MOVEMENT_INVITE_DAILY_LIMIT_PER_TARGET = 1
# REGRA_OFICIAL_GAMIFICACAO_MENTAL.md item 1.5 (19/09/2026, Fase 1,
# aprovado): recalibrado de 30 pra 2 — vencer Batalha volta a ser um
# bônus distinto do XP de resposta correta, não maior que ele.
BATTLE_WIN_BONUS_XP = 2

# FEED_SOCIAL_V1.md §2 — eventos automáticos aceitos no Feed (piloto).
# Nenhum evento fora desta lista pode ser criado (feed.create_feed_event
# valida contra este conjunto) — trava contra typo/tipo inventado em
# runtime virar uma entrada de feed "órfã" que o client não sabe exibir.
FEED_EVENT_TYPES = frozenset({
    "world_completed",
    "streak_milestone",
    "level_up_milestone",
    "battle_won",
    "badge_earned",
    "movement_record",
})

# FEED_SOCIAL_V1.md §2: "a cada 10 níveis, não em todo nível pra não
# poluir o feed", e marcos de streak citados como exemplo (30/60/100).
FEED_LEVEL_UP_MILESTONE_INTERVAL = 10
FEED_STREAK_MILESTONES = (30, 60, 100)

FEED_LIST_DEFAULT_LIMIT = 20
FEED_LIST_MAX_LIMIT = 50

# CENTRAL_DE_NOTIFICACOES_HOME_V1.md §3 — "prazo técnico razoável (ex.:
# 30 dias)", proposto por Claude Code e implementado exatamente como
# sugerido no próprio documento; ajustável aqui se Rhoney pedir outro
# valor depois de ver em produção.
NOTIFICATION_RETENTION_DAYS = 30
NOTIFICATION_LIST_DEFAULT_LIMIT = 20
NOTIFICATION_LIST_MAX_LIMIT = 50

# MentalCoins — moeda de prestígio semanal (MentalCoins/MENTALCOINS_V1.md).
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

# SCREENSHOTS_LOJA_E_AVISO_ATUALIZACAO_V1.md §2 (05/09/2026) — aviso
# gentil de nova versão disponível. Backend expõe a versão mais recente
# publicada e a mínima ainda aceita (client compara com sua própria
# versão instalada, ver client/pubspec.yaml). Sobrescrevível por env
# var pra não exigir redeploy só pra anunciar uma versão nova — versão
# (não build number) no formato "major.minor.patch", igual ao
# `version:` de pubspec.yaml sem o sufixo "+build".
#
# min_required == latest por padrão: nenhuma versão em campo hoje exige
# atualização obrigatória. Só sobe min_required quando uma versão
# publicada corrigir algo crítico de segurança/integridade (decisão de
# Rhoney, nunca automática).
APP_LATEST_VERSION = os.environ.get("APP_LATEST_VERSION", "0.3.0")
APP_MIN_REQUIRED_VERSION = os.environ.get("APP_MIN_REQUIRED_VERSION", "0.3.0")

# REGRA_OFICIAL_GAMIFICACAO_MENTAL.md — Fase 2 (19/09/2026, aprovada por
# Rhoney): recompensas novas. Todas passam por rewards.py (claim único por
# período em mental.reward_claims — nunca pagam duas vezes).
#
# 4.1 Login diário: +1 XP e +0,5 MentalCoin. O saldo é sempre inteiro,
# então 0,5 vira "1 moeda a cada 2 logins" (média exata, decisão de
# Rhoney — sem migração de schema pra decimal).
LOGIN_DAILY_XP = 1
LOGIN_COIN_EVERY_N_LOGINS = 2
LOGIN_COIN_AMOUNT = 1
# 5 — marcos do streak geral: dias -> (tipo, valor). 30 e 100 dias também
# dão distintivo (badges streak_30/streak_100, migrations/082).
STREAK_MILESTONE_REWARDS = {
    7: ("xp", 15),
    15: ("xp", 30),
    30: ("coins", 75),
    100: ("coins", 250),
}
# 3.2 marco de amigos confirmados (5, 10, 15...): +1 XP, único por marco.
FRIEND_MILESTONE_EVERY = 5
FRIEND_MILESTONE_XP = 1
# 3.3 Torcida a AMIGO confirmado: +1 XP, 1x por dia (só amigo — Torcida
# está aberta a qualquer perfil, recompensar estranho viraria farm).
TORCIDA_FRIEND_DAILY_XP = 1
# 4.3 feedback: +5 XP, 1x por semana ISO; texto mínimo pra não pagar por
# "a"/"." repetido.
FEEDBACK_WEEKLY_XP = 5
FEEDBACK_REWARD_MIN_CHARS = 10
# 3.1 interação diária com amigos (Torcida, Batalha ou convite de
# Movimento a amigo confirmado) por 7 dias seguidos: +10 XP.
FRIEND_INTERACTION_STREAK_DAYS = 7
FRIEND_INTERACTION_STREAK_XP = 10
# 2.2 Movimento: dia ativo = ciclo com >= 2.000 passos (mesmo piso de
# MOVEMENT_MIN_DAILY_GOAL_STEPS); 7 dias ativos seguidos: +10 MentalCoins.
MOVEMENT_ACTIVE_DAY_MIN_STEPS = 2000
MOVEMENT_ACTIVE_STREAK_DAYS = 7
MOVEMENT_ACTIVE_STREAK_COINS = 10
# 1.3/1.4 lote de perguntas (o "Desafio inteiro"): +3 XP ao terminar,
# +5 XP extra se todas certas e sem dica (mínimo de respostas no lote
# pra "perfeito" não valer por um lote trivial).
BATCH_COMPLETE_BONUS_XP = 3
BATCH_PERFECT_BONUS_XP = 5
BATCH_PERFECT_MIN_ANSWERS = 2
