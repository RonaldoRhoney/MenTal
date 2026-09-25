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

**Achado real durante a integração (06/09/2026)**: o lote nasceu em
`difficulty_level=1` fixo, por um receio infundado de que o modo
Palavras Relâmpago sintetizasse alternativas erradas a partir do
`correct_answer` de outro desafio do mesmo nível
(`services.generate_relampago_options`) — mas essa síntese só é
acionada quando `challenge.options is None` (`routers/challenges.py`),
e este lote sempre teve as 4 opções curadas preenchidas. O pin nunca
protegia nada.

**BUG_LINGUAGEM_NAO_APARECE (corrigido em 06/09/2026)**: efeito
colateral real do pin: `/challenges/next` só cai pro nível calculado
adaptativamente pro jogador, e só usa "qualquer nível" como fallback
quando não existe NENHUM desafio no nível calculado — como "palavras"
já tinha conteúdo antigo nos níveis 2 e 3, qualquer jogador além do
nível 1 nunca recebia este lote (nem os dois seguintes, mesmo pin).
Corrigido redistribuindo (round-robin por índice) os 30 itens entre os
níveis 1/2/3, igual a qualquer outro conteúdo de "palavras" — os itens
de nível 2/3 aparecem normalmente no Relâmpago agora, sempre com suas
próprias opções reais (nunca sintetizadas). Ver `scripts/
fix_linguagem_difficulty_levels.py` (UPDATE em produção, idempotente).

Testes: `tests/test_linguagem_gramatica_densa_content.py` (volume,
difficulty_level em {1,2,3}, Relâmpago serve nível 2/3 com opções
reais, fluxo de resposta normal).

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
prompt por território. Mesmo achado e mesma correção do primeiro lote
(BUG_LINGUAGEM_NAO_APARECE, seção 7 acima): options sempre curadas
(nunca None), então redistribuído entre níveis 1/2/3 via `scripts/
fix_linguagem_difficulty_levels.py`.

Testes: `tests/test_linguagem_vocabulario_avancado_content.py` (volume,
difficulty_level em {1,2,3}, Relâmpago serve nível 2/3 com opções
reais, fluxo de resposta normal).

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

---

## 8. SubMundo "Palavras Raras" (20/09/2026, pedido de Rhoney)

Fonte: `100_palavras_raras_portugues.json` (esta pasta) — 100 palavras raras/pouco usuais em 10 áreas de 10, com significado resumido (seleção temática, não um ranking estatístico; a própria fonte manda conferir a acepção em Priberam, Michaelis ou Caldas Aulete — a explicação de cada desafio traz esse aviso).

**Estrutura** (mesmo mecanismo de Bloco do SubMundo Internet em Tecnologia, `ARQUITETURA_SUBMUNDOS_V1.md` — nenhuma entidade nova): Bloco `palavras_raras` ("Palavras Raras", subcabeçalho no Mundo da Linguagem) com **10 territórios**, um por área: `palavras_raras_filosofia`, `_psicologia`, `_medicina`, `_fisica_quimica`, `_matematica`, `_linguistica`, `_historia`, `_geografia`, `_direito`, `_eruditas` (display_order 86–95). Migration: `backend/migrations/087_submundo_palavras_raras_em_linguagem.sql`.

**Conteúdo**: `scripts/convert_palavras_raras_content.py` gera `backend/content/linguagem_palavras_raras_<area>.json` — **200 desafios** (20 por território), todos `difficulty_level=3` (decisão de Rhoney), 2 dicas que não entregam a resposta, `options` sempre curadas (o Relâmpago usa as opções como estão, nada é sintetizado). Cada palavra vira duas perguntas:
- (A) "Qual é o significado de 'X'?" — 4 significados: o certo + 3 de outras palavras da MESMA área, escolhidos entre os 5 de tamanho mais parecido (evita o viés "a opção mais longa é a certa");
- (B) "Qual palavra corresponde a este significado: «…»?" — 4 palavras da mesma área.
As duas direções existem também por exigência do critério de volume (≥ 15 itens por território, `test_content_volume.py`): 10 palavras por área não bastariam. Distratores nunca são inventados; sorteio com semente fixa (geração reproduzível).

