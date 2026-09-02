# MENTAL — Encerramento da V3 e Pendências Movidas para V4

**Status:** V3 formalmente encerrada. AAB já publicado. Este documento fecha o ciclo de auditoria da V3, registrando o destino de cada pendência identificada.
**Documento de origem:** Auditoria V3 completa (varredura de código real, git log, greps no repositório), que identificou 3 pendências.

---

## 1. Decisão geral

Todas as pendências remanescentes da V3 — que não bloqueavam o encerramento nem a publicação do AAB — são formalmente movidas para o escopo de **V4**. A V3 está encerrada como está, com essas três exceções documentadas e sem ambiguidade sobre onde cada uma será tratada.

## 2. Pendências e destino

### 2.1 Redação
- **Situação:** V3.1 prometeu explicitamente que Redação seria tratada em V3.4; quando V3.4 foi reformulado para focar exclusivamente em Libras, essa promessa não foi cumprida em nenhum documento posterior. Não existe território, migration, model ou router de Redação no código.
- **Destino:** V4. Ao ser detalhada, a mecânica de Redação precisa ser desenhada do zero (não existe rascunho aproveitável) — provavelmente reaproveitando a mecânica Pausa para Aprender para explicação de estrutura textual, mas isso é decisão de escopo a ser tomada quando V4 chegar a esse item, não uma antecipação automática.

### 2.2 Idiomas Estrangeiros
- **Situação:** Citado em V3.0 e V3.1 como "fora de escopo, a formalizar depois". Nunca foi formalmente prometido dentro da V3 — diferente de Redação, não é uma promessa quebrada, apenas um item que ficou sem documento próprio.
- **Destino:** ~~V4~~ **V5** (correção de 02/09/2026, decisão de Rhoney ao priorizar o roadmap da V4) — já existe piloto de mecânica desenhado (Inglês, bloco de 5 + desafio de frase), mas o item passa a ser tratado exclusivamente na V5, fora do escopo da V4.

### 2.3 Cor de identidade visual do bloco Curiosidade Relâmpago
- **Situação:** V3.5 já registrava isso como placeholder desde a criação do documento ("definição final da paleta — placeholder até fase visual"). Confirmado que não existe hoje nenhum sistema de cor por território/bloco no app — apenas a paleta global fixa, com a cor roxa já em uso para nível/rank.
- **Destino:** V4. Item puramente visual/cosmético, sem risco funcional — deve ser resolvido como parte natural do próximo trabalho de UI, não exige documento técnico dedicado, apenas decisão de cor quando a tela for revisada.

## 3. O que permanece encerrado e não muda

Confirmado pela auditoria, sem necessidade de ação adicional:
- Todo o conteúdo real dos territórios V3.0-V3.5 (Esportes, Regiões, Cultura Pop, Mitologia, ENEM, Concursos, Tecnologia, Finanças, Filosofia, Artes, Saúde, Curiosidade Relâmpago) — mínimo de 15 itens por território, nenhum "casca vazia".
- Pausa para Aprender (V3.2) — mecânica totalmente implementada (migration, model, router); volume de itens em Tecnologia e Libras é decisão de curadoria, não lacuna técnica.
- BUG_MOVIMENTO_XP_GRAFICOS.md — os 4 itens originais corrigidos e validados, incluindo o bug adicional de ciclo pendente ("123.040 passos presos") encontrado e corrigido durante a validação.

## 4. Cruzadas (Fase 2 de Jogos de Palavras)

Não é uma pendência não identificada — já está registrada como propositalmente adiada por decisão de Rhoney, sem prazo definido. Curadoria de conteúdo (temas e dicas) já iniciada como piloto. Fica fora do escopo deste documento de encerramento, tratada separadamente quando Rhoney decidir avançar.

## 5. Encerramento

Com este documento, a V3 do MENTAL está formalmente fechada. Nenhuma pendência remanescente bloqueia o que já foi publicado. Todo trabalho futuro relacionado aos itens da seção 2 passa a ser tratado como parte do planejamento de V4, junto com o restante do roadmap já registrado (V4_NOVOS_TERRITORIOS.md e a arquitetura de agentes de IA, cuja Fase 1 é a primeira ação ao início da V4).
