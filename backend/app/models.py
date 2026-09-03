import uuid
from datetime import datetime, date
from .timeutil import utcnow

from sqlalchemy import (
    String,
    Boolean,
    Integer,
    Text,
    JSON,
    DateTime,
    Date,
    ForeignKey,
    UniqueConstraint,
    Uuid,
)
from sqlalchemy.orm import Mapped, mapped_column

from .db import Base


def new_uuid() -> str:
    return str(uuid.uuid4())


# Gap identificado testando contra o Postgres real do projeto MENTAL
# (2026-08-19, ver docs/02_IMPLEMENTATION/SUPABASE_SETUP.md §3): colunas
# de UUID declaradas como String genérico geram erro real no Postgres
# ("operator does not exist: uuid = character varying") porque a migration
# (backend/migrations/001_initial_schema.sql) usa o tipo uuid nativo.
# sqlalchemy.Uuid é agnóstico de banco — native uuid no Postgres,
# CHAR(32) no SQLite — e mantém o valor Python como str (as_uuid=False),
# sem exigir mudança em nenhum outro ponto do código que já trata esses
# campos como string.
UUIDType = Uuid(as_uuid=False)


class Profile(Base):
    __tablename__ = "profiles"

    user_id: Mapped[str] = mapped_column(UUIDType, primary_key=True)
    nickname: Mapped[str] = mapped_column(String, nullable=False)
    nickname_is_system_generated: Mapped[bool] = mapped_column(Boolean, default=True)
    # Padrão RhoneyInc (skill admin-padrao, aplicado 2026-08-20):
    # rhoneyinc@gmail.com é sempre admin, promovido automaticamente por
    # trigger no Postgres (migrations/002_admin_role.sql), não por passo
    # manual. Nenhum endpoint usa este campo ainda no V1 — não existe
    # painel admin no Vertical Slice 01 — mas a coluna/trigger nasce agora
    # para não virar retrabalho estrutural depois.
    role: Mapped[str] = mapped_column(String, default="user")  # user|admin
    # MENTAL-DIR-001/POL-002 (24/08/2026): MENTAL passa a ser exclusivo
    # pra maiores de 18 anos — sem mais age gate multi-público nem
    # child_safe_mode (colunas antigas `age_mode`/`child_safe_mode`
    # continuam existindo no banco por ora, deprecated/não lidas por
    # nenhum código, ver migrations/021_majority_confirmation.sql).
    # Substituídas por um registro simples de consentimento: confirmou
    # maioridade quando, e aceitando qual versão dos Termos.
    age_confirmed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    terms_version_accepted: Mapped[str | None] = mapped_column(String, nullable=True)
    xp_total: Mapped[int] = mapped_column(Integer, default=0)
    level: Mapped[int] = mapped_column(Integer, default=1)
    # Campo adicionado no Vertical Slice 01 (não estava no DATA_MODEL.md
    # original): API_CONTRACT.md §6 previa "backend registra
    # parental_gate_passed_at na sessão", mas o V1 não tem mecanismo de
    # sessão de servidor (auth é stateless via token) — registrar no
    # profile é a forma mais simples de persistir esse estado sem
    # introduzir um sistema de sessão só para isso. Ver relatório do VS01.
    parental_gate_passed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)

    # V2 item 8 — Notificações (NOTIFICATIONS.md). Preferência é por
    # categoria (§4: "toggle para desativar cada categoria separadamente")
    # e vive no backend, não só localmente no aparelho como o toggle de
    # som (MICROINTERACTIONS.md) — quem decide SE notifica é o job
    # agendado no backend (services.run_notification_checks), então ele
    # precisa conhecer a preferência, não só o client.
    push_token: Mapped[str | None] = mapped_column(String, nullable=True)
    notif_reengagement_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    notif_social_enabled: Mapped[bool] = mapped_column(Boolean, default=True)
    # Atualizado a cada GET /progress (Home carrega isso sempre que abre)
    # — é o sinal de "o jogador de fato usou o app", não só "fez uma
    # requisição qualquer".
    last_seen_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    # Evita notificar de novo dentro da MESMA janela de inatividade
    # (NOTIFICATIONS.md §2: "no máximo uma notificação de reengajamento
    # por janela de inatividade") — guarda em qual das duas janelas (24h
    # ou 48h) a última notificação de reengajamento já foi enviada.
    last_reengagement_notified_window: Mapped[str | None] = mapped_column(String, nullable=True)  # "24h" | "48h"
    # Última posição conhecida no ranking semanal — permite detectar a
    # TRANSIÇÃO exata de "ultrapassado agora" (mesmo princípio já usado
    # em level_up/territory_just_conquered: nunca notificar de novo pela
    # mesma posição já notificada).
    last_known_weekly_rank: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # V2 item 9 — Contador de passos (STEP_COUNTER_MOVIMENTO.md §2). O
    # ciclo de 24h é âncorado no momento da PRIMEIRA ativação, não num
    # horário fixo do sistema — este campo nunca muda depois de setado
    # (desativar/reativar preserva o horário original, mesmo raciocínio
    # de não recomeçar streak à toa).
    movement_enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    movement_cycle_anchor_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    # Meta diária OPCIONAL definida pelo próprio usuário (pedido de
    # Rhoney, 2026-08-21) — nunca imposta pelo sistema. Null = sem meta
    # (comportamento padrão, só o bônus escalonado por faixa se aplica).
    # Ultrapassar a própria meta paga um bônus extra (config.
    # MOVEMENT_GOAL_BONUS_XP), separado do bônus de faixa — recompensa
    # especificamente superar o que a PESSOA se propôs, não o volume
    # absoluto de passos (que já é recompensado pela faixa).
    movement_daily_goal_steps: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # Recompensa por compartilhar conquista (pedido de Rhoney, 2026-08-22:
    # "compartilhando seus desempenhos... o usuário ganha xp"). O app não
    # tem como confirmar que o compartilhamento via OS share sheet foi de
    # fato concluído (share_plus só confirma que o sheet foi aberto) —
    # por isso a defesa contra farm não é "verificar o compartilhamento",
    # é um teto de 1 recompensa por dia civil (UTC), igual ao resto do
    # backend que trata data como referência UTC única.
    last_share_reward_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    # Recompensa do botão de convidar amigos pra baixar o app (pedido de
    # Rhoney) — teto de 1x/dia PRÓPRIO, separado do teto de
    # last_share_reward_date acima: são botões/recompensas distintos
    # (esta rende XP + MentalCoins, aquela só XP), então cada um tem seu
    # próprio dia já usado, nunca compartilham o mesmo teto.
    last_app_invite_reward_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    # V2 — Perfil do usuário (USER_PROFILE.md, aprovado). Todos opcionais,
    # nenhum bloqueia ou degrada o uso do app se não preenchidos (mesmo
    # princípio de Clareza Imediata/não-humilhação já aplicado a tudo).
    # Deprecated (26/08/2026) — avatar emoji pré-definido, substituído
    # por upload de foto real (photo_url abaixo). Coluna mantida (dado
    # de testadores reais já em produção), sem leitura pelo client a
    # partir de agora, mesmo padrão de outras colunas deprecated.
    avatar_id: Mapped[str | None] = mapped_column(String, nullable=True)
    # Revisão 26/08/2026 (decisão de Rhoney): real_name passa a ser
    # exposto publicamente ao lado da foto de perfil (friends/ranking/
    # battles) — reverte a regra anterior de "nunca exibido
    # publicamente", registrada em USER_PROFILE.md.
    real_name: Mapped[str | None] = mapped_column(String, nullable=True)
    # Upload de foto real (26/08/2026) substitui os avatares emoji —
    # USER_PROFILE.md §3.1 exige moderação (fail-closed) antes de
    # aparecer pra outros usuários: todo upload novo nasce 'pending',
    # só fica visível quando 'approved'. Hoje só a camada manual (admin/
    # Rhoney, via /admin/profile-photos) está implementada.
    photo_url: Mapped[str | None] = mapped_column(String, nullable=True)
    photo_moderation_status: Mapped[str] = mapped_column(String, default="none")  # none|pending|approved|rejected
    # Estado é opcional (detalhe extra); location_public controla exibição
    # pública de ambos — preencher não é o mesmo que exibir.
    location_state: Mapped[str | None] = mapped_column(String, nullable=True)
    location_country: Mapped[str | None] = mapped_column(String, nullable=True)
    location_public: Mapped[bool] = mapped_column(Boolean, default=False)
    # Cadastro mínimo obrigatório (pedido de Rhoney, 2026-08-26): antes
    # dessa mudança, USER_PROFILE.md §1/§3 tratava nome/localização como
    # 100% opcional e bloqueava explicitamente "cidade exata" por risco
    # de localizar um menor — regra motivada pelo público misto de antes
    # da DIR-001. Com o MENTAL agora exclusivo pra 18+ (sem child_safe_
    # mode), essa restrição específica deixou de se aplicar; Rhoney
    # decidiu tornar nome/país/cidade/gênero/faixa etária obrigatórios
    # antes de liberar o jogo. `city` é campo novo (o antigo `location_
    # state` continua existindo, mas não é mais obrigatório nem exigido
    # aqui). `onboarding_completed_at` marca quando os 5 campos foram
    # preenchidos pela primeira vez — GET /profile expõe pra o client
    # decidir se mostra a tela de cadastro obrigatório, mesmo padrão já
    # usado por age_confirmed_at.
    city: Mapped[str | None] = mapped_column(String, nullable=True)
    gender: Mapped[str | None] = mapped_column(String, nullable=True)  # masculino|feminino|nao_binario|prefiro_nao_informar
    age_range: Mapped[str | None] = mapped_column(String, nullable=True)  # 18-25|26-35|36-45|46+ (revisão 28/08/2026)
    onboarding_completed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class MovementCycle(Base):
    """
    Um registro por janela de 24h do contador de passos de um usuário
    (STEP_COUNTER_MOVIMENTO.md §2/§4). `steps_collected` e `xp_awarded`
    acumulam a cada coleta parcial dentro da MESMA janela — nunca
    recalculados do zero, para permitir múltiplas coletas parciais sem
    perder o que já foi convertido. `report_sent` evita reenviar o
    relatório de fim de ciclo mais de uma vez (mesmo padrão de
    last_reengagement_notified_window em Profile). `goal_bonus_awarded`
    evita pagar o bônus de meta mais de uma vez por ciclo mesmo com
    várias coletas parciais depois de já ter cruzado a meta.
    """

    __tablename__ = "movement_cycles"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(UUIDType, index=True)
    cycle_start_at: Mapped[datetime] = mapped_column(DateTime)
    cycle_end_at: Mapped[datetime] = mapped_column(DateTime)
    steps_collected: Mapped[int] = mapped_column(Integer, default=0)
    xp_awarded: Mapped[int] = mapped_column(Integer, default=0)
    report_sent: Mapped[bool] = mapped_column(Boolean, default=False)
    goal_bonus_awarded: Mapped[bool] = mapped_column(Boolean, default=False)
    # Checkpoints intradiários (pedido de Rhoney, 2026-08-21): as 24h são
    # divididas em config.MOVEMENT_CHECKPOINT_PARTS partes iguais; os
    # primeiros PARTS-1 fechamentos (a última coincide com o fim do
    # próprio ciclo, já coberto por xp_awarded/goal_bonus_awarded) pagam
    # um bônus extra se o total acumulado até aquele ponto já bate a
    # faixa de MOVEMENT_STEP_TIERS proporcional ao tempo decorrido.
    # Bitmask (bit i = checkpoint i já pago) evita pagar de novo.
    checkpoint_bonus_mask: Mapped[int] = mapped_column(Integer, default=0)


