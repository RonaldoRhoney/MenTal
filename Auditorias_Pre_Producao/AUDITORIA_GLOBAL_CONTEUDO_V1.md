# MENTAL — Auditoria Global de Perguntas e Respostas em Todos os Mundos

**Status:** Fase 1 (levantamento) CONCLUÍDA (19/09/2026). Fase 2 (correção), itens 1, 2 e 3 de 3, IMPLEMENTADOS (19/09/2026) — ver seção "Fase 2" abaixo.

## Fase 2 — o que foi corrigido (19/09/2026)

**Item 1 — 200 `explanation` vazias (Copa do Mundo/Futebol):** todas reescritas, fatos verificados (WebSearch quando necessário, inclusive Copa 2026). Nenhum item ficou sem verificação confiável.

**Item 2 — 624 `hints[0]` fantasma (23 territórios `reading_passage`):** trocados por dica genérica que não cita nenhum título fora da tela.

**Item 3 — bloco Internet (5 arquivos, 1.997 itens):** escopo decidido com Rhoney — **só `explanation`** reescrita (nunca `prompt`/`options`/`correct_answer`/`hints`, pra não mexer na chave que identifica o item já em produção). Todas as 1.997 explanations revisadas; a maioria reescrita para responder diretamente à pergunta específica (não mais curiosidade lateral do lote); **7 itens mantidos com a explanation antiga**, de propósito, por suspeita de que o próprio `correct_answer` esteja errado (ver tabela abaixo) — decisão de manter a explicação genérica em vez de confirmar um fato duvidoso.

### ⚠️ 7 itens de `internet_gigantes.json` com suspeita de `correct_answer` incorreto (não alterados — decisão de Rhoney)

| Índice | Pergunta | `correct_answer` no arquivo | O que a verificação encontrou |
|---|---|---|---|
| 91 | Participantes do re:Invent 2013 | "mais de 8.000" | Não confirmado por fonte confiável; 2012 teve ~6.000 |
| 93 | Recursos anunciados por Jassy no 1º dia (fonte de 2020) | "24" | Fontes indicam 28-30+ lançamentos |
| 138 | Crescimento das vendas da Amazon 1996-1997 | "880%" | Fonte oficial/imprensa documenta **838%** |
| 146 | Semanas antes do IPO que Jassy começou na Amazon | "três semanas" | CNBC/HBS/Fortune dizem **uma semana** |
| 157 | Serviço de música atribuído a Jassy como fundador | "Amazon Music" | Jassy escreveu o plano inicial, mas foi preterido pra liderar essa área — não é creditado como fundador |
| 199 | Ano em que o Facebook se popularizou no Brasil | "2008" | Facebook só ultrapassou o Orkut no Brasil em **2011** |
| 294 | Ano de lançamento de perfis (profiles) na Netflix | "2005" | Recurso lançado em **2013** |

**Recomendação:** revisar esses 7 itens manualmente antes da próxima curadoria — se os fatos acima estiverem certos, o `correct_answer` (e possivelmente `options`) precisa mudar, o que é uma decisão de conteúdo, não uma correção mecânica de explanation.

### Aplicar em produção
Os 32 arquivos do item 1+2 já têm commit com `backend/scripts/apply_content_audit_fixes.py` pronto pra rodar. Os 5 arquivos do bloco Internet (item 3) usam o mesmo script — depois do commit deste item, rodar:
```bash
export MENTAL_DATABASE_URL="postgresql+psycopg://..."
cd backend && python3 scripts/apply_content_audit_fixes.py content/internet_origens.json content/internet_sistemas_operacionais.json content/internet_gigantes.json content/internet_cultura.json content/internet_futuro.json
```

**Validação:** `content_validation.validate_content`: 0 erros nos 5 arquivos (1.997 itens), 0 `explanation` vazia. Suíte completa de testes do backend rodada depois de todas as mudanças de conteúdo, sem regressão.

---

## Relatório da Fase 1

**Cobertura:** estrutural 100% (4.543 desafios + 8 caça-palavras + 5 pausas para aprender, 84 territórios); qualitativa amostrada (~516 itens, ~11% do total — territórios grandes como Internet/Idiomas/Palavras/Textos não foram lidos item a item).

### Achados por severidade

**Alta prioridade**
1. **`explanation` vazia em 200 itens** (8 arquivos: `copa_mundo_*.json` ×4, `futebol_*.json` ×4) — tela de explicação fica em branco depois de responder, nos territórios de maior volume de trivia esportiva. O validador (`content_validation.py`) exige a chave existir, mas não checa se está vazia (diferente do que já faz com `prompt`) — gap a corrigir no próprio validador.
2. **624 de 638 itens com `reading_passage` (98%) têm `hints[0]` citando um título/pergunta que o jogador nunca vê na tela** — 23 territórios (Mundo dos Valores, Trânsito, Gastronomia, Oceanos, Espaço). Exemplo real: pergunta é "Em que estado está o Centro de Lançamento de Alcântara?", a dica manda "reler" uma frase-título que nunca apareceu na interface.
3. **Bloco Internet (Mundo da Tecnologia), ~1.600 itens, maior território do app**: tom sistemático de "nota de pesquisa" em vez de pergunta de quiz ("segundo relatos", "segundo uma das fontes mais específicas"), e a `explanation` frequentemente não responde à pergunta feita, fala de uma curiosidade lateral do mesmo lote temático.

