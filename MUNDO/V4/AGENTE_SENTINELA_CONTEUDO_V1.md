# MENTAL — Agente Sentinela de Conteúdo

**Status:** APROVADO. Consolida e substitui a menção pendente de "Agente de Consistência de Conteúdo" em AUDITORIA_GLOBAL_CONTEUDO_V1.md — este documento é a especificação definitiva. Segunda camada de verificação, complementar à checagem humana de Rhoney, nunca substituta dela.

---

## 1. Objetivo

Criar um agente de IA que monitora continuamente todo o conteúdo do MENTAL (Mundos, SubMundos, Blocos, Desafios, Relâmpagos), reagindo **imediatamente** quando conteúdo novo é incrementado em qualquer parte do app, buscando erros e inconsistências — como uma segunda camada de verificação que reduz o risco de algo passar despercebido conforme o volume de conteúdo cresce.

## 2. Motivação

Rhoney realiza checagem humana de todo conteúdo hoje, e essa checagem **continua obrigatória e final** — mas o volume de conteúdo do MENTAL cresceu substancialmente (múltiplos Mundos, SubMundos com centenas/milhares de itens cada), tornando plausível que algo escape mesmo numa revisão cuidadosa. O Agente Sentinela existe para reduzir esse risco, não para substituir o julgamento humano.

## 3. Modo de operação — reativo, não apenas agendado

- O agente age **imediatamente** ao detectar que novo conteúdo foi incrementado em qualquer Mundo do app — não espera um ciclo agendado (diferente, por exemplo, do monitoramento mensal já definido para o Mundo dos Concursos, que tem lógica própria por lidar com dados externos de prazo/status).
- Cobre qualquer tipo de conteúdo gamificado: perguntas e respostas de Desafios e Relâmpagos, conteúdo de Revisão, Dicas, fichas de Banca (Mundo dos Concursos), e qualquer outro tipo de conteúdo que venha a existir no app no futuro.

## 4. Fluxo de decisão — correção automática vs. fila de aprovação (ponto central deste documento)

Após extensa discussão com Rhoney sobre os riscos de correção 100% automática sem revisão, foi definido um fluxo de **dois níveis**, dividido pela natureza do problema encontrado:

### 4.1 Correções de baixíssimo risco — agente corrige automaticamente, reporta depois
Categoria restrita a problemas mecânicos, sem ambiguidade de interpretação possível:
- Erros de digitação óbvios e inequívocos.
- Links de mídia (imagem, áudio, vídeo) quebrados ou apontando para recurso inexistente.
- Problemas de formatação (ex.: tag HTML/markdown mal fechada, campo obrigatório vazio por falha técnica).
- Repetição indevida de pergunta dentro da mesma sessão (já coberto por CORRECAO_REPETICAO_PERGUNTAS_V1.md — o Sentinela reforça essa checagem continuamente).

Nesses casos, o agente corrige e **relata a correção já aplicada** no relatório periódico (seção 6) — não bloqueia a correção esperando aprovação, dado o baixíssimo risco de interpretação errada.

### 4.2 Correções de conteúdo/factuais — agente propõe, nunca publica sozinho
Categoria que envolve qualquer julgamento sobre exatidão factual, adequação pedagógica, ou interpretação de contexto:
- Resposta marcada como correta que pode estar factualmente errada.
- Pergunta ambígua, mal formulada, ou escrita para quem já domina o conteúdo em vez do usuário final (mesmo critério já estabelecido em AUDITORIA_GLOBAL_CONTEUDO_V1.md, seção 3.2).
- Nível de dificuldade mal calibrado.
- Qualquer inconsistência que exija comparação com fonte externa para ser resolvida (ex.: dado histórico, tradução, regra gramatical).

Nesses casos, o agente:
1. Identifica o problema.
2. Pesquisa em **fontes confiáveis, fiéis e oficiais** (mesmo padrão de rigor de fonte já usado em toda curadoria do MENTAL — nunca uma fonte não verificada).
3. **Prepara a correção completa e pronta**, citando a fonte usada.
4. Insere a correção proposta numa **fila de aprovação rápida** para Rhoney — não uma revisão do zero, e sim um "aprovar/rejeitar" sobre algo já pronto, reduzindo o esforço de Rhoney a uma decisão rápida por item.
5. **Nunca publica essa categoria de correção sem aprovação explícita de Rhoney.**

Este fluxo de dois níveis é o núcleo da decisão de design deste agente: rapidez onde o risco é desprezível, aprovação humana onde existe qualquer julgamento envolvido — preservando o princípio de que a revisão humana é a essência do MENTAL, aplicado de forma proporcional ao risco real de cada tipo de correção.