class MovementSnapshot(Base):
    """
    Registro de "quantos passos existiam até este momento", um por
    coleta (POST /movement/collect) — achado real (2026-08-26): o
    checkpoint_bonus_mask acima só guarda SE um bônus já foi pago, não
    QUANTOS passos existiam em cada ponto do dia. Sem isso não dá pra
    desenhar a curva intradiária real de progressão (pedido do redesign
    da tela Movimento) — só o total acumulado do ciclo inteiro.
    """

    __tablename__ = "movement_snapshots"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    # ondelete="CASCADE" (migration 048, 01/09/2026): sem isso, o
    # SQLAlchemy declara a FK mas não seu comportamento de exclusão — em
    # produção o Postgres real usava NO ACTION, travando a exclusão de
    # conta em cascata pra qualquer usuário com Movimento ativo.
    cycle_id: Mapped[str] = mapped_column(UUIDType, ForeignKey("movement_cycles.id", ondelete="CASCADE"), index=True)
    recorded_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    steps_total: Mapped[int] = mapped_column(Integer)


class World(Base):
    """
    V2 item 10 — Mundos completos (V2_KICKOFF.md §2/§6A). Agrupa
    territórios tematicamente relacionados (aprovado por Rhoney,
    2026-08-22): Mundo da Linguagem (palavras/textos/enigmas) e Mundo da
    Mente Lógica (números/lógica/visual/conhecimento). "Mundo completo"
    nunca é armazenado — é sempre derivado em tempo real a partir de
    UserTerritoryProgress.conquered_at (mesma disciplina de nunca ter
    duas fontes de verdade pro mesmo fato, já usada em badges).
    """

    __tablename__ = "worlds"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    name: Mapped[str] = mapped_column(String, nullable=False)
    display_order: Mapped[int] = mapped_column(Integer, default=0)


