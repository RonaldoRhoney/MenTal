# V4

**Status:** Encerrada em 02/09/2026 — todos os 4 itens da ordem travada por Rhoney (abaixo) concluídos e em produção, incluindo o timing 20s universal do Relâmpago (`RELAMPAGO_TEMPO_20S_UNIVERSAL.md`) e a reorganização "Mundo da Descoberta" (`PROMPT_CLAUDE_CODE_MUNDO_DESCOBERTA.md`). Ver `V5/README.md` para o que vem a seguir.

- `V3_ENCERRAMENTO_PENDENCIAS_PARA_V4.md` — fecha o ciclo da V3 e formaliza o que foi movido pra cá (Redação, cor de identidade visual do bloco Curiosidade Relâmpago). Idiomas Estrangeiros foi movido pra cá originalmente mas **corrigido em 02/09/2026 pra V5** — ver histórico no próprio documento.
- `MENTAL_AI_AGENT_TEAM_V1.md` — arquitetura de agentes de IA para curadoria/revisão de conteúdo; Fase 1 é a primeira ação prevista ao início da V4. **Progresso (02/09/2026):** Motor A implementado — `mental-security` (Segurança + Revisor de Código fundidos, §5.1) reescrito com a stack real do projeto e escopo de qualidade de código adicionado; `mental-testing` (§5.2) criado do zero. Ambos em `/home/rhoney/Documentos/MyApps/.claude/agents/`. Motor B (Pesquisador de Conteúdo, §5.3 — agendado via n8n) **não implementado**: exige acesso à infraestrutura n8n, fora do alcance desta sessão do Claude Code. "Painel de Relatórios" (§3) fica adiado — sem Motor B rodando, o output direto no chat de cada agente Motor A já satisfaz "um único lugar onde Rhoney vê o achado", não há ainda necessidade real de um painel consolidado.
- `MENTAL_V3_SOUND_AI_PRD_Implementacao_Pos_V3_revisado.docx` — PRD de Som + IA, pós-V3.
- `V4_NOVOS_TERRITORIOS.md` — cinco novos blocos de conteúdo (Invenções, Veículos, Ouvido Afiado, Detetive Mental, Astronomia), rollout sequencial igual ao usado na V3.
- `MENTAL_AGENTES_CONSOLIDADO_V1.md` — documento vivo consolidando a descrição dos 9 agentes de IA nomeados (função, contexto, relação entre si), complementando `MENTAL_AI_AGENT_TEAM_V1.md`. **Aprovado**, sem pendência de implementação em si (registra status de cada agente: `mental-security`/`mental-testing` implementados, demais formalizados ou candidatos) — atualizar sempre que um agente mudar de status.

## Ordem de implementação (decisão de Rhoney, 02/09/2026)

1. ✅ **Perfil Público + Torcida** (`V3/PERFIL_PUBLICO_E_TORCIDA_V1.md` + `TORCIDA_MULTIPLA_V2.md`, aqui em V4) — concluído e em produção (02/09/2026): `GET/POST /profile/{id}/*`, migration 049, tela nova + pontos de entrada em Ranking/Amigos/Batalhas/Hall da Fama.
2. ✅ **Cor de identidade visual do bloco Curiosidade Relâmpago** — concluído (02/09/2026): `AppColors.mystery` (índigo, não o roxo sugerido no doc original — já em uso pra XP/nível/rank), ícone no card da Home.
3. ✅ **Redação** (`V4_REDACAO.md`) — concluído e em produção (02/09/2026).
4. ✅ **5 territórios novos** (Invenções, Veículos, Ouvido Afiado, Detetive Mental, Astronomia, `V4_NOVOS_TERRITORIOS.md`) — concluído e em produção (02/09/2026), reorganizados em "Mundo da Descoberta" (`PROMPT_CLAUDE_CODE_MUNDO_DESCOBERTA.md`).

**Idiomas Estrangeiros sai do escopo da V4** — tratado exclusivamente na V5 (ver correção em `V3_ENCERRAMENTO_PENDENCIAS_PARA_V4.md` §2.2).