**Média prioridade**
4. **15 arquivos de conteúdo (395 itens) são 100% redundantes com `seed.py`** — mesmo prompt, mesmo território, já existente. Não quebra nada em produção (`append_production_content.py` é idempotente e pula), mas não adiciona conteúdo novo nenhum se alguém pensou que estava expandindo o banco.

**Baixa prioridade / retomando pendência já conhecida**
5. 8 prompts duplicados dentro do próprio `seed.py` no território "visual" (risco latente, não ativo).
6. ~36 territórios sem progressão real de dificuldade (nível único) e 9 territórios com banco pequeno (15-18 itens) — retoma o pedido em aberto de `Engenharia_Geral/CORRECAO_REPETICAO_PERGUNTAS_V1.md`.

**Falso-positivo revisado, sem ação:** 49 itens de Idiomas com "alternativas parecidas" (ex.: "Agua"/"Água"/"Porque"/"Por que") são desafios de ortografia deliberados, não duplicata.

**Gatilho de segurança:** nenhum achado envolveu mídia quebrada ou fonte externa suspeita — não há necessidade de acionar `mental-security` a partir deste relatório.

### Recomendação de ordem (decisão final é de Rhoney)
1. Corrigir as 200 `explanation` vazias (8 explicações-modelo, uma por lote temático).
2. Regerar os 624 `hints[0]` fantasma (provavelmente scriptável: substituir por algo que não cite título nenhum).
3. Decisão de produto sobre o tom do bloco Internet (manter "curiosidade densa" de propósito, ou reescrever).
4. Decidir o destino dos 15 arquivos redundantes.
5. Ampliar banco dos 9 territórios pequenos, se sessões longas continuarem ativas neles.

Relatório completo (com exemplos item a item) disponível na transcrição do agente — peça se quiser o detalhamento bruto de qualquer território específico.

---

## 1. Objetivo

Auditar sistematicamente todo o conteúdo de perguntas e respostas do MENTAL, identificando e reportando (antes de corrigir) inconsistências que comprometam a qualidade, a clareza ou a experiência do usuário final.

## 2. Escopo da auditoria

Cobre **todos** os seguintes níveis da estrutura do app, sem exceção:
- Todos os Mundos (incluindo os que já usam a arquitetura de SubMundos, como o Mundo da Tecnologia com o SubMundo Internet).
- Todos os SubMundos existentes dentro de cada Mundo.
- Todos os Blocos dentro de cada Mundo/SubMundo.
- Todos os Desafios dentro de cada Bloco.
- Todos os Relâmpagos (modo de jogo rápido), em todos os Mundos onde esse formato exista.

## 3. Tipos de inconsistência a buscar

### 3.1 Inconsistências factuais e estruturais
- Pergunta sem resposta correta definida, ou com mais de uma alternativa marcada como correta.
- Resposta marcada como correta que, de fato, está factualmente errada (situação já identificada e corrigida em casos anteriores do projeto).
- Alternativas de resposta duplicadas ou logicamente equivalentes dentro da mesma pergunta.
- Pergunta cuja resposta depende de contexto ou mídia (imagem, áudio, vídeo) que está ausente, quebrada ou incorreta (situação já identificada anteriormente em bug do desafio Visual, com imagens quebradas exibindo o nome do asset como texto).
- Repetição indevida da mesma pergunta dentro do mesmo Desafio/Relâmpago (cobrir esta verificação em conjunto com a correção já formalizada em CORRECAO_REPETICAO_PERGUNTAS_V1.md, evitando trabalho duplicado).

### 3.2 Inconsistência de perspectiva — o ponto mais importante deste documento
**Toda pergunta deve ser redigida para o usuário final que está aprendendo ou se divertindo com o conteúdo — nunca para alguém que já domina, curou ou pesquisou aquele conteúdo previamente.** Isso significa identificar e corrigir perguntas que:
- Pressupõem conhecimento prévio que não foi apresentado dentro do próprio app (jargão técnico não explicado, referências a fatos que só fariam sentido para quem já pesquisou a fonte original).
- Usam linguagem de curadoria/pesquisa em vez de linguagem de pergunta de quiz (ex.: frases que soam como anotação de pesquisa ou rascunho de redação, não como uma pergunta clara e direta destinada a testar conhecimento).
- Têm redação ambígua o suficiente para que só quem já sabe a resposta (por ter escrito ou revisado a pergunta) consiga interpretar o que está sendo perguntado.
- Assumem que o usuário já viu ou sabe de informações contextuais que apareceram apenas na pesquisa/fonte usada para criar a pergunta, mas nunca foram incorporadas ao enunciado.

