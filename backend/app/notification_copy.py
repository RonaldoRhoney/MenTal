"""
Copy das notificações (NOTIFICATIONS.md §5-6): "Claude Code propõe
variações, Rhoney aprova o texto final antes de produção." Os textos
abaixo são a OPÇÃO 1 de cada categoria — usada como default funcional
até aprovação explícita, para não bloquear a implementação. Variações
alternativas propostas no relatório desta etapa; trocar aqui é a única
mudança necessária se outra opção for escolhida.

Nenhum texto usa linguagem de perda/culpa/urgência artificial (proibido
por NOTIFICATIONS.md §2 — "você vai perder seu progresso" e afins).
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
