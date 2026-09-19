# MENTAL — Mundo dos Idiomas: Imersão Progressiva por Nível de Dificuldade

**Status:** PARCIALMENTE IMPLEMENTADO (19/09/2026). Aplica-se a **todos os idiomas** do Mundo dos Idiomas (Inglês, Espanhol, Francês, e demais futuros), não apenas ao Inglês. Integra-se estruturalmente aos níveis de dificuldade já existentes no MENTAL e à mecânica de Constelação de Palavras já formalizada.

## Decisões e levantamento confirmados com Rhoney (19/09/2026)

- Mapeamento do §2 aprovado como proposto.
- **Achado de levantamento (§6/§7 — antes de qualquer implementação):** `Challenge.difficulty_level` é inteiro 1–5 no backend, mas o conteúdo real do Mundo dos Idiomas hoje só usa 3 níveis, um por território inteiro (não misturado dentro do território): `*_basico`=1, `*_intermediario`=2, `*_avancado`=3. Não existe conteúdo em nível 4/5. Rhoney aprovou mapear **basico=Fácil, intermediario=Média, avancado=Difícil**, deixando "Muito Difícil" definido na estrutura mas sem conteúdo por enquanto (sem recriação em massa agora).
- Ao investigar o que dá pra implementar sem criar/curar conteúdo novo, dois dos quatro sinais da tabela do §2 **já existiam de fato para todos os níveis** (não eram level-gated): alternativas já são sempre no idioma-alvo (decorre dos 2 templates fixos de prompt, ver MUNDO_IDIOMAS_CONSTELACAO_PALAVRAS_V1.md) e o botão de áudio por alternativa já existe desde a Fase 1 de MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md. Não foi preciso codar nada novo pra esses dois itens.
- Os outros dois sinais do §2 — **pergunta totalmente no idioma-alvo** (Difícil/Muito Difícil) e **imagem ilustrativa** (Média) — exigem conteúdo novo (tradução/curadoria por item) que não existe hoje. **Não implementados nesta rodada** — ficam pendentes de uma fase de curadoria de conteúdo separada, a ser escopada com Rhoney.

## O que foi implementado (19/09/2026)

- Constelação de Palavras agora recebe o `difficulty_level` do Desafio de origem (`challenge_screen.dart` → `WordConstellationScreen.difficultyLevel`, sem mudança de backend, o campo já vinha no payload do Desafio) e aplica a regra do §5: a partir do nível avançado (Difícil, `difficulty_level >= 3`), a instrução em português (`wordConstellationInstructionLabel`) some da tela — nunca "regride" pra português depois de um Desafio já em imersão.
- Testes: `client/test/word_constellation_screen_test.dart` — 2 novos testes (instrução aparece em `difficultyLevel < 3`, some em `difficultyLevel == 3`).

## Pendente (não implementado, requer decisão/curadoria de conteúdo)

- Pergunta 100% no idioma-alvo para o território `avancado` (Difícil) — precisa de tradução/curadoria por item, não é tarefa de código.
- Imagem ilustrativa para `intermediario` (Média) — mesma observação; usaria o campo `prompt_image` (emoji, catálogo zero-custo) já existente no modelo `Challenge`, mas sem conteúdo curado ainda.
- Relatório formal de adequação do conteúdo já existente (§7) — o levantamento acima já cobre a parte estrutural (3 níveis reais x 4 do documento); o levantamento item-a-item de qual pergunta específica precisaria de tradução/imagem ainda não foi feito, fica pra quando essa fase de curadoria for escopada.

---

## 1. Princípio pedagógico

O Mundo dos Idiomas passa a seguir um princípio de **imersão progressiva**: conforme o nível de dificuldade do Desafio aumenta, a dependência da língua portuguesa diminui, até chegar em imersão total no idioma estudado (pergunta, alternativas e áudio, tudo no idioma-alvo). Isso segue prática pedagógica reconhecida no ensino de idiomas — apoio inicial na língua materna, transição por reforço visual, e consolidação em imersão completa.

## 2. Mapeamento aos níveis de dificuldade já existentes (proposta, a validar por Rhoney)

O MENTAL já usa a estrutura Fácil / Média / Difícil / Muito Difícil em todos os Mundos. A proposta de mapeamento dos três mecanismos descritos por Rhoney para essa régua de quatro níveis é:

| Nível | Formato da pergunta | Formato das alternativas | Áudio |
|---|---|---|---|
| **Fácil** | Em português | Em inglês/idioma-alvo | Opcional, reforço |
| **Média** | Com imagem ilustrativa (apoio visual, reduzindo dependência de tradução literal) | No idioma-alvo | Opcional, reforço |
| **Difícil** | Totalmente no idioma-alvo | Totalmente no idioma-alvo | Botão de áudio em cada alternativa |
| **Muito Difícil** | Totalmente no idioma-alvo, sem apoio de imagem (exige recordação ativa, não reconhecimento visual) | Totalmente no idioma-alvo | Botão de áudio em cada alternativa |

**Esta tabela é uma proposta de interpretação de Claude para encaixar os 3 mecanismos descritos por Rhoney nos 4 níveis já existentes — deve ser validada explicitamente por Rhoney antes da implementação, podendo ser ajustada (ex.: trocar a diferença entre Difícil e Muito Difícil por outro critério, se Rhoney preferir).**

## 3. Escopo — todos os idiomas

- Este princípio de imersão progressiva é uma **regra estrutural do Mundo dos Idiomas como um todo**, não uma característica exclusiva da trilha de Inglês.
- Aplica-se a todos os idiomas já existentes e a qualquer idioma futuro adicionado ao Mundo dos Idiomas, seguindo a mesma arquitetura genérica por idioma já definida em MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md.
- Libras é uma exceção natural a este documento por não ter componente sonoro nem "idioma-alvo" no sentido falado — este princípio de imersão progressiva por texto/áudio não se aplica a Libras, que segue sua própria especificação (vídeo/GIF).

## 4. Áudio nas alternativas — Difícil e Muito Difícil

- A partir do nível Difícil, **cada uma das alternativas de resposta tem seu próprio botão de áudio individual**, não apenas o enunciado da pergunta.
- Isso significa, numa pergunta de múltipla escolha com 4 alternativas nesses níveis, até 5 pontos de áudio possíveis (enunciado + 4 alternativas), todos seguindo a mesma regra já definida: reprodução apenas sob clique explícito, com as 3 velocidades (normal, rápido, acelerado) disponíveis em cada um.

## 5. Integração com a Constelação de Palavras

- A mecânica de Constelação de Palavras (MUNDO_IDIOMAS_CONSTELACAO_PALAVRAS_V1.md), que já aparece como etapa complementar ao final de cada Desafio, deve **refletir o nível de imersão do Desafio de origem**:
  - Em Desafios de nível Fácil/Média, a Constelação de Palavras pode manter algum apoio em português (ex.: instrução em português, vocabulário no idioma-alvo).
  - Em Desafios de nível Difícil/Muito Difícil, a Constelação de Palavras passa a ser **também totalmente no idioma-alvo** — sem instrução em português, mantendo a imersão completa até o final do ciclo daquele Desafio.
- Isso garante consistência de experiência: o usuário não regride para português na etapa complementar depois de ter acabado de praticar em imersão total no Desafio principal.

## 6. Escopo técnico (a propor em detalhe por Claude Code)

- Validar com Rhoney o mapeamento da seção 2 antes de iniciar qualquer implementação.
- Modelar a estrutura de dados de perguntas do Mundo dos Idiomas para suportar, por nível de dificuldade: idioma do enunciado, idioma das alternativas, presença ou ausência de imagem ilustrativa, e presença de áudio por alternativa — de forma genérica por idioma, reaproveitando a arquitetura já definida.
- Adaptar o componente de Constelação de Palavras para respeitar o nível de imersão do Desafio de origem, conforme seção 5.
- Levantar o conteúdo já existente no Mundo dos Idiomas (perguntas já publicadas) e reportar a Rhoney quanto desse conteúdo já atende à nova estrutura de imersão progressiva e quanto precisa ser adaptado ou recriado — não presumir que o conteúdo antigo já está adequado sem essa checagem.

## 7. Critério de aceite

- Rhoney validou o mapeamento de níveis proposto na seção 2 (ou forneceu um mapeamento ajustado) antes de qualquer implementação.
- Cada nível de dificuldade do Mundo dos Idiomas segue o formato de imersão correspondente, em todos os idiomas do Mundo.
- A partir do nível Difícil, cada alternativa de resposta tem botão de áudio próprio e funcional.
- Constelação de Palavras reflete o nível de imersão do Desafio de origem, sem regredir para português em Desafios de nível Difícil/Muito Difícil.
- Relatório de adequação do conteúdo já existente entregue a Rhoney antes de qualquer recriação em massa de conteúdo antigo.
