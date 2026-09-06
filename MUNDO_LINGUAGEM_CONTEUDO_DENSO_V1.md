# MENTAL — Mundo da Linguagem: Conteúdo Mais Denso e Desafiador

**Status:** Implementado (06/09/2026) — ver seção 7.
**Origem:** Pedido recorrente de testadores via Feedback no app, relatando conteúdo simples e repetitivo demais no Mundo da Linguagem.
**Escopo:** Apenas conteúdo/curadoria. A liberdade de navegação do jogador (acesso a qualquer desafio, a qualquer momento, sem progressão sequencial obrigatória) permanece intacta e não é afetada por este documento — foi deliberadamente descartada uma proposta de trava de progressão sequencial nesta rodada, por contrariar um princípio de liberdade já estabelecido no app.

---

## 1. Objetivo

Elevar a densidade e o nível de exigência cognitiva do conteúdo do Mundo da Linguagem (Português/Vocabulário), respondendo a feedback real de que os desafios atuais são simples e repetitivos demais. O objetivo é criar um "método ativo": o jogador deve trabalhar de verdade para chegar à resposta, fixando por esforço regras gramaticais e ortográficas que o ensino escolar costuma tratar de forma superficial — não reconhecer a resposta certa por eliminação óbvia entre alternativas.

## 2. Diretrizes de curadoria de conteúdo

### 2.1 Menos reconhecimento, mais produção/dedução
- Reduzir a proporção de perguntas em que a resposta certa é reconhecível de forma óbvia entre as alternativas (ex.: 3 opções claramente erradas e 1 óbvia).
- Priorizar formatos que exijam mais raciocínio do jogador antes de conseguir eliminar alternativas — por exemplo, alternativas plausíveis entre si, exigindo conhecimento real da regra para diferenciar, não apenas familiaridade superficial com a palavra.

### 2.2 Foco em regras que a escola trata de forma rasa
Priorizar curadoria de conteúdo sobre temas gramaticais e ortográficos que costumam ser ensinados de forma superficial no ensino básico, e por isso geram dúvida recorrente mesmo entre adultos escolarizados — exemplos de categorias a explorar (lista ilustrativa, não exaustiva):
- Regência verbal e nominal (uso correto de preposições exigidas por verbos/nomes específicos).
- Crase (quando usar, quando não usar, casos facultativos vs. obrigatórios).
- Concordância verbal e nominal em casos menos óbvios (sujeito composto, expressões partitivas, "a maioria de").
- Uso correto de "porque/por que/porquê/por quê" e pares de palavras parecidas que geram confusão real (ex.: "mal/mau", "se não/senão", "há/a").
- Pontuação em casos que mudam sentido da frase (vírgula antes de "e" em certos contextos, uso de ponto e vírgula).
- Ortografia de palavras com grafia frequentemente confundida, além das já cobertas no vocabulário básico já existente.

### 2.3 Nível de esforço, não apenas nível de vocabulário
Diferente da curadoria por dificuldade já usada em outros blocos (baseada em quão comum é a palavra), aqui o critério de dificuldade deve ser **o esforço de raciocínio exigido para chegar à resposta certa**, mesmo quando o vocabulário envolvido é relativamente comum — a complexidade vem da regra gramatical em jogo, não da raridade da palavra.

## 3. Formato dos desafios

- Manter o formato de desafio já existente no Mundo da Linguagem (múltipla escolha, dentro da mecânica atual) — esta entrega não introduz um formato de resposta totalmente novo, é uma elevação de densidade e qualidade do conteúdo dentro do formato já validado.
- Feedback explicativo obrigatório em cada resposta (certa ou errada) deve, nesta leva, explicar a regra gramatical/ortográfica em jogo de forma clara — reforçando a fixação da regra pelo próprio ato de errar e entender o porquê, não apenas indicar a resposta certa.

## 4. O que NÃO muda nesta entrega

- Liberdade total de navegação do jogador — nenhuma trava de progressão sequencial é introduzida no Mundo da Linguagem ou em qualquer outro Mundo.
- Estrutura de dificuldade já existente (níveis 1/2/3) permanece — o conteúdo mais denso deve ser distribuído dentro dessa estrutura já validada, não criar uma categoria paralela.

## 5. Escopo técnico (alto nível — arquitetura detalhada a propor por Claude Code)

- Curadoria de novo lote de conteúdo seguindo as diretrizes da seção 2, para os territórios já existentes do Mundo da Linguagem.
- Nenhuma mudança de schema de dado é esperada, já que o formato de desafio (múltipla escolha + feedback explicativo) já existe — esta é primariamente uma entrega de conteúdo, não de arquitetura.

## 6. Critério de aceite