**Efeito colateral a saber**: os 10 territórios pertencem ao Mundo da Linguagem, então o Mundo só volta a contar como "completo" depois de conquistar também esses territórios (mesmo comportamento de quando os SubMundos foram adicionados a Tecnologia e Esportes).

Testes: `tests/test_linguagem_palavras_raras_content.py` (estrutura, 200 desafios, duas direções conferidas contra o arquivo fonte, distratores só da mesma área, viés de tamanho) + `test_content_volume.py`, `test_blocks.py`, `test_worlds.py`.

---

## 9. SubMundos de gramática (20/09/2026, pedido de Rhoney)

Fonte da decisão: `MUNDO_LINGUAGEM_ARQUITETURA_V1.md` (19 temas: Crase, Preposição, Regência Verbal/Nominal, Concordância Verbal/Nominal, Colocação Pronominal, Pronomes, Pontuação, Ortografia, Acentuação Gráfica, Numerais, Interjeições, Morfologia, Sintaxe, Semântica, Orações Coordenadas e Subordinadas, Figuras de Linguagem, Interpretação de Texto).

**Estrutura** (mesmo mecanismo de Bloco do SubMundo Internet): cada tema é um SubMundo (bloco `lg_<slug>`) com **1 território** `linguagem_<slug>` de 50 perguntas — 25 de nível 1, 15 de nível 2 e 10 de nível 3 (o Desafio serve todos os níveis; o Relâmpago só 2 e 3). O plano completo fica em `backend/content/plano_temas_linguagem.json`; **só temas com `status: "ativo"` são registrados** (seed, migration, app) — um território sem conteúdo aprovado daria erro no app.

**Fluxo de um tema novo**: (1) lote curado em `MUNDO/Mundo_da_Linguagem/temas/<slug>_lote<N>.json` (perguntas originais, sem cópia de fonte; revisão obrigatória de Rhoney); (2) `python3 scripts/convert_linguagem_tema_content.py <slug>` gera `backend/content/linguagem_tema_<slug>.json`; (3) marcar o tema `ativo` no plano; (4) migration do bloco+território (modelo: `088_submundo_crase_em_linguagem.sql`); (5) `scripts/append_production_content.py`; (6) registrar o território no client (`territories.dart` + `app_pt.arb`); (7) AAB novo.

**Lote 1 — Crase**: 50 perguntas originais (`temas/crase_lote1.json`), aguardando revisão de Rhoney. Migration `088`. Testes: `tests/test_linguagem_temas_content.py`.

**Lote 1 — Morfologia** (2º SubMundo, 1º na ordem de produção da seção 5): 50 perguntas originais (`temas/morfologia_lote1.json`) sobre classes de palavras, flexão (gênero, número, grau), coletivos, formação de palavras (prefixo, sufixo, justaposição, aglutinação, derivações) e formas verbais — aguardando revisão de Rhoney. Migration `089`, carga `content/linguagem_tema_morfologia.json`.

**Lote 1 — Interpretação de Texto** (3º SubMundo, 2º na ordem da seção 5): 50 perguntas sobre 10 textos curtos originais (5 perguntas por texto: literal, vocabulário no contexto, inferência, finalidade) em `temas/interpretacao_de_texto_lote1.json`, com o texto dentro do próprio prompt (padrão do território "textos"). Aguardando revisão de Rhoney. Migration `090`, carga `content/linguagem_tema_interpretacao_de_texto.json`. **Decisão pendente:** o Relâmpago (20 s) com um texto de ~60 palavras é apertado — manter conforme o documento (25+25) ou marcar o território como "nunca cronometrado" (como as cápsulas de Valores/Trânsito).

