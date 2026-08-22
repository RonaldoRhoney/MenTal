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
# Comemora o que a pessoa andou "do tamanho que for" (0 passos incluso —
# nunca culpa por não ter andado, §5), e serve de convite pra coleta
# final, nunca de cobrança.
MOVEMENT_CYCLE_REPORT_TITLE = "Seu ciclo fechou!"
MOVEMENT_CYCLE_REPORT_BODY_TEMPLATE = "{steps} passos hoje — toque pra coletar seus pontos. 🚶"