## 5. Fontes de referência

O agente deve seguir o mesmo padrão de rigor de fonte já estabelecido em toda a curadoria do MENTAL: fontes confiáveis, fiéis e oficiais (dicionários e gramáticas reconhecidas para questões linguísticas, fontes históricas/jornalísticas cruzadas para fatos gerais, sites oficiais de banca/DOU para o Mundo dos Concursos, e assim por diante, conforme já praticado em cada frente de conteúdo). Nunca corrigir com base em fonte única não verificada, mesmo para a categoria de correção automática.

## 6. Relatório

- O agente produz um **relatório periódico** (cadência a propor por Claude Code — ex.: diário ou semanal, equilibrando visibilidade e volume de leitura para Rhoney) consolidando: correções automáticas já aplicadas (seção 4.1) e itens pendentes na fila de aprovação (seção 4.2).
- O relatório deve ser claro e rastreável: o que foi encontrado, onde (Mundo/SubMundo/Bloco/Desafio), o que foi feito ou proposto, e a fonte usada.

## 7. Relação com agentes já existentes/planejados

- Este agente consolida e substitui a menção anterior ao "Agente de Consistência de Conteúdo" em AUDITORIA_GLOBAL_CONTEUDO_V1.md — aquele documento e este devem ser lidos em conjunto, com este prevalecendo em caso de detalhe conflitante sobre o fluxo de aprovação.
- Deve coordenar com **mental-testing** para garantir que qualquer correção (automática ou aprovada) tenha teste de regressão associado.
- Deve coordenar com **mental-security** quando uma inconsistência encontrada tocar em aspectos de segurança de conteúdo.

## 8. Escopo técnico (a propor em detalhe por Claude Code)

- Definir o mecanismo técnico de detecção de "conteúdo novo incrementado" em qualquer Mundo (ex.: gatilho em cada escrita no banco de dados de conteúdo).
- Implementar a fila de aprovação rápida para correções de conteúdo/factuais, com interface simples de aprovar/rejeitar por item.
- Definir e implementar os critérios técnicos que classificam um problema como "baixíssimo risco" (seção 4.1) vs. "conteúdo/factual" (seção 4.2), com margem de segurança — em caso de dúvida sobre a classificação, o agente deve tratar como conteúdo/factual (fila de aprovação), nunca presumir baixo risco.
- Propor a cadência do relatório periódico.

## 9. Critério de aceite

- Agente detecta e reage a conteúdo novo incrementado em qualquer Mundo, em tempo próximo ao real.
- Correções de baixíssimo risco aplicadas automaticamente e reportadas.
- Correções de conteúdo/factuais **nunca publicadas sem aprovação explícita de Rhoney**, sempre citando a fonte usada na proposta.
- Relatório periódico entregue de forma clara e rastreável.
- Nenhuma correção baseada em fonte não verificada/não confiável.

---

## Status de implementação — V1 (26/09/2026)

Implementado: `backend/app/sentinela.py` (varredura + relatório), `backend/scripts/sentinela.py` (CLI sob demanda) e gancho automático em `scripts/append_production_content.py` (roda a cada carga de conteúdo nos territórios tocados). Testes em `backend/tests/test_sentinela.py`.

- **Mecânico (§4.1):** espaço sobrando nas pontas/duplo em enunciado, alternativas, resposta e explicação — corrigido automaticamente (só se as alternativas continuarem 4 distintas com a resposta dentro) e reportado.
- **Conteúdo (§4.2), nunca alterado:** resposta dentro do enunciado, dica que entrega a resposta, pergunta repetida (mesmo enunciado + mesmas alternativas + mesma imagem no território), alternativas inválidas, resposta fora das alternativas, enunciado/explicação vazios. Em dúvida = fila.
- **Padrões legítimos ignorados** (para não poluir a fila): Cores/Visual/Textos (resposta na figura ou passagem) e enunciados que listam as próprias alternativas.
- **Relatório (§6):** `Auditorias_Pre_Producao/sentinela/RELATORIO_<data>.md`, sob demanda e a cada carga. Cadência periódica proposta: semanal (rodar `python3 scripts/sentinela.py`).
- **Limites honestos da V1:** não pesquisa fonte na web (backend custo zero); a pesquisa e a redação da correção proposta (§4.2, passos 2-3) são feitas numa sessão do Claude Code a partir do relatório, e a decisão final é de Rhoney. Ainda não há gatilho "em tempo real" a cada escrita no banco — a reação é a cada carga de conteúdo (única via de entrada de conteúdo em produção) e sob demanda. Links de mídia quebrados: verificação de formato (https) fica no validador de carga; checagem de disponibilidade da URL (rede) fica para a V2.
