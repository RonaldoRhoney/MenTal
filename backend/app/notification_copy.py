"""
Copy das notificações (NOTIFICATIONS.md §5-6). Aprovada por Rhoney em
2026-08-21 — reengajamento 24h/48h e social/ranking validadas contra a
regra de não usar linguagem de culpa/perda/urgência artificial.

MENTAL-DIR-001 (24/08/2026): MENTAL passa a ser exclusivo pra maiores
de 18 anos — a variante anonimizada de child_safe_mode (que existia
aqui) foi removida; toda notificação social usa o nickname normalmente.
"""

REENGAGEMENT_24H = {
    "title": "Seu território está esperando",
    "body": "Bora pensar um pouco hoje?",
}

# Placeholder {level} preenchido com profile.level no momento do envio —
# reforço positivo do que já foi conquistado, nunca culpa por ter sumido.
REENGAGEMENT_48H_TITLE = "Sentimos sua falta!"
REENGAGEMENT_48H_BODY_TEMPLATE = "Seu Nível {level} e seus territórios seguem esperando por você."

SOCIAL_OVERTAKE_GENERIC_TITLE = "O ranking mudou"
SOCIAL_OVERTAKE_NAMED_BODY_TEMPLATE = "{nickname} passou você no ranking. Hora de reconquistar?"

# V2 item 9 — Contador de passos (STEP_COUNTER_MOVIMENTO.md §3/§5).
# Aprovada por Rhoney em 2026-08-21 — tom convite, sem cobrança, alinhada
# com o resto. Comemora o que a pessoa andou "do tamanho que for" (0
# passos incluso — nunca culpa por não ter andado, §5), e serve de
# convite pra coleta final, nunca de cobrança.
MOVEMENT_CYCLE_REPORT_TITLE = "Seu ciclo fechou!"
MOVEMENT_CYCLE_REPORT_BODY_TEMPLATE = "{steps} passos hoje — toque pra coletar seus pontos. 🚶"

# Convite diário pra ativar Movimento (29/08/2026, pedido de Rhoney:
# "todos os dias às 07:30... convidando o usuário a ativar o contador de
# passos") — só chega a quem ainda NÃO ativou (a própria consulta em
# notifications.py para de mandar assim que a pessoa ativa, sem precisar
# de nenhum controle extra de "já mandei hoje").
MOVEMENT_ACTIVATION_INVITE_TITLE = "Bora somar passos ao XP?"
MOVEMENT_ACTIVATION_INVITE_BODY = "Ative o contador de Movimento e transforme sua caminhada de hoje em XP e MentalCoins. 🚶"

# V2 item 14 — Batalha assíncrona (ASYNC_BATTLE.md §5, aprovado
# 2026-08-22). Batalha só existe entre amigos JÁ confirmados (item 12).
# Tom de convite/comemoração, nunca de provocação — perdedor nunca lê
# "você perdeu" com ênfase na derrota.
BATTLE_CHALLENGE_RECEIVED_TITLE = "Você foi desafiado!"
BATTLE_CHALLENGE_RECEIVED_BODY_TEMPLATE = "{nickname} te desafiou em {territory}! Bora responder? 🎯"

BATTLE_OPPONENT_ANSWERED_TITLE = "Sua vez de jogar! ⚔️"
BATTLE_OPPONENT_ANSWERED_BODY_TEMPLATE = "{nickname} já respondeu a batalha em {territory}! Contra-responda agora 🎯"

BATTLE_RESULT_WIN_TITLE = "Você venceu a batalha! 🏆"
BATTLE_RESULT_WIN_BODY_TEMPLATE = "Você venceu a batalha contra {nickname}! 🏆"

BATTLE_RESULT_LOSS_TITLE = "Batalha encerrada"
BATTLE_RESULT_LOSS_BODY_TEMPLATE = "Batalha encerrada — {nickname} levou essa. Bora tentar outra? 💪"

BATTLE_RESULT_TIE_TITLE = "Batalha encerrada"
BATTLE_RESULT_TIE_BODY_TEMPLATE = "Empate na batalha contra {nickname} — os dois erraram dessa vez. Bora tentar outra? 💪"

# V2 item 13 — Disputa territorial (TERRITORY_DISPUTE.md, aprovado
# 2026-08-22). Escopo só entre amigos confirmados (mesma razão do item
# 14). Quem foi ultrapassado nunca lê "você perdeu" — tom de convite
# pra reconquistar, igual ao resultado de batalha perdida.
TERRITORY_DETENTOR_GAINED_TITLE = "Você assumiu um território! 🏰"
TERRITORY_DETENTOR_GAINED_BODY_TEMPLATE = "Você assumiu {territory} entre seus amigos! 🏰"

