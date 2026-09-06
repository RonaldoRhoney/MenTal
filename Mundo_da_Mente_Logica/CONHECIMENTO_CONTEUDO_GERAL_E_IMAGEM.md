# MENTAL — Território Conhecimento: Conteúdo Geral e Curadoria de Imagem

**Status:** Aprovado para implementação.
**Documentos relacionados:** PALAVRAS_RELAMPAGO.md (mecanismo de múltipla escolha com tempo), V2_KICKOFF.md, FAMILY_SAFETY.md

---

## 1. Escopo do conteúdo — princípio aberto

O território **Conhecimento** é expandido com conteúdo geral cobrindo **qualquer matéria de conhecimento escolar/geral** — português, geografia, história do Brasil, história mundial, ciências (biologia, física, química), artes, cultura geral, e qualquer outra matéria básica que venha a ser curada no futuro.

**Não é uma lista fechada de matérias.** O critério é um único corte de exclusão: **cálculo/matemática nunca entra aqui** — isso é papel exclusivo do território Números.

**Critério de curadoria:** conteúdo deve ser factualmente estável (mesmo cuidado já aplicado em TRANSIT_TERRITORY_CONCEPT_V3.md) — evitar dados que mudam com frequência (população atual, recordes que são batidos, estatísticas variáveis) em favor de fatos estáveis (capital de um país, data de um evento histórico, regra gramatical, classificação biológica, fórmula química).

---

## 2. Formato de resposta — exclusivamente múltipla escolha com tempo

Todo desafio deste conteúdo usa o mecanismo já definido em **PALAVRAS_RELAMPAGO.md** — 3 alternativas, tempo regressivo escalonado por nível de dificuldade, tratamento suave quando o tempo esgota (não conta como erro pleno), bônus de XP por velocidade de resposta. Não existe aqui o formato digitado tradicional — diferente de Palavras, onde o formato com tempo é opcional, aqui é o único formato.

Reforça-se a recomendação já registrada: implementar o mecanismo como componente reutilizável (ex.: `TimedMultipleChoiceChallenge`), já usado tanto por Palavras (modo opcional) quanto por este conteúdo geral (modo único).

---

## 3. Enriquecimento visual — opcional, nunca obrigatório

Cada desafio pode, **quando fizer sentido**, incluir imagem/ilustração como suporte — mas isso nunca é obrigatório. A decisão de usar ou não visual é feita desafio a desafio, na curadoria de conteúdo, e depende exclusivamente de a imagem facilitar o entendimento ou enriquecer a interação.

**Onde a imagem pode aparecer (flexível, conforme o contexto da pergunta):**
- **Complementando a pergunta em si** — ex.: uma ilustração histórica acompanhando "quem descobriu o Brasil?".
- **Complementando as alternativas de resposta** — ex.: fotos das cidades nas 3 opções de "qual a capital do Brasil?", em vez de só o nome escrito.
- **Como parte central da charada** — ex.: pergunta descreve características de um item ("assada, arredondada..."), e as alternativas mostram imagens dos itens (fruta, objeto, etc.), não apenas nomes.
- **Fórmula ou notação técnica** — ex.: fórmula química ilustrando a pergunta ou uma das alternativas.

**Regra geral:** sempre contextualizar quando a imagem agrega valor real ao entendimento; nunca forçar imagem só para "ter ilustração" quando o texto sozinho já é suficiente e claro.

---

## 4. Política de curadoria de imagem — pessoas reais vs. ilustração histórica

- **Fatos/pessoas com foto real disponível (tipicamente século XX em diante):** uso de fotografia real é permitido.
- **Fatos/pessoas sem foto real disponível (períodos anteriores, ex.: colonial, antiguidade):** usar ilustração, gravura ou pintura histórica de época em vez de tentar simular um retrato realista.

Este critério é sobre disponibilidade e precisão histórica da imagem, não sobre uma restrição geral de uso de fotos reais no conteúdo educacional/histórico deste território.

---

## 5. Escopo técnico (alto nível)

- Reaproveita a estrutura de conteúdo já existente do território Conhecimento (mesma tabela de desafios), com novo campo indicando formato "múltipla escolha com tempo, sem alternativa digitada" e campo opcional de referência a imagem/ilustração por desafio.
- Reaproveita 100% a arquitetura de tempo, timeout e bônus de velocidade já aprovada em PALAVRAS_RELAMPAGO.md.
- Fonte/pipeline de imagem: a definir por Claude Code na proposta de arquitetura — pode reaproveitar pipeline já usado no território Visual (desafios visuais), se aplicável, ou pipeline novo dedicado a este conteúdo.
- Autoridade de XP, tempo e resultado permanece 100% no backend, como em todo o MENTAL.

---

## 6. Fora de escopo agora

- Não altera o formato de nenhum outro território existente além do já definido para Conhecimento.
- Não introduz territórios novos, mundos novos, nem badges novos nesta etapa.
- Não define ainda a fonte exata do banco de imagens (biblioteca, banco de gravuras históricas, etc.) — fica para a proposta de arquitetura de Claude Code.
