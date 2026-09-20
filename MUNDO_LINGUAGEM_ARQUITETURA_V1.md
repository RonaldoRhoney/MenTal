# MENTAL — Mundo da Linguagem: Arquitetura e Delegação ao Agente de Curadoria

**Status:** APROVADO. Novo Mundo dedicado à gramática da Língua Portuguesa. Conteúdo deve ser produzido pelo agente autônomo de curadoria, com aprovação humana obrigatória antes de qualquer publicação — mesmo princípio já estabelecido para o Mundo dos Idiomas (expansão de vocabulário) e o Mundo dos Concursos.
> **Andamento (20/09/2026):** estrutura implementada — 1 SubMundo (bloco `lg_<slug>`) por tema, com 1 território `linguagem_<slug>` de 50 perguntas (25 nível 1 + 15 nível 2 + 10 nível 3; o Desafio usa todos os níveis e o Relâmpago só os níveis 2 e 3, regra do app). Plano dos 19 temas em `backend/content/plano_temas_linguagem.json` (só os de status `ativo` são registrados). **Lote piloto de Crase** (50 perguntas originais) em `MUNDO/Mundo_da_Linguagem/temas/crase_lote1.json`, **aguardando revisão de Rhoney** antes de ir ao ar (migration 088 + carga). Demais temas: um lote revisável por vez, na ordem da seção 5.

---

## 1. Objetivo

Criar o **Mundo da Linguagem**, dedicado à gramática da Língua Portuguesa, cobrindo os principais tópicos normalmente exigidos em provas, concursos e no domínio prático do idioma — crase, preposição, regência, concordância, entre outros.

## 2. Temas identificados (levantamento de pesquisa, base para o agente)

Lista consolidada a partir de pesquisa sobre os principais assuntos de gramática da Língua Portuguesa:

Crase · Preposição · Regência Verbal · Regência Nominal · Concordância Verbal · Concordância Nominal · Colocação Pronominal · Pronomes · Pontuação · Ortografia · Acentuação Gráfica · Numerais · Interjeições · Morfologia · Sintaxe · Semântica · Orações Coordenadas e Subordinadas · Figuras de Linguagem · Interpretação de Texto

Esta lista é o ponto de partida — o agente de curadoria pode propor ajustes (fusão de temas muito próximos, divisão de temas muito amplos, ou adição de tema relevante não listado aqui) antes de iniciar a produção em massa, reportando a Rhoney para validação.

## 3. Volume de conteúdo por tema

- Para cada tema (ex.: Crase), a estrutura-padrão é: **25 Desafios distintos + 25 Relâmpagos distintos**, cada Desafio e cada Relâmpago seguindo o mesmo padrão de perguntas já usado nos demais Mundos do MENTAL (5 ou 20 perguntas por unidade, conforme o padrão já estabelecido).
- **Esta escala (25+25) é a referência-padrão aplicada a cada um dos temas da seção 2**, não uma exceção pontual da Crase. Como o volume total resultante é substancial (dado o número de temas), o agente deve produzir e entregar o conteúdo **tema por tema, em lotes revisáveis**, não todos de uma vez, permitindo a Rhoney acompanhar e ajustar o ritmo/prioridade conforme necessário.

## 4. Delegação ao agente de curadoria — mesmo princípio já estabelecido

- Este Mundo deve ser populado pelo **agente autônomo de curadoria de conteúdo** (mesmo agente já direcionado para a expansão do Mundo dos Idiomas e para o Mundo dos Concursos), não por curadoria manual linha a linha no chat.
- O agente deve pesquisar fontes confiáveis sobre cada tema gramatical (gramáticas normativas reconhecidas, materiais educacionais estabelecidos) para embasar o conteúdo, **sempre redigindo perguntas e explicações originais**, nunca copiando literalmente de nenhuma fonte — mesmo princípio de originalidade já aplicado a todo o conteúdo do MENTAL.
- **Revisão humana de Rhoney continua obrigatória e não-negociável** antes de qualquer Desafio ou Relâmpago ir ao ar.

## 5. Ordem de produção sugerida (a validar por Rhoney)

Com base numa lógica pedagógica de progressão encontrada na pesquisa (da base para o mais avançado), sugestão de ordem de produção, tema por tema:
1. Morfologia (classes de palavras — base para os demais temas)
2. Interpretação de Texto
3. Concordância Verbal e Nominal
4. Regência Verbal e Nominal
5. Crase
6. Colocação Pronominal e Pronomes
7. Pontuação, Ortografia, Acentuação Gráfica
8. Numerais, Interjeições
9. Sintaxe, Orações Coordenadas e Subordinadas
10. Semântica, Figuras de Linguagem

Esta ordem é uma sugestão inicial — Rhoney pode reordenar por prioridade própria (ex.: começar pelos temas mais cobrados em concursos, já que há sobreposição direta com o Mundo dos Concursos).

## 6. Escopo técnico (a propor em detalhe por Claude Code)

- Modelar a estrutura de dados do Mundo da Linguagem, compatível com a arquitetura já existente (Mundo → Bloco/Tema → Desafio/Relâmpago → perguntas), reaproveitando o que for aplicável dos Mundos já implementados.
- Confirmar com o agente de curadoria já formalizado (ou em formalização) se a capacidade de produção comporta o volume total estimado, e propor um cronograma realista de entrega por tema.
- Garantir que cada lote entregue por tema venha com verificação de originalidade e de precisão gramatical antes de chegar à revisão de Rhoney.

## 7. Critério de aceite

- Mundo da Linguagem estruturado, com temas organizados conforme a lista da seção 2 (ajustada, se necessário, pelo agente com validação de Rhoney).
- Cada tema populado com 25 Desafios e 25 Relâmpagos, entregues em lotes revisáveis, não em massa de uma vez.
- Nenhum conteúdo publicado sem passar pela revisão humana obrigatória de Rhoney.
- Conteúdo gramaticalmente correto e original, sem cópia literal de nenhuma fonte de referência.