class Block(Base):
    """
    Blocos (BLOCOS_MENUS.md, aprovado 2026-08-23). Puramente organização
    de menu/navegação — nunca progressão ou conquista (isso continua
    sendo World, via UserTerritoryProgress). Mesmo padrão de World (tabela
    simples com display_order), sem qualquer derivação de "completo": um
    Bloco não tem estado, só agrupa territórios visualmente.
    """

    __tablename__ = "blocks"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    name: Mapped[str] = mapped_column(String, nullable=False)
    display_order: Mapped[int] = mapped_column(Integer, default=0)


class Territory(Base):
    __tablename__ = "territories"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    challenge_type: Mapped[str] = mapped_column(String, nullable=False)
    requires_subscription: Mapped[bool] = mapped_column(Boolean, default=False)
    free_sample_count: Mapped[int] = mapped_column(Integer, default=0)
    display_order: Mapped[int] = mapped_column(Integer, default=0)
    world_id: Mapped[str | None] = mapped_column(String, ForeignKey("worlds.id"), nullable=True)
    # Bloco é opcional (BLOCOS_MENUS.md §3): territórios que não entraram
    # em nenhum Bloco ainda continuam acessíveis normalmente, fora de
    # qualquer agrupamento de menu extra.
    block_id: Mapped[str | None] = mapped_column(String, ForeignKey("blocks.id"), nullable=True)


class UserTerritoryProgress(Base):
    __tablename__ = "user_territory_progress"

    user_id: Mapped[str] = mapped_column(UUIDType, primary_key=True)
    territory_id: Mapped[str] = mapped_column(String, primary_key=True)
    xp_in_territory: Mapped[int] = mapped_column(Integer, default=0)
    conquered_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class Challenge(Base):
    __tablename__ = "challenges"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    territory_id: Mapped[str] = mapped_column(String, ForeignKey("territories.id"))
    difficulty_level: Mapped[int] = mapped_column(Integer, default=1)
    prompt: Mapped[str] = mapped_column(Text)
    options: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    correct_answer: Mapped[str] = mapped_column(Text)
    explanation: Mapped[str] = mapped_column(Text)
    age_reviewed: Mapped[bool] = mapped_column(Boolean, default=False)
    # ARCHITECTURE_UPDATE_I18N_READY.md §3: nasce desde já, mesmo com 100%
    # dos registros em 'pt-BR' hoje — evita migração de schema dolorosa
    # quando o 2º idioma for adicionado (só inserir novos registros com
    # language_code diferente, sem alteração estrutural).
    language_code: Mapped[str] = mapped_column(String, default="pt-BR")
    # CONHECIMENTO_CONTEUDO_GERAL_E_IMAGEM.md §3 (aprovado): enriquecimento
    # visual OPCIONAL, nunca obrigatório. Decisão de arquitetura
    # (2026-08-22): V1 só cobre "imagem complementando a pergunta" e
    # "fórmula/notação técnica" — um emoji Unicode, mesmo catálogo
    # zero-custo/zero-risco-autoral já usado nos avatares (client/lib/
    # avatars.dart), nunca upload de imagem binária. "Imagem nas próprias
    # alternativas" (§3, casos 2-3 do documento) fica fora desta etapa —
    # mudaria a estrutura de `options` (hoje texto puro, usado em todo o
    # app: Palavras Relâmpago, Batalha, etc.), uma mudança maior que
    # merece desenho dedicado, não encaixe apressado aqui.
    prompt_image: Mapped[str | None] = mapped_column(String, nullable=True)
    # V4 — Detetive Mental (V4/V4_NOVOS_TERRITORIOS.md §4): 2-3 pistas
    # reveladas em etapas antes de `prompt` (a pergunta final com o
    # "veredito" da dedução). None em todo o resto do app — mesmo padrão
    # opcional-nunca-obrigatório já usado em prompt_image.
    clues: Mapped[list | None] = mapped_column(JSON, nullable=True)
    # V4 — Ouvido Afiado (V4/V4_NOVOS_TERRITORIOS.md §3): primeiro bloco
    # a usar áudio como o próprio enunciado do desafio (não confundir com
    # o futuro Sound AI, que é trilha sonora ambiente — MENTAL_V3_SOUND_
    # AI_PRD, produto diferente). Tudo-ou-nada, mesmo padrão de
    # video_url/source_name/source_url já usado na Pausa para Aprender
    # de Libras (V3.4_LIBRAS.md §3.2). None em todo o resto do app.
    audio_url: Mapped[str | None] = mapped_column(String, nullable=True)
    audio_source_name: Mapped[str | None] = mapped_column(String, nullable=True)
    audio_source_url: Mapped[str | None] = mapped_column(String, nullable=True)