**Lote 1 — Concordância Verbal** (4º SubMundo, 3º na ordem da seção 5): 50 perguntas (`temas/concordancia_verbal_lote1.json`): sujeito simples e composto, coletivos, `mais de um`, `um dos que`, `que`/`quem`, `haver`/`fazer` impessoais, horas com `ser`, `se` apassivador e índice de indeterminação, `cerca de`, `nem... nem`, sujeito posposto. Em todo "Complete", as opções estão no mesmo tempo verbal, para que só a concordância diferencie. Aguardando revisão de Rhoney. Migration `091`, carga `content/linguagem_tema_concordancia_verbal.json`.

**Lote 1 — Concordância Nominal** (5º SubMundo, também do 3º item da seção 5): 50 perguntas (`temas/concordancia_nominal_lote1.json`): concordância de artigo/adjetivo/numeral/pronome com o substantivo, sujeito composto de gêneros diferentes, e os casos especiais (`meio`, `obrigado`, `anexo`, `bastante`, `mesmo/próprio`, `menos`, `só`, `quite`, `é proibido/é necessário`, adjetivos compostos, `Vossa Excelência`, `lesa-pátria`). Aguardando revisão de Rhoney. Migration `092`, carga `content/linguagem_tema_concordancia_nominal.json`.

**Lote 1 — Regência Verbal** (6º SubMundo, 4º item da seção 5): 50 perguntas (`temas/regencia_verbal_lote1.json`) sobre a preposição que cada verbo exige: `obedecer a`, `preferir a`, `chegar/ir a`, `morar/residir em`, `simpatizar/concordar/casar-se com`, `confiar/insistir em`, `gostar/precisar/desistir de`, `assistir a` (ver), `aspirar a` (desejar) contra `aspirar` (respirar), `esquecer/lembrar` (direto) contra `esquecer-se/lembrar-se de`, `custar`, `implicar`, relativos (`ao qual`, `de que`, `em que`). Evitei os casos em que as gramáticas divergem (`visar`, `informar`, `pagar`). Aguardando revisão de Rhoney. Migration `093`, carga `content/linguagem_tema_regencia_verbal.json`.

**Lote 1 — Regência Nominal** (7º SubMundo, fecha o 4º item da seção 5): 50 perguntas (`temas/regencia_nominal_lote1.json`) sobre a preposição que substantivos e adjetivos exigem: `acesso a`, `favorável/contrário a`, `fiel a`, `capaz de`, `medo de`, `orgulhoso/suspeito de`, `diferente de`, `igual/semelhante/anterior/superior/inferior/posterior/paralelo a`, `responsável/ansioso/apaixonado por`, `grato a` (pessoa) contra `grato por` (coisa), `imune/alheio/insensível a`, `compatível/generosa com`, `pronto/impróprio para`. Evitei termos com mais de uma preposição aceita (`apto a/para`, `satisfeito com/de`, `respeito a/por`, `próximo a/de`). Aguardando revisão de Rhoney. Migration `094`, carga `content/linguagem_tema_regencia_nominal.json`.

**Lote 1 — Colocação Pronominal** (8º SubMundo, 6º item da seção 5): 50 perguntas (`temas/colocacao_pronominal_lote1.json`): próclise (palavra negativa, pronome relativo/indefinido/interrogativo, conjunção subordinativa, advérbio `talvez`/`ainda`/`como`, oração optativa), ênclise (verbo no início, imperativo afirmativo, gerúndio) e mesóclise (futuro do presente e do pretérito no início da frase), além de particípio (pronome junto ao auxiliar), `lo/la` depois de r/s/z e `Trata-se`/`Dir-se-ia`. Evitei os casos em que a norma admite mais de uma colocação (advérbio sem pausa, sujeito expresso, locução com infinitivo). Aguardando revisão de Rhoney. Migration `097`, carga `content/linguagem_tema_colocacao_pronominal.json`.

