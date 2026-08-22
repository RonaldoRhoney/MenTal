"""
Copy das notificações (NOTIFICATIONS.md §5-6). Aprovada por Rhoney em
2026-08-21 — reengajamento 24h/48h e social/ranking (incluindo a
variante anonimizada para child_safe_mode) validadas contra a regra de
não usar linguagem de culpa/perda/urgência artificial.
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
# Placeholder {nickname} — nunca usado se o perfil for child_safe_mode
# (NOTIFICATIONS.md §3: proibido citar outro jogador nominalmente para
# criança).
SOCIAL_OVERTAKE_NAMED_BODY_TEMPLATE = "{nickname} passou você no ranking. Hora de reconquistar?"

# child_safe_mode=true: nunca cita nome de outro jogador, mesmo o
# anônimo/apelido gerado pelo sistema — mensagem genérica de convite.
SOCIAL_OVERTAKE_CHILD_SAFE_TITLE = "A disputa está acirrada"
SOCIAL_OVERTAKE_CHILD_SAFE_BODY = "A disputa está acirrada no seu território — hora de jogar!"

# V2 item 9 — Contador de passos (STEP_COUNTER_MOVIMENTO.md §3/§5).
# Aprovada por Rhoney em 2026-08-21 — tom convite, sem cobrança, alinhada
# com o resto. Comemora o que a pessoa andou "do tamanho que for" (0
# passos incluso — nunca culpa por não ter andado, §5), e serve de
# convite pra coleta final, nunca de cobrança.
MOVEMENT_CYCLE_REPORT_TITLE = "Seu ciclo fechou!"
MOVEMENT_CYCLE_REPORT_BODY_TEMPLATE = "{steps} passos hoje — toque pra coletar seus pontos. 🚶"

# V2 item 14 — Batalha assíncrona (ASYNC_BATTLE.md §5, aprovado
# 2026-08-22). Batalha só existe entre amigos JÁ confirmados (item 12)
# — decisão de Rhoney (2026-08-22): nome aparece normalmente mesmo em
# child_safe_mode aqui, mesmo raciocínio já aplicado às telas de Amigos
# (diferente do ranking geral, que expõe estranhos). Tom de convite/
# comemoração, nunca de provocação — perdedor nunca lê "você perdeu"
# com ênfase na derrota.
BATTLE_CHALLENGE_RECEIVED_TITLE = "Você foi desafiado!"
BATTLE_CHALLENGE_RECEIVED_BODY_TEMPLATE = "{nickname} te desafiou em {territory}! Bora responder? 🎯"

BATTLE_RESULT_WIN_TITLE = "Você venceu a batalha! 🏆"
BATTLE_RESULT_WIN_BODY_TEMPLATE = "Você venceu a batalha contra {nickname}! 🏆"

BATTLE_RESULT_LOSS_TITLE = "Batalha encerrada"
BATTLE_RESULT_LOSS_BODY_TEMPLATE = "Batalha encerrada — {nickname} levou essa. Bora tentar outra? 💪"

BATTLE_RESULT_TIE_TITLE = "Batalha encerrada"
BATTLE_RESULT_TIE_BODY_TEMPLATE = "Empate na batalha contra {nickname} — os dois erraram dessa vez. Bora tentar outra? 💪"

# V2 item 13 — Disputa territorial (TERRITORY_DISPUTE.md, aprovado
# 2026-08-22). Escopo só entre amigos confirmados (mesma razão do item
# 14) — nome aparece normalmente mesmo em child_safe_mode, mesmo
# raciocínio já aplicado à Batalha assíncrona. Quem foi ultrapassado
# nunca lê "você perdeu" — tom de convite pra reconquistar, igual ao
# resultado de batalha perdida.
TERRITORY_DETENTOR_GAINED_TITLE = "Você assumiu um território! 🏰"
TERRITORY_DETENTOR_GAINED_BODY_TEMPLATE = "Você assumiu {territory} entre seus amigos! 🏰"

TERRITORY_DETENTOR_LOST_TITLE = "Seu território mudou de mãos"
TERRITORY_DETENTOR_LOST_BODY_TEMPLATE = "{nickname} assumiu {territory}. Bora reconquistar? 💪"

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