class ChallengeHint(Base):
    __tablename__ = "challenge_hints"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    challenge_id: Mapped[str] = mapped_column(UUIDType, ForeignKey("challenges.id"))
    hint_level: Mapped[int] = mapped_column(Integer)
    content: Mapped[str] = mapped_column(Text)


class LearningPause(Base):
    """
    V3.2 (V3/V3.2_TECNOLOGIA.md §3) — "Pausa para Aprender": estrutura
    de conteúdo NOVA, deliberadamente diferente de Challenge — sem
    options/correct_answer/timer, é leitura pura, nunca avaliação.
    Reaproveitada também em V3.4 (Libras) e blocos futuros de V4 (§3.5),
    por isso vive numa tabela própria em vez de forçar campos opcionais
    dentro de Challenge (que exige correct_answer NOT NULL hoje).
    """

    __tablename__ = "learning_pauses"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    territory_id: Mapped[str] = mapped_column(String, ForeignKey("territories.id"))
    difficulty_level: Mapped[int] = mapped_column(Integer, default=1)
    text: Mapped[str] = mapped_column(Text)
    # Mesmo catálogo de emoji zero-custo já usado em Challenge.prompt_image.
    prompt_image: Mapped[str | None] = mapped_column(String, nullable=True)
    age_reviewed: Mapped[bool] = mapped_column(Boolean, default=False)
    language_code: Mapped[str] = mapped_column(String, default="pt-BR")
    # V3.4 (V3/V3.4_LIBRAS.md §3.2/§8) — vídeo de referência opcional,
    # sempre de fonte institucional (INES/VLibras/UFSC/IFs), com
    # atribuição obrigatória exibida junto ao player (nunca ocultar a
    # fonte). Os 3 campos são tudo-ou-nada: video_url só existe com
    # source_name/source_url preenchidos (validate_learning_pauses).
    # Nullable porque a maioria das Pausas (Tecnologia, etc.) não tem
    # vídeo — é específico de blocos com fonte de referência em vídeo.
    video_url: Mapped[str | None] = mapped_column(String, nullable=True)
    source_name: Mapped[str | None] = mapped_column(String, nullable=True)
    source_url: Mapped[str | None] = mapped_column(String, nullable=True)


class LearningPauseRead(Base):
    """
    Registra a PRIMEIRA leitura concluída de cada Pausa por usuário —
    §3.4: "não deve ser um atalho de XP fácil". XP (config.
    LEARNING_PAUSE_XP_REWARD) só é concedido na primeira vez; reler a
    mesma Pausa depois (ela pode reaparecer no sorteio) não paga de
    novo, mas a leitura em si nunca é bloqueada.
    """

    __tablename__ = "learning_pause_reads"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(UUIDType)
    learning_pause_id: Mapped[str] = mapped_column(UUIDType, ForeignKey("learning_pauses.id"))
    read_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


class Attempt(Base):
    __tablename__ = "attempts"

    attempt_id: Mapped[str] = mapped_column(UUIDType, primary_key=True)
    user_id: Mapped[str] = mapped_column(UUIDType)
    challenge_id: Mapped[str] = mapped_column(UUIDType, ForeignKey("challenges.id"))
    submitted_answer: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_correct: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    hints_used: Mapped[int] = mapped_column(Integer, default=0)
    xp_base: Mapped[int | None] = mapped_column(Integer, nullable=True)
    xp_awarded: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    # V2 item 15 — Palavras Relâmpago (PALAVRAS_RELAMPAGO.md, aprovado
    # 2026-08-22). Só preenchido em tentativas do modo relâmpago; null em
    # todo o resto do app. speed_bonus_xp guardado à parte (não só somado
    # em xp_awarded) pra reenvio idempotente do mesmo attempt_id devolver
    # o mesmo detalhamento, sem precisar recalcular.
    response_time_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)
    timed_out: Mapped[bool] = mapped_column(Boolean, default=False)
    speed_bonus_xp: Mapped[int] = mapped_column(Integer, default=0)
    # Achado de auditoria de segurança (28/08/2026): response_time_ms era
    # 100% informado pelo client — enviar 0 dobrava o bônus de velocidade
    # em qualquer território cronometrado. served_at é gravado pelo
    # PRÓPRIO SERVIDOR no momento em que o desafio é entregue (GET
    # /challenges/next), e o bônus de velocidade passa a ser calculado
    # como (agora - served_at) no momento da resposta, nunca mais
    # confiando no valor que o cliente manda.
    served_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    # Generalização do Relâmpago pra todos os territórios (29/08/2026)
    # expôs uma lacuna: o bônus de velocidade em POST /answer decidia
    # elegibilidade só por challenge.territory_id (allowlist fixa
    # TIMED_MULTIPLE_CHOICE_TERRITORIES), então um desafio servido em
    # modo relâmpago fora de "palavras"/"conhecimento" mostrava o
    # cronômetro no cliente mas nunca pagava bônus por responder rápido.
    # Gravado pelo PRÓPRIO SERVIDOR no momento em que o desafio é
    # entregue (mesmo raciocínio de served_at/response_time_ms — nunca
    # confiar num flag "isso foi relâmpago" vindo do client em
    # POST /answer, que poderia ser forjado pra sempre reivindicar
    # bônus).
    timed: Mapped[bool] = mapped_column(Boolean, default=False)
    # BUG_PERGUNTAS_REPETINDO_SEQUENCIA.md §2.3 — gravado no momento em
    # que o desafio é servido (GET /challenges/next), não recalculado
    # depois: True quando este era o ÚLTIMO item restante do lote sem
    # repetição daquele território+dificuldade+timed para este usuário.
    # POST /answer devolve esse valor em AnswerResponse.batch_exhausted
    # pro client saber que deve voltar à Home em vez de oferecer
    # repetir/seguir (não existe "próximo" real nesse ponto).
    was_last_of_batch: Mapped[bool] = mapped_column(Boolean, default=False)


