# V4

**Status:** Iniciada em 02/09/2026 — Fase 1 do time de agentes de IA (primeira ação prevista pela própria V4) parcialmente implementada. Restante do roadmap (itens movidos da V3, 5 novos territórios) ainda não priorizado/iniciado.

- `V3_ENCERRAMENTO_PENDENCIAS_PARA_V4.md` — fecha o ciclo da V3 e formaliza o que foi movido pra cá (Redação, Idiomas Estrangeiros, cor de identidade visual do bloco Curiosidade Relâmpago).
- `MENTAL_AI_AGENT_TEAM_V1.md` — arquitetura de agentes de IA para curadoria/revisão de conteúdo; Fase 1 é a primeira ação prevista ao início da V4. **Progresso (02/09/2026):** Motor A implementado — `mental-security` (Segurança + Revisor de Código fundidos, §5.1) reescrito com a stack real do projeto e escopo de qualidade de código adicionado; `mental-testing` (§5.2) criado do zero. Ambos em `/home/rhoney/Documentos/MyApps/.claude/agents/`. Motor B (Pesquisador de Conteúdo, §5.3 — agendado via n8n) **não implementado**: exige acesso à infraestrutura n8n, fora do alcance desta sessão do Claude Code. "Painel de Relatórios" (§3) fica adiado — sem Motor B rodando, o output direto no chat de cada agente Motor A já satisfaz "um único lugar onde Rhoney vê o achado", não há ainda necessidade real de um painel consolidado.
- `MENTAL_V3_SOUND_AI_PRD_Implementacao_Pos_V3_revisado.docx` — PRD de Som + IA, pós-V3.
- `V4_NOVOS_TERRITORIOS.md` — cinco novos blocos de conteúdo (Invenções, Veículos, Ouvido Afiado, Detetive Mental, Astronomia), rollout sequencial igual ao usado na V3. Ordem entre os 5 blocos e entre eles vs. os 3 itens movidos da V3 (ver `V3_ENCERRAMENTO_PENDENCIAS_PARA_V4.md`) ainda não decidida.

**Pendência em aberto, não relacionada ao roadmap V4 original:** `PERFIL_PUBLICO_E_TORCIDA_V1.md` (aprovado na V3, nunca implementado) foi encontrado esquecido — não estava registrado como concluído nem como formalmente adiado pra V4 no encerramento da V3. Destino ainda não decidido por Rhoney (entra na V4 / cancelado / decidir depois).
