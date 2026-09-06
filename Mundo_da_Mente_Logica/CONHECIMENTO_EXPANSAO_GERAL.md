# MENTAL — Expansão do Território Conhecimento (Conteúdo Geral — Qualquer Matéria, Exceto Cálculo)

**Status:** Aprovado para implementação.
**Documentos relacionados:** PALAVRAS_RELAMPAGO.md (mecanismo de múltipla escolha com tempo, originalmente specado para Palavras), V2_KICKOFF.md

---

## 1. Conceito

O território **Conhecimento** é expandido com um novo eixo de conteúdo: cultura geral abrangendo **português, geografia, história do Brasil e história mundial** — explicitamente **sem matemática/cálculo** (isso já é coberto pelo território Números).

Diferente de Palavras (onde o formato de tempo é um modo alternativo que convive com o digitado), aqui a decisão é diferente: **todo desafio deste conteúdo usa exclusivamente o formato de múltipla escolha com tempo regressivo** — nunca formato digitado.

---

## 2. Consequência de arquitetura — mecanismo deixa de ser exclusivo de Palavras

Como o PALAVRAS_RELAMPAGO.md especificou o mecanismo (3 alternativas, tempo escalonado por nível, tratamento suave pra timeout, bônus de XP por velocidade) **pensando em ser modo alternativo só de Palavras**, e agora esse mesmo mecanismo se torna o formato **único e obrigatório** para todo o conteúdo geral do Conhecimento, recomenda-se:

- Generalizar a implementação do mecanismo como um **componente/formato reutilizável** (ex.: `TimedMultipleChoiceChallenge`), não como algo acoplado ao território Palavras.
- As regras já definidas em PALAVRAS_RELAMPAGO.md (tempo por nível, timeout suave, bônus de velocidade) se aplicam integralmente aqui, sem necessidade de redefinir nada — é o mesmo formato, aplicado a um território diferente.
- Territórios que usam este formato até agora: **Palavras** (modo opcional, convive com digitado) e **Conhecimento — conteúdo geral** (modo único, sem alternativa digitada para este conteúdo específico).

---

## 3. Escopo do conteúdo

**Princípio aberto:** qualquer matéria de conhecimento geral/escolar é elegível — português, geografia, história do Brasil, história mundial, ciências, artes, biologia, física, química, atualidades culturais, e qualquer outra matéria básica de educação geral que venha a ser curada. **A única exclusão permanente é cálculo/matemática** (já coberto pelo território Números).

Não é uma lista fechada de matérias — é um critério de exclusão único: **se não envolve cálculo matemático, é elegível para este conteúdo**, desde que seja factualmente estável (ver critério de curadoria abaixo).

Exemplos de matérias cobertas (lista ilustrativa, não exaustiva, pode crescer livremente):
- Português (gramática, curiosidades da língua)
- Geografia (capitais, países, características do Brasil e do mundo)
- História do Brasil e história mundial
- Ciências gerais (biologia, física, química — fatos estáveis, não fórmulas de cálculo)
- Artes e cultura geral

**Fora de escopo:** matemática/cálculo (já coberto por Números), interpretação de texto longo (já coberto por Textos, que tem formato próprio de parágrafos).

Mesmo padrão de curadoria já usado no restante do MENTAL: conteúdo factualmente estável, mesmo cuidado já aplicado em TRANSIT_TERRITORY_CONCEPT_V3.md — evitar dados que mudam com frequência (ex.: população atual de um país, recordes que são batidos, estatísticas que mudam) em favor de fatos estáveis (capital de um país, data de um evento histórico, regra gramatical, classificação biológica).

---

## 4. Reaproveitamento técnico

- Reaproveita 100% a arquitetura de tempo/pontuação já aprovada em PALAVRAS_RELAMPAGO.md (seção 2-4): tempo escalonado por nível, timeout suave, bônus de XP por velocidade.
- Reaproveita a estrutura de conteúdo já existente do território Conhecimento (mesma tabela de desafios, só novo conteúdo curado e format flag indicando "somente múltipla escolha com tempo").
- Autoridade de XP/tempo permanece 100% no backend, como em todo o MENTAL.

---

## 5. Fora de escopo agora

- Não altera o formato de nenhum outro território existente — é uma expansão pontual, restrita ao conteúdo geral dentro de Conhecimento.
- Não introduz territórios novos, mundos novos, nem badges novos nesta etapa (a menos que solicitado separadamente).
