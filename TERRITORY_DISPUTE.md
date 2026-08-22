# MENTAL — Disputa Territorial (item 13)

**Status:** Aprovado e implementado — item 13 da V2, fecha o Grupo 2.
**Documentos relacionados:** V2_KICKOFF.md §4/§6A, item 12 (Amigos), item 14 (Batalha assíncrona), PRODUCT_PRINCIPLES.md (Não-Humilhação)

---

## 1. Conceito

Cada território tem um "detentor": quem tem mais XP acumulado naquele território, **entre você e seus amigos confirmados** (nunca global). Decisão de Rhoney (2026-08-22, registrada em V2_KICKOFF.md §6A antes desta implementação): o critério de "detentor" é XP acumulado por território (`UserTerritoryProgress.xp_in_territory`, já existente), não taxa de acerto nem tempo.

---

## 2. Escopo — só entre amigos, nunca global

Decisão confirmada nesta implementação (2026-08-22): a disputa é calculada só dentro do grupo de amigos confirmados de cada jogador (mesmo escopo do item 14 — Batalha assíncrona — e do ranking de amigos do item 12), nunca entre estranhos.

**Por quê:** "perder território para um estranho" é exatamente o tipo de dinâmica hostil que o Princípio de Não-Humilhação pede pra evitar, especialmente num público que inclui crianças. Restringir a amigos reaproveita a mesma infraestrutura e a mesma decisão de anonimização já tomada no item 12 (nickname aparece normalmente entre amigos confirmados, diferente do ranking geral) — sem inventar uma regra nova.

Consequência prática: "detentor" não é um registro único e global por território — é sempre relativo a quem pergunta (`services.get_territory_detentor(db, user_id, territory_id)`), exatamente como o ranking `scope=friends` já funciona.

---

## 3. Sem bônus de XP por assumir

Decisão confirmada: assumir um território **não** paga XP bônus extra, diferente de `WORLD_COMPLETION_BONUS_XP` e `BATTLE_WIN_BONUS_XP`.

**Por quê:** o próprio XP acumulado já é o critério de disputa — pagar mais XP por já ter mais XP criaria um efeito "rico fica mais rico" que distorce a economia sem necessidade. O status de detentor já é a recompensa.

---

## 4. Mecânica técnica

- `services.get_territory_detentor(db, user_id, territory_id)`: entre `{user_id} ∪ amigos(user_id)`, retorna o perfil com maior `xp_in_territory > 0` nesse território (desempate determinístico por `user_id`, nunca aleatório). Retorna `None` se ninguém no grupo tem XP ainda — sempre derivado, nunca armazenado (mesmo princípio de "mundo completo").
- `GET /progress` retorna `detentor_nickname`/`is_detentor` por território, sempre do ponto de vista de quem pergunta.
- `POST /challenges/{id}/answer`: captura o detentor ANTES e DEPOIS de aplicar o XP da resposta (mesmo padrão de `was_conquered_before`/`was_world_completed_before`). Só sinaliza `territory_detentor_gained=true` na resposta exata em que a liderança muda — nunca de novo enquanto continuar líder.
- Quando alguém assume um território que tinha um detentor anterior, o detentor anterior recebe uma notificação push com tom de convite, nunca de derrota: **"{nickname} assumiu {território}. Bora reconquistar? 💪"** — mesmo padrão de `ASYNC_BATTLE.md §5`.

---

## 5. Fora de escopo agora

- Disputa global (entre estranhos): não incluída, ver §2.
- Bônus de XP por conquista: não incluído, ver §3.
- Histórico de "quantas vezes já foi detentor": não incluído — mesmo raciocínio já registrado em `ASYNC_BATTLE.md §7` (evitar comparação constante entre amigos).