Este é um critério de **qualidade de experiência do usuário**, não apenas de correção factual — uma pergunta pode estar factualmente certa e, ainda assim, estar mal formulada por não ser inteligível para quem nunca teve contato com a fonte de pesquisa original.

### 3.3 Inconsistência de nível de dificuldade
- Perguntas classificadas como "Fácil" que exigem conhecimento muito específico ou avançado, e vice-versa (perguntas "Muito Difícil" que, na prática, são triviais).
- Verificar coerência de dificuldade dentro do mesmo Desafio/nível, comparando perguntas entre si.

## 4. Processo recomendado

1. **Levantamento completo primeiro, correção depois.** Claude Code deve produzir um relatório consolidado de todas as inconsistências encontradas, organizado por Mundo/SubMundo/Bloco/Desafio, antes de corrigir qualquer item — para que Rhoney tenha visibilidade da extensão real do problema em todo o app, da mesma forma que foi pedido para o Caça-palavras.
2. Rhoney revisa o relatório e aprova (ou ajusta) a prioridade de correção.
3. Correções são implementadas Mundo por Mundo (ou lote por lote, a critério de Claude Code), com testes de regressão confirmando que nada mais foi quebrado no processo.

## 4.1 Delegação explícita aos agentes de IA já existentes no MENTAL

Este trabalho não deve ser tratado como uma tarefa genérica e avulsa de Claude Code — o MENTAL já conta com um time de agentes de IA especializados, cada um com escopo próprio, e esta auditoria deve ser **delegada ao(s) agente(s) correspondente(s) à sua área de competência**, não executada de forma solta fora dessa estrutura já estabelecida:

- **Agente de Consistência de Conteúdo** (já concebido no roadmap do MENTAL, com a função de repetir periodicamente a Auditoria Estrutural do conteúdo): é o responsável natural por esta auditoria global de perguntas e respostas. Se este agente ainda não foi formalizado/implementado, Claude Code deve tratar esta tarefa como o **gatilho para finalmente formalizá-lo**, documentando seu escopo de forma equivalente aos demais agentes já existentes (mental-security, mental-testing, MentalFeedAI, Agente de Saúde de Infraestrutura, Agente de Moderação), e não apenas rodar a auditoria uma única vez de forma manual e isolada.
- **mental-testing**: responsável por garantir que qualquer correção aplicada a partir desta auditoria tenha teste de regressão associado, seguindo o padrão já usado nas demais entregas do projeto (ex.: os 287 testes de backend + 101 de client mantidos desde a V4).
- **mental-security**: deve ser consultado sempre que uma inconsistência encontrada tocar em aspectos de segurança de conteúdo (ex.: mídia quebrada exibindo dados não tratados, referências a fontes externas não verificadas), garantindo que a correção não introduza nenhum problema de segurança/qualidade de código ao ser aplicada.
- Caso Claude Code identifique que esta tarefa se encaixa melhor em outro agente já existente, ou justifique a criação de um agente adicional específico para isso, deve propor isso a Rhoney antes de simplesmente executar a auditoria fora da estrutura de agentes — a expectativa é que o trabalho fortaleça o sistema de agentes já em construção, não o contorne.

## 5. Relação com documentos já existentes — não duplicar trabalho

Este documento **não substitui** os seguintes, que tratam de aspectos específicos já formalizados anteriormente — devem ser tratados como parte do mesmo esforço de auditoria, sem retrabalho duplicado:
- `CACA_PALAVRAS_BUG_E_VISUAL_V1.md` (validação de palavras existentes na grade, específico do Caça-palavras).
- `CORRECAO_REPETICAO_PERGUNTAS_V1.md` (não repetição de perguntas dentro da mesma sessão).

## 6. Critério de aceite

- Relatório consolidado entregue a Rhoney, cobrindo todos os Mundos/SubMundos/Blocos/Desafios/Relâmpagos do app, categorizando cada inconsistência encontrada segundo as seções 3.1, 3.2 e 3.3.
- Nenhuma correção aplicada sem relatório prévio e aprovação de prioridade por Rhoney.
- Após aprovação, correções implementadas com testes de regressão, sem introduzir novas inconsistências no processo.
- Especial atenção documentada e resolvida para o critério da seção 3.2 (perguntas escritas pensando no usuário final, não em quem já domina o conteúdo) — este é o critério mais subjetivo da auditoria e o que exige mais cuidado de julgamento por parte do agente responsável.
## 7. Critério de aceite adicional — governança de agentes

- A auditoria foi executada através do agente responsável (Consistência de Conteúdo), não como script avulso fora da estrutura de agentes do MENTAL.
- Se o agente de Consistência de Conteúdo não existia antes desta tarefa, ele foi formalizado como parte da execução, com documentação equivalente aos demais agentes já existentes no projeto.
- Correções aplicadas têm testes de regressão associados, validados pelo mental-testing.
- Qualquer inconsistência com implicação de segurança de conteúdo foi encaminhada ao mental-security antes da correção final.
