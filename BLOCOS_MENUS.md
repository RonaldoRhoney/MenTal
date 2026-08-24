# MENTAL — Blocos (Menus de Navegação)

**Status:** Aprovado para implementação.
**Documentos relacionados:** V2_KICKOFF.md (item 10 — Mundos), PALAVRAS_RELAMPAGO.md, CONHECIMENTO_CONTEUDO_GERAL_E_IMAGEM.md

---

## 1. Conceito

**Bloco = menu de navegação/organização visual.** Não é uma camada de jogo, não afeta XP, conquista, badge nem qualquer mecânica de progressão — é puramente uma forma de agrupar territórios na tela pra evitar que tudo apareça solto numa lista única, à medida que novos territórios forem adicionados.

**Não confundir com Mundo:** Mundo (já existente — Linguagem / Mente Lógica) continua sendo a camada de progressão/conquista real (derivada de UserTerritoryProgress, com bônus e badge por completar). Bloco é só organização de menu — as duas camadas coexistem, sem se sobrepor.

---

## 2. Hierarquia

```
MUNDO (progressão/conquista — já existente)
  └─ BLOCO (menu de navegação — novo, só organização visual)
       └─ TERRITÓRIO (onde o desafio de fato acontece)
            └─ Relâmpago (modo extra de múltipla escolha com tempo, dentro do território, quando aplicável)
```

---

## 3. Blocos definidos

| Bloco | Territórios |
|---|---|
| **Matemática** | Números, Lógica (já existentes) |
| **ENEM** | Território(s) novo(s), conteúdo curado no estilo das matérias cobradas no ENEM |
| **Concursos** | Território(s) novo(s), conteúdo curado no estilo de prova de concurso público |
| **Regiões** | Território novo, cultura/curiosidades regionais do Brasil |
| **Mundo** | Território novo, geografia/história/cultura internacional (fora do Brasil) |

Territórios já existentes que não entraram explicitamente em um Bloco acima (Palavras, Textos, Enigmas, Visual, Conhecimento) permanecem acessíveis normalmente — a decisão de encaixá-los em algum Bloco existente ou mantê-los fora da organização de menu fica para refinamento posterior, sem bloquear a implementação dos Blocos novos.

---

## 4. Relâmpago dentro de cada território

Cada território (dentro de qualquer Bloco) pode oferecer, além do conteúdo no formato próprio dele, uma opção de desafio **Relâmpago** — reaproveitando 100% o mecanismo já definido em PALAVRAS_RELAMPAGO.md (múltipla escolha, tempo escalonado por nível, timeout suave, bônus de XP por velocidade).

---

## 5. Escopo técnico (alto nível — arquitetura detalhada a propor por Claude Code)

- Blocos são uma camada de apresentação — provável necessidade de uma tabela simples (`blocks`) com relação a territórios, mas sem qualquer lógica de progressão/conquista associada (diferente de `worlds`, que tem derivação de conquista).
- Territórios novos (ENEM, Concursos, Regiões, Mundo) seguem o mesmo padrão de curadoria de conteúdo já usado no restante do MENTAL — critério de conteúdo factualmente estável, mesma disciplina de curadoria já estabelecida em CONHECIMENTO_CONTEUDO_GERAL_E_IMAGEM.md.
- Nenhuma mudança na arquitetura de Mundos, XP ou badges — Blocos não interferem nessas camadas.

---

## 6. Fora de escopo agora

- Conteúdo específico de cada território novo (ENEM, Concursos, Regiões, Mundo) ainda não foi curado — este documento define a estrutura de organização, não o conteúdo em si.
- Decisão sobre onde encaixar os territórios já existentes que não foram mencionados explicitamente (Palavras, Textos, Enigmas, Visual, Conhecimento) fica pendente de refinamento futuro.
