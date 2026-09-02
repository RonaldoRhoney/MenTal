# V4

**Status:** Iniciada em 02/09/2026 — Fase 1 do time de agentes de IA (primeira ação prevista pela própria V4) implementada (Motor A). Ordem do restante do roadmap **travada por Rhoney em 02/09/2026**, ver seção "Ordem de implementação" abaixo.

- `V3_ENCERRAMENTO_PENDENCIAS_PARA_V4.md` — fecha o ciclo da V3 e formaliza o que foi movido pra cá (Redação, cor de identidade visual do bloco Curiosidade Relâmpago). Idiomas Estrangeiros foi movido pra cá originalmente mas **corrigido em 02/09/2026 pra V5** — ver histórico no próprio documento.
- `MENTAL_AI_AGENT_TEAM_V1.md` — arquitetura de agentes de IA para curadoria/revisão de conteúdo; Fase 1 é a primeira ação prevista ao início da V4. **Progresso (02/09/2026):** Motor A implementado — `mental-security` (Segurança + Revisor de Código fundidos, §5.1) reescrito com a stack real do projeto e escopo de qualidade de código adicionado; `mental-testing` (§5.2) criado do zero. Ambos em `/home/rhoney/Documentos/MyApps/.claude/agents/`. Motor B (Pesquisador de Conteúdo, §5.3 — agendado via n8n) **não implementado**: exige acesso à infraestrutura n8n, fora do alcance desta sessão do Claude Code. "Painel de Relatórios" (§3) fica adiado — sem Motor B rodando, o output direto no chat de cada agente Motor A já satisfaz "um único lugar onde Rhoney vê o achado", não há ainda necessidade real de um painel consolidado.
- `MENTAL_V3_SOUND_AI_PRD_Implementacao_Pos_V3_revisado.docx` — PRD de Som + IA, pós-V3.
- `V4_NOVOS_TERRITORIOS.md` — cinco novos blocos de conteúdo (Invenções, Veículos, Ouvido Afiado, Detetive Mental, Astronomia), rollout sequencial igual ao usado na V3.

## Ordem de implementação (decisão de Rhoney, 02/09/2026)

1. **Perfil Público + Torcida** (`PERFIL_PUBLICO_E_TORCIDA_V1.md` + `TORCIDA_MULTIPLA_V2.md`, na raiz do repo) — já aprovado desde a V3, pequeno, fecha uma experiência que já existe parcialmente (Ranking sem lugar pra "entrar"). Primeiro item de produto, logo após a Fase 1 dos agentes.
2. **Cor de identidade visual do bloco Curiosidade Relâmpago** — menor item de todos, puramente visual, zero risco funcional, sem curadoria de conteúdo.
3. **Redação** — precisa ser desenhada do zero (mecânica nunca foi definida, nenhum rascunho aproveitável); vem depois dos itens mais prontos por exigir mais trabalho de concepção antes mesmo de curadoria.
4. **5 territórios novos** (Invenções, Veículos, Ouvido Afiado, Detetive Mental, Astronomia) — maior volume de trabalho, cada um exige curadoria completa do zero; deixados por último por serem o item mais "caro" em tempo.

**Idiomas Estrangeiros sai do escopo da V4** — tratado exclusivamente na V5 (ver correção em `V3_ENCERRAMENTO_PENDENCIAS_PARA_V4.md` §2.2).