class ChallengeBatchProgress(Base):
    """
    BUG_PERGUNTAS_REPETINDO_SEQUENCIA.md — fila embaralhada e persistente
    de challenge_ids ainda não servidos, por (user_id, territory_id,
    difficulty_level, timed). Substitui a heurística probabilística
    anterior (evitar repetir o último N e limitar repetições recentes)
    por uma garantia real: nenhum item se repete até o lote inteiro
    (todos os candidatos daquele território+dificuldade) ser consumido.
    Ao esvaziar, o próximo GET /challenges/next reembaralha o mesmo lote
    do zero (§2.1: "pode reiniciar... só depois de esgotado").
    """

    __tablename__ = "challenge_batch_progress"

    user_id: Mapped[str] = mapped_column(UUIDType, primary_key=True)
    territory_id: Mapped[str] = mapped_column(String, ForeignKey("territories.id"), primary_key=True)
    difficulty_level: Mapped[int] = mapped_column(Integer, primary_key=True)
    timed: Mapped[bool] = mapped_column(Boolean, primary_key=True)
    remaining_challenge_ids: Mapped[list] = mapped_column(JSON, default=list)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


class WordPuzzle(Base):
    """
    V3.3 (V3/V3.3_VIDA_PRATICA_PENSAMENTO.md §6, Jogos de Palavras) —
    Fase 1: Caça-palavras. Estrutura DELIBERADAMENTE diferente de
    Challenge: a grade inteira (letras + preenchimento) é visível ao
    jogador desde o início — não há "resposta escondida" pra proteger,
    diferente de MCQ. `grid` é uma lista de N strings de N caracteres
    (linhas da grade já resolvida); `words` é a lista de palavras reais
    escondidas nela (maiúsculas, sem acento). A grade é gerada uma única
    vez por scripts/generate_word_search.py a partir de uma lista de
    palavras curada — nunca em runtime, pra manter geração determinística
    e auditável (mesmo espírito de "nunca fabricar conteúdo").
    """

    __tablename__ = "word_puzzles"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    territory_id: Mapped[str] = mapped_column(String, ForeignKey("territories.id"))
    difficulty_level: Mapped[int] = mapped_column(Integer, default=1)
    theme: Mapped[str] = mapped_column(String)
    grid_size: Mapped[int] = mapped_column(Integer)
    grid: Mapped[list] = mapped_column(JSON)
    words: Mapped[list] = mapped_column(JSON)
    age_reviewed: Mapped[bool] = mapped_column(Boolean, default=False)
    language_code: Mapped[str] = mapped_column(String, default="pt-BR")


class WordPuzzleResult(Base):
    """
    Uma linha por TENTATIVA (equivalente ao Attempt de Challenge): nasce
    em GET /word-puzzles/next com started_at=agora, ANTES do jogador
    encontrar qualquer palavra — é isso que permite calcular o tempo
    real decorrido no servidor (nunca confiar em duração vinda do
    client, mesma regra de segurança de todo o app). completed_at só é
    preenchido quando POST /complete confirma que todas as palavras
    foram encontradas. XP só é creditado na PRIMEIRA conclusão deste
    puzzle por este usuário (mesmo espírito de LearningPauseRead —
    "não deve ser atalho de XP fácil" se o puzzle reaparecer no sorteio).
    """

    __tablename__ = "word_puzzle_results"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(UUIDType)
    word_puzzle_id: Mapped[str] = mapped_column(UUIDType, ForeignKey("word_puzzles.id"))
    started_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    elapsed_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)
    xp_awarded: Mapped[int | None] = mapped_column(Integer, nullable=True)


class LevelFeedback(Base):
    __tablename__ = "level_feedback"

    # FEEDBACK_POS_NIVEL.md (aprovado): coleta pura de opinião pós-nível,
    # nunca lida por hint_penalty_factor nem qualquer mecânica adaptativa
    # — só o endpoint admin read-only (routers/level_feedback.py) consulta
    # esta tabela. "Nível" == o challenge (difficulty_level) que acabou de
    # ser respondido, único conceito de "nível concluído" que já existe no
    # schema hoje.
    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    # Migration 048 (LGPD, 01/09/2026): nullable — vira NULL quando o
    # autor exclui a conta (ON DELETE SET NULL). Preservado anonimizado
    # (decisão de Rhoney: é insumo de calibração de dificuldade de
    # conteúdo, tem valor analítico além do vínculo com a pessoa).
    user_id: Mapped[str | None] = mapped_column(UUIDType, nullable=True)
    territory_id: Mapped[str] = mapped_column(String, ForeignKey("territories.id"))
    challenge_id: Mapped[str] = mapped_column(UUIDType, ForeignKey("challenges.id"))
    action: Mapped[str] = mapped_column(String)  # repeat|continue
    difficulty_rating: Mapped[str] = mapped_column(String)  # facil|medio|dificil|muito_dificil
    comment: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