TERRITORY_DETENTOR_LOST_TITLE = "Seu território mudou de mãos"
TERRITORY_DETENTOR_LOST_BODY_TEMPLATE = "{nickname} assumiu {territory}. Bora reconquistar? 💪"

# V4 item 1 — Torcida (TORCIDA_MULTIPLA_V2.md §4): notificação sempre
# identifica QUEM mandou e QUAL tipo — nunca agrupa múltiplos envios
# numa mensagem só, mesmo enviados quase juntos (cada envio dispara a
# própria notificação, decisão explícita do documento). Emoji por tipo
# reforça visualmente o ícone que o client mostra na tela de perfil.
TORCIDA_RECEIVED_TITLE = "Você recebeu uma torcida! 🎉"
TORCIDA_EMOJI_BY_TYPE = {
    "vibracao": "⚡",
    "balao": "🎈",
    "coracao": "💚",
    "joinha": "👍",
}
TORCIDA_RECEIVED_BODY_TEMPLATE = "{nickname} te mandou um {emoji}!"

# Pedido de Rhoney (05/09/2026): convite pra ligar o Movimento, mesma
# área do Perfil Público onde já existe Torcida — tocar na notificação
# leva direto pra tela de Movimento (data payload "navigate": "movement",
# ver push.send_push_notification).
MOVEMENT_INVITE_RECEIVED_TITLE = "Bora se mexer? 🚶"
MOVEMENT_INVITE_RECEIVED_BODY_TEMPLATE = "{nickname} te convidou a ligar o Movimento e contar seus passos!"

# CENTRAL_DE_NOTIFICACOES_HOME_V1.md (14/09/2026) — pedido/aceite de
# amizade nunca tinham push nem registro nenhum antes desta leva
# (achado ao mapear as origens pra unificar na Central, doc §4).
FRIEND_REQUEST_RECEIVED_TITLE = "Novo pedido de amizade"
FRIEND_REQUEST_RECEIVED_BODY_TEMPLATE = "{nickname} quer ser seu amigo no MENTAL!"
FRIEND_REQUEST_ACCEPTED_TITLE = "Pedido de amizade aceito! 🤝"
FRIEND_REQUEST_ACCEPTED_BODY_TEMPLATE = "{nickname} aceitou seu pedido de amizade!"

# NOTIFICACAO_CONTEUDO_ATUALIZADO_V1.md (19/09/2026, aprovado) — dispara
# no primeiro GET /progress após publicação de conteúdo novo/corrigido
# (services.notify_content_updated_if_needed). Corpo sempre nomeia os
# Mundos afetados, nunca um Desafio individual (evita enxurrada quando
# uma correção em massa toca muitos itens de uma vez).
CONTENT_UPDATED_TITLE = "Novidade no conteúdo! ✨"
CONTENT_UPDATED_SINGLE_BODY_TEMPLATE = "{territory} foi atualizado — dá uma olhada!"
CONTENT_UPDATED_MULTIPLE_BODY_TEMPLATE = "Novidades em: {worlds} — dá uma olhada!"

# FEED_SOCIAL_V1.md §2 — texto de exibição de cada evento automático do
# Feed, montado no servidor (feed.build_feed_event_text) a partir do
# `payload` do FeedEvent. Nunca texto livre do usuário — só interpolação
# num template fixo, mesmo princípio de não-humilhação/reforço positivo
# já usado no resto das notificações deste arquivo.
FEED_EVENT_TEMPLATES = {
    "world_completed": "{nickname} completou o {world_name}! 🌍",
    "streak_milestone": "{nickname} alcançou {days} dias de sequência! 🔥",
    "level_up_milestone": "{nickname} chegou ao Nível {level}! ⭐",
    "battle_won": "{nickname} venceu uma Batalha contra {opponent_nickname}! 🏆",
    "badge_earned": '{nickname} conquistou o troféu "{badge_name}"! 🏅',
    "movement_record": "{nickname} bateu seu recorde pessoal de passos: {steps} em um dia! 🚶",
}

# Usado nas notificações de batalha e de disputa territorial — os
# territórios ainda não têm uma tabela de nomes server-side (o client
# resolve isso via l10n). 7 territórios fixos, mesmo texto exibido no
# client (client/lib/territories.dart).
TERRITORY_NAMES = {
    "palavras": "Palavras",
    "numeros": "Números",
    "logica": "Lógica",
    "conhecimento": "Conhecimento",
    "enigmas": "Enigmas",
    "textos": "Textos",
    "visual": "Visual",
}