- Novo lote de conteúdo do Mundo da Linguagem reflete maior densidade de raciocínio exigido, com foco nas categorias gramaticais/ortográficas listadas na seção 2.2.
- Feedback explicativo de cada item ensina a regra em jogo, não apenas aponta a resposta certa.
- Liberdade de navegação do jogador permanece 100% intacta, sem nenhuma trava de progressão sequencial introduzida.

## 7. Implementação (06/09/2026)

30 desafios curados no território "palavras" (Mundo da Linguagem já
existente), cobrindo as 6 categorias da seção 2.2: regência
verbal/nominal (5), crase (5), concordância verbal/nominal (5), pares
confusos porque/por que/porquê/por quê + mal/mau + senão/se não + há/a
(6), pontuação (4) e ortografia (5). Mesmo formato de múltipla escolha
já validado no resto do app — nenhum campo/mecânica novo. Cada item tem
explicação que ensina a regra (não só aponta a resposta certa) e 2
dicas que nunca entregam a resposta, seguindo o padrão já estabelecido
em `backend/content/README.md`.

Carregado de `backend/content/linguagem_gramatica_densa.json` via
`app/seed.py` (mesmo padrão de idiomas/valores — nunca duplicado
inline). Validado com `scripts/validate_content.py` antes de integrar.

**Achado real durante a integração**: todo o lote nasce em
`difficulty_level=1`, de propósito — não por serem fáceis (a
"densidade" pedida está no raciocínio exigido pela regra, não no nível
declarado), mas porque o modo Palavras Relâmpago (território
"palavras", nível ≥ 2) sintetiza alternativas erradas a partir do
`correct_answer` de QUALQUER outro desafio do mesmo nível, assumindo
respostas curtas e intercambiáveis (antônimos, anagramas). As respostas
deste lote são frases completas específicas de cada pergunta —
apareceriam sem nexo nenhum como alternativa de uma pergunta
completamente diferente se entrassem em nível 2/3. Ver comentário
detalhado em `app/seed.py` e `tests/test_linguagem_gramatica_densa_content.py`
(regressão que garante que o lote nunca é servido no modo Relâmpago).

Testes: `tests/test_linguagem_gramatica_densa_content.py` (volume,
difficulty_level=1, nunca servido no Relâmpago, fluxo de resposta
normal).

### 7.1 Segundo lote: vocabulário avançado/jargão (100 palavras)

Curadoria própria de Rhoney (`palavras_dificeis_bloco{1..4}.json`, raiz
do repo — 4 blocos de 25 palavras, geral/jurídico/política/negócios),
convertida por `scripts/convert_palavras_dificeis_content.py` em
`backend/content/linguagem_vocabulario_avancado.json` e carregada no
mesmo território "palavras" via o mesmo glob `linguagem_*.json` de
`app/seed.py` — nenhuma mudança adicional de código precisou ser feita
além do script de conversão, já se encaixa na entrega da seção 7.

Duas variantes alternadas no arquivo fonte: (A) "O que significa
'PALAVRA'?" com definições como alternativas; (B) contexto descritivo
sem citar a palavra, com palavras candidatas como alternativas — o
contexto vira parte do próprio campo `prompt` (mesmo padrão já usado no
território "textos", sem campo novo), porque a pergunta sozinha ("A
palavra é:") se repete em todo item formato B e violaria a unicidade de
prompt por território. Mesma trava de `difficulty_level=1` do primeiro
lote e pelo mesmo motivo (respostas do formato A são definições
completas, incompatíveis com a síntese de alternativas do Palavras
Relâmpago).

Testes: `tests/test_linguagem_vocabulario_avancado_content.py` (volume,
difficulty_level=1, nunca servido no Relâmpago, fluxo de resposta
normal).

### 7.2 Terceiro lote: interpretação de texto (100 textos originais)

Curadoria própria de Rhoney (`interpretacao_textos_bloco{1..4}.json`,
raiz do repo — 4 blocos de 25 textos curtos originais + pergunta,
nenhum trecho de fonte externa reproduzido), convertida por
`scripts/convert_interpretacao_textos_content.py` em
`backend/content/linguagem_interpretacao_textos.json` e carregada no
território "textos" já existente (V2 item 3) — o texto-base entra
dentro do próprio campo `prompt` (mesmo padrão já usado no resto do
território), sem nenhum campo novo.

`difficulty_level=1` em todo o lote (compreensão literal — a resposta
está sempre dita de forma direta no texto, conferido por amostragem
manual), mesmo critério já usado nos itens de nível 1 pré-existentes
deste território. Diferente do território "palavras", aqui não há
trava de Relâmpago: "textos" sempre reaproveita as próprias opções
curadas no modo relâmpago, sem sintetizar nada a partir de outras
perguntas.

Testes: `tests/test_linguagem_interpretacao_textos_content.py` (volume,
prompt inclui o texto-base, fluxo de resposta normal).

**Suíte backend completa após os três lotes: 342/342.**