class AppFeedback(Base):
    """
    Canal geral de feedback (pedido de Rhoney, 2026-08-26) — diferente
    de LevelFeedback (associado a um nível/desafio específico), esse é
    um comentário livre sobre o app em geral, acessível a qualquer
    momento pelo usuário (não amarrado a completar um nível).

    Revisão 29/08/2026 (decisão de Rhoney): deixa de ser privado (só
    autor + admin) e vira um MURAL PÚBLICO, visível a todos os usuários,
    com reações de curtir/amei (AppFeedbackReaction) — "isso ajudará
    mais usuários fazerem comentários sobre o app". A resposta do admin
    (admin_reply) continua existindo e aparece pra todos verem, não só
    pro autor.
    """

    __tablename__ = "app_feedback"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    # Migration 048 (LGPD, 01/09/2026): nullable — vira NULL quando o
    # autor exclui a conta (ON DELETE SET NULL), preservando o
    # comentário/resposta do admin no mural público sem manter o
    # vínculo com a pessoa (decisão de Rhoney: anonimizar, não apagar,
    # pra não quebrar o histórico da conversa pra quem acompanhava).
    user_id: Mapped[str | None] = mapped_column(UUIDType, nullable=True)
    comment: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    # Pedido de Rhoney (29/08/2026): "deve haver... campos que eu possa
    # responder, discutir e interagir com o usuário" — resposta única do
    # admin por feedback (não é uma thread completa; se precisar de
    # várias trocas no futuro, o usuário sempre pode enviar outro
    # feedback novo, que aparece como uma linha separada nesta mesma
    # tabela). read_by_user marca se o autor já viu a resposta, pra
    # decidir se mostra um badge de "não lido" na tela dele.
    admin_reply: Mapped[str | None] = mapped_column(Text, nullable=True)
    admin_reply_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    reply_read_by_user: Mapped[bool] = mapped_column(Boolean, default=False)


class ContentSuggestion(Base):
    """
    Busca na Home (pedido de Rhoney, 2026-09-03): quando o termo
    buscado não corresponde a nenhum desafio/tema existente, fica
    registrado aqui pra avaliação futura de um agente de curadoria de
    conteúdo (Motor B, V4/MENTAL_AI_AGENT_TEAM_V1.md §5.3 — ainda não
    implementado, exige infraestrutura n8n fora do alcance desta
    sessão). Por ora, visível só no painel admin in-app.
    """

    __tablename__ = "content_suggestions"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    # Mesmo padrão de anonimização de AppFeedback.user_id acima: nullable,
    # vira NULL quando o autor exclui a conta, sem apagar o registro.
    user_id: Mapped[str | None] = mapped_column(UUIDType, nullable=True)
    query_text: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


class AppFeedbackReaction(Base):
    """Curtir/amei num feedback do mural público (29/08/2026) — um
    usuário pode reagir com no máximo uma linha por (feedback, tipo);
    reagir de novo com o MESMO tipo remove a reação (toggle)."""

    __tablename__ = "app_feedback_reactions"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    feedback_id: Mapped[str] = mapped_column(UUIDType, ForeignKey("app_feedback.id"), index=True)
    user_id: Mapped[str] = mapped_column(UUIDType)
    reaction_type: Mapped[str] = mapped_column(String)  # like|love
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)

    __table_args__ = (UniqueConstraint("feedback_id", "user_id", "reaction_type"),)


class Streak(Base):
    __tablename__ = "streaks"

    user_id: Mapped[str] = mapped_column(UUIDType, primary_key=True)
    current_streak: Mapped[int] = mapped_column(Integer, default=0)
    last_played_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    freeze_available: Mapped[bool] = mapped_column(Boolean, default=True)
    freeze_used_this_week: Mapped[bool] = mapped_column(Boolean, default=False)
    week_anchor: Mapped[date | None] = mapped_column(Date, nullable=True)


class Subscription(Base):
    __tablename__ = "subscriptions"

    user_id: Mapped[str] = mapped_column(UUIDType, primary_key=True)
    status: Mapped[str] = mapped_column(String, default="none")  # none|active|expired|cancelled
    google_play_purchase_token: Mapped[str | None] = mapped_column(String, nullable=True)
    validated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class DailyChallengeUsage(Base):
    __tablename__ = "daily_challenge_usage"

    user_id: Mapped[str] = mapped_column(UUIDType, primary_key=True)
    usage_date: Mapped[date] = mapped_column(Date, primary_key=True)
    challenges_consumed: Mapped[int] = mapped_column(Integer, default=0)


class Invite(Base):
    __tablename__ = "invites"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    inviter_user_id: Mapped[str] = mapped_column(UUIDType)
    invite_code: Mapped[str] = mapped_column(String, unique=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


class InviteConversion(Base):
    __tablename__ = "invite_conversions"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    invite_id: Mapped[str] = mapped_column(UUIDType, ForeignKey("invites.id"))
    invited_user_id: Mapped[str] = mapped_column(UUIDType)
    converted_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)

    __table_args__ = (UniqueConstraint("invited_user_id", name="uq_invite_conversion_user"),)