**Lote 1 — Pronomes** (9º SubMundo, também do 6º item da seção 5): 50 perguntas (`temas/pronomes_lote1.json`): pessoais (reto x oblíquo, `para eu fazer`, `entre mim e você`, `comigo/consigo/conosco`), possessivos, demonstrativos (este/esse/aquele, `aquele` x `este` ao retomar termos), relativos (`cujo`, `onde`, `quem`, `de que`), indefinidos, interrogativos, pronomes de tratamento (`Vossa` x `Sua`) e função sintática de `o/lhe/se` (`Vendem-se`, `Precisa-se`, `arrepender-se`), `que` relativo x conjunção. Aguardando revisão de Rhoney. Migration `097` (junto com Colocação Pronominal), carga `content/linguagem_tema_pronomes.json`. **Pendente na ordem da seção 5:** `Preposição` (5º item) segue como `planejado`.

**Lote 1 — Preposição** (10º SubMundo, fecha o 5º item da seção 5 junto da Crase): 50 perguntas (`temas/preposicao_lote1.json`): preposições essenciais x acidentais, contrações e combinações (`na`, `do`, `ao`, `pelas`, `daquele`, `nisto`), valores semânticos (meio, causa, posse, companhia, instrumento, finalidade, origem, matéria, ausência), locuções prepositivas (`perto de`, `apesar de`, `devido a`, `a fim de`, `a respeito de`, `ao invés de`), `há` x `a` em tempo, `sob`/`sobre`/`perante`/`após`/`contra`/`entre`, e a não-contração no sujeito do infinitivo (`na hora de o professor começar`). Evitei regência (já coberta). **Decisão de Rhoney:** `ao invés de` segue a norma tradicional (só oposição) — retirar se preferir. Migration `098`, carga `content/linguagem_tema_preposicao.json`.

**Lote 1 — Pontuação** (11º SubMundo, 7º item da seção 5): 50 perguntas (`temas/pontuacao_lote1.json`): vírgula (vocativo, enumeração, aposto, adversativas, orações explicativas x restritivas, elipse do verbo, `isto é`/`por exemplo`, não separar sujeito de verbo), dois-pontos, ponto e vírgula, ponto de interrogação/exclamação, reticências, travessão e discurso direto. Evitei vírgulas facultativas (adjunto adverbial curto, subordinada posposta, vírgula antes de `e` com sujeitos diferentes), onde as gramáticas divergem. Migration `099`, carga `content/linguagem_tema_pontuacao.json`.

**Lote 1 — Ortografia** (12º SubMundo, também do 7º item): 50 perguntas (`temas/ortografia_lote1.json`) seguindo o Acordo Ortográfico de 1990: 25 de grafia (s/ss/ç/x/ch/g/j, ex.: `exceção`, `privilégio`, `empecilho`, `obcecado`, `caranguejo`), 15 de palavras parecidas (`mas/mais`, `mau/mal`, `por que/porque/porquê/por quê`, `onde/aonde`, `sessão/seção/cessão`, `concerto/conserto`, `iminente/eminente`, `flagrante/fragrante`) e 10 combinando pares. Evitei grafias com variante aceita (`berinjela/beringela`, `susceptível`). Migration `099`, carga `content/linguagem_tema_ortografia.json`.

**Lote 1 — Acentuação Gráfica** (13º SubMundo, também do 7º item): 50 perguntas (`temas/acentuacao_grafica_lote1.json`): proparoxítonas, oxítonas (-a/-e/-o/-em), paroxítonas (-l/-r/-i/-is/-us/-um/-ão/ditongo), monossílabos tônicos, hiato (`saúde`, `país`, `cafeína`), ditongos abertos (`herói`, `papéis`, `chapéu`), o que mudou no Acordo (`ideia`, `assembleia`, `jiboia`, `voo`, `leem`, `veem`) e o acento diferencial que ficou (`pôr`, `pôde`). Evitei os casos facultativos (`fôrma/forma`, `dêmos/demos`). Migration `099`, carga `content/linguagem_tema_acentuacao_grafica.json`.