class Friendship(Base):
    """
    V2 item 12 — Amigos (V2_KICKOFF.md §6A, aprovado 2026-08-22). N:N de
    verdade — deliberadamente NÃO reaproveita InviteConversion, que tem
    UniqueConstraint("invited_user_id") pensado pra atribuição de
    crescimento (1 resposta só pra "quem trouxe esse usuário"), o que
    limitaria cada jogador a um único amigo pra sempre. Usa o MESMO
    invite_code/deep link já existente como ponto de entrada (nenhuma
    tela nova de convite), só grava o resultado numa tabela separada.
    Par sempre canônico (user_id_a < user_id_b como string) — evita
    duas linhas pra mesma amizade dependendo de quem adicionou quem.
    """

    __tablename__ = "friendships"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    user_id_a: Mapped[str] = mapped_column(UUIDType, index=True)
    user_id_b: Mapped[str] = mapped_column(UUIDType, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    # Achado de auditoria de segurança (28/08/2026): resgatar um
    # invite_code criava a amizade de forma unilateral — o dono do
    # código nunca era consultado, e passava a expor user_id/real_name/
    # photo_url/XP pra um estranho automaticamente. status/requested_by
    # tornam o resgate um PEDIDO ('pending'); só quem NÃO pediu pode
    # aceitar ('accepted') via /social/friend-requests/{id}/accept.
    # get_friend_user_ids só considera 'accepted'.
    status: Mapped[str] = mapped_column(String, default="pending")  # pending|accepted
    requested_by: Mapped[str] = mapped_column(UUIDType)

    __table_args__ = (UniqueConstraint("user_id_a", "user_id_b", name="uq_friendship_pair"),)


class Badge(Base):
    """
    Catálogo de badges/conquistas — V2 item 1 (V2_KICKOFF.md §6A).
    `criteria_type` é avaliado por services.check_and_award_badges contra
    dado que já existe (Attempt, UserTerritoryProgress, Streak) — nenhuma
    contagem nova precisa ser mantida só para badges. `criteria_value` é
    o limiar numérico; para critérios sem limiar (ex.: "conquistar todos
    os territórios", que deve reagir a quantos territórios existirem no
    momento, não a um número fixo hoje) o valor fica 0 e é ignorado.
    """

    __tablename__ = "badges"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    code: Mapped[str] = mapped_column(String, unique=True)
    name: Mapped[str] = mapped_column(String)
    description: Mapped[str] = mapped_column(Text)
    criteria_type: Mapped[str] = mapped_column(String)
    criteria_value: Mapped[int] = mapped_column(Integer, default=0)
    display_order: Mapped[int] = mapped_column(Integer, default=0)


class UserBadge(Base):
    __tablename__ = "user_badges"

    user_id: Mapped[str] = mapped_column(UUIDType, primary_key=True)
    badge_id: Mapped[str] = mapped_column(UUIDType, ForeignKey("badges.id"), primary_key=True)
    earned_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


class Battle(Base):
    """
    V2 item 14 — Batalha assíncrona (ASYNC_BATTLE.md, aprovado
    2026-08-22). Só entre amigos já confirmados (item 12). Cada lado
    responde um desafio DIFERENTE (mesmo território/nível) — nunca o
    mesmo, pra evitar cola. A resposta em si é dada pelo já existente
    POST /challenges/{id}/answer (nenhuma lógica de score duplicada
    aqui) — este registro só correlaciona os dois lados e guarda o
    resultado/tempo de cada um pra decidir o vencedor quando ambos já
    tiverem respondido.

    *_served_at existe pra medir "tempo de resposta" de forma justa
    apesar do fluxo ser assíncrono: o desafiante responde na hora
    (challenger_served_at = created_at), mas o desafiado pode abrir dias
    depois — comparar desde created_at penalizaria sempre o desafiado.
    opponent_served_at só é preenchido no momento em que ele de fato
    abre o próprio desafio (GET /battles/{id}/my-challenge), não na
    criação da batalha.
    """

    __tablename__ = "battles"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    challenger_user_id: Mapped[str] = mapped_column(UUIDType, index=True)
    opponent_user_id: Mapped[str] = mapped_column(UUIDType, index=True)
    territory_id: Mapped[str] = mapped_column(String, ForeignKey("territories.id"))
    difficulty_level: Mapped[int] = mapped_column(Integer)
    challenger_challenge_id: Mapped[str] = mapped_column(UUIDType, ForeignKey("challenges.id"))
    opponent_challenge_id: Mapped[str] = mapped_column(UUIDType, ForeignKey("challenges.id"))
    # Achado de auditoria de segurança CRÍTICO (01/09/2026, migration
    # 047): antes, o CLIENT inventava um attempt_id novo (uuid v4) pra
    # responder o desafio de batalha, porque GET /battles/{id}/
    # my-challenge não devolvia nenhum — e POST /challenges/{id}/answer
    # aceitava qualquer attempt_id novo, criando uma tentativa (e XP)
    # nova pra ele sem limite algum, permitindo responder o MESMO
    # desafio repetidas vezes. Agora o SERVIDOR gera e grava aqui o
    # attempt_id de cada lado no momento em que o desafio é de fato
    # servido (challenger: na criação da batalha; opponent: na primeira
    # abertura) — mesmo padrão de GET /challenges/next.
    challenger_attempt_id: Mapped[str | None] = mapped_column(UUIDType, nullable=True)
    opponent_attempt_id: Mapped[str | None] = mapped_column(UUIDType, nullable=True)
    status: Mapped[str] = mapped_column(String, default="pending")  # pending|resolved
    challenger_served_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    opponent_served_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    challenger_is_correct: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    opponent_is_correct: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    challenger_response_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)
    opponent_response_ms: Mapped[int | None] = mapped_column(Integer, nullable=True)
    # null enquanto pending; também null quando resolved e foi empate
    # (ambos erraram) — status é quem diferencia "ainda não resolvida"
    # de "resolvida sem vencedor".
    winner_user_id: Mapped[str | None] = mapped_column(UUIDType, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class Report(Base):
    """
    Canal de denúncia (auditoria de segurança, 28/08/2026) — DIR-001 §4
    e POL-003 §2.4 exigem que um usuário consiga reportar conteúdo já
    aprovado (foto/nome) que se revele impróprio depois. Puramente
    reativo: não dispara nenhuma ação automática (não esconde a foto
    sozinho) — um admin revisa via GET /admin/reports e decide,
    aprovando/rejeitando a foto do lado de /admin/profile-photos como
    já existia.
    """

    __tablename__ = "reports"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    reporter_user_id: Mapped[str] = mapped_column(UUIDType, index=True)
    reported_user_id: Mapped[str] = mapped_column(UUIDType, index=True)
    reason: Mapped[str] = mapped_column(Text)
    resolved: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


class TorcidaReaction(Base):
    """
    V4 item 1 — Torcida (PERFIL_PUBLICO_E_TORCIDA_V1.md §4, expandida por
    TORCIDA_MULTIPLA_V2.md §2 pra 4 tipos de ícone). Nunca texto livre —
    reaction_type é sempre um dos 4 valores fixos de
    config.TORCIDA_REACTION_TYPES. Uma linha por envio (não agregada),
    igual ao padrão já usado em AppFeedbackReaction — o limite diário
    (services.send_torcida) é calculado por COUNT em tempo real, não por
    um contador mantido à parte.
    """

    __tablename__ = "torcida_reactions"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    from_user_id: Mapped[str] = mapped_column(UUIDType, index=True)
    to_user_id: Mapped[str] = mapped_column(UUIDType, index=True)
    reaction_type: Mapped[str] = mapped_column(String)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


class UserBlock(Base):
    """
    Bloqueio de usuário (auditoria de conformidade Google Play,
    29/08/2026, item 6 — "UGC precisa de mecanismo de bloqueio, além da
    denúncia"). Direcional (A bloqueia B não implica B bloqueia A), mas
    a checagem de elegibilidade pra amizade (services.is_blocked_either_way)
    trata qualquer bloqueio em qualquer direção como suficiente pra
    impedir novo contato — evita o cenário de quem bloqueou continuar
    recebendo pedidos da mesma pessoa.
    """

    __tablename__ = "user_blocks"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    blocker_user_id: Mapped[str] = mapped_column(UUIDType, index=True)
    blocked_user_id: Mapped[str] = mapped_column(UUIDType, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)

    __table_args__ = (UniqueConstraint("blocker_user_id", "blocked_user_id", name="uq_user_block_pair"),)


class MentalCoinsBalance(Base):
    """
    Saldo de MentalCoins (U.I/MENTALCOINS_V1.md) — moeda de prestígio
    semanal, sem valor monetário. Autoridade 100% do backend: nunca
    calculado ou decidido pelo client, só exibido.
    """

    __tablename__ = "mentalcoins_balances"

    user_id: Mapped[str] = mapped_column(UUIDType, primary_key=True)
    balance: Mapped[int] = mapped_column(Integer, default=0)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


class MentalCoinsTransaction(Base):
    __tablename__ = "mentalcoins_transactions"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(UUIDType, index=True)
    amount: Mapped[int] = mapped_column(Integer)
    reason: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


class MentalCoinsHallOfFameEntry(Base):
    """
    Congelamento dos vencedores da semana fechada (MENTALCOINS_V1.md §6)
    — nunca recalculado durante a semana seguinte, só lido. category:
    'xp_daily' (rank 1-3, reference_date = o dia específico), 'steps_week'
    (vencedor único, reference_date null) ou 'steps_day' (vencedor único,
    reference_date = o dia do pico).
    """

    __tablename__ = "mentalcoins_hall_of_fame"

    id: Mapped[str] = mapped_column(UUIDType, primary_key=True, default=new_uuid)
    cycle_start: Mapped[date] = mapped_column(Date)
    cycle_end: Mapped[date] = mapped_column(Date)
    category: Mapped[str] = mapped_column(String)
    rank: Mapped[int | None] = mapped_column(Integer, nullable=True)
    reference_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    user_id: Mapped[str] = mapped_column(UUIDType, index=True)
    nickname: Mapped[str] = mapped_column(String)
    amount: Mapped[int] = mapped_column(Integer)
    metric_value: Mapped[int] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


class MentalCoinsProcessedCycle(Base):
    """Idempotência da apuração semanal — evita creditar duas vezes o
    mesmo ciclo se o job agendado rodar mais de uma vez."""

    __tablename__ = "mentalcoins_processed_cycles"

    cycle_start: Mapped[date] = mapped_column(Date, primary_key=True)
    cycle_end: Mapped[date] = mapped_column(Date)
    processed_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)


class MentalCoinsItem(Base):
    """Catálogo de itens cosméticos resgatáveis só com MentalCoins —
    nunca compráveis com dinheiro real (MENTALCOINS_V1.md §4)."""

    __tablename__ = "mentalcoins_items"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    name: Mapped[str] = mapped_column(String)
    description: Mapped[str] = mapped_column(Text)
    cost: Mapped[int] = mapped_column(Integer)
    item_type: Mapped[str] = mapped_column(String)
    display_order: Mapped[int] = mapped_column(Integer, default=0)


class MentalCoinsRedemption(Base):
    __tablename__ = "mentalcoins_redemptions"

    user_id: Mapped[str] = mapped_column(UUIDType, primary_key=True)
    item_id: Mapped[str] = mapped_column(String, ForeignKey("mentalcoins_items.id"), primary_key=True)
    redeemed_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
