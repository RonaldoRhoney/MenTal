# MENTAL — Caça-palavras: Correção de Palavras Inválidas e Redesenho Visual de Palavras Encontradas

**Status:** CONCLUÍDO (18/09/2026). Escopo aplica-se a **todo o desafio de Caça-palavras como tipo/mecânica**, não apenas à sessão específica analisada (tema "Corpo Humano").

## Conclusão — resumo executivo

- **Item 1 (bug OLHO)**: falso alarme, não bug real — ver seção 1 abaixo. Rodei o validador oficial (`content_validation.validate_word_puzzles`, que já existia e já roda em todo conteúdo carregado via `scripts/append_word_puzzles.py`) contra as 8 sessões de Caça-palavras do app: **zero erros**. Conferi "OLHO" manualmente, letra por letra, contra o print da tela real que Rhoney mandou — existe na diagonal, e o código de seleção do jogo (`word_search_screen.dart::_onPanEnd`) já suporta as 8 direções e os dois sentidos de leitura. Nenhuma correção de código necessária.
- **Item 2 (redesenho visual)**: implementado — ver seção 2 abaixo.

---

## 1. Bug confirmado — palavra inexistente na grade

### 1.1 Caso identificado
Na sessão de Caça-palavras "Corpo Humano" (print anexado por Rhoney), a palavra **OLHO**, listada no banco de palavras do desafio, **não existe em nenhuma linha reta válida da grade** (horizontal, vertical ou diagonal, em qualquer sentido). A única ocorrência da letra "H" na grade forma a sequência "O-H-L-O" ao redor dela, não "O-L-H-O" — as letras L e H aparecem trocadas de posição em relação à palavra que deveria estar codificada.

As demais 11 palavras da mesma sessão (CORAÇÃO, PULMÃO, FÍGADO, CÉREBRO, ESTÔMAGO, RIM, OSSO, MÚSCULO, SANGUE, PELE, NARIZ) foram verificadas manualmente e **existem corretamente** na grade.

### 1.2 Escopo da correção — não é um caso isolado
Rhoney determinou explicitamente que esta verificação e correção deve cobrir **todos os desafios de Caça-palavras já publicados no MENTAL**, em todos os Mundos/territórios que usam essa mecânica — não apenas a sessão "Corpo Humano" analisada.

### 1.3 O que deve ser feito
- Levantar todas as sessões de Caça-palavras existentes no banco de dados/conteúdo do app.
- Para cada sessão, validar programaticamente que **todas as palavras do banco de palavras realmente existem na grade**, percorrendo as 8 direções possíveis (horizontal esquerda/direita, vertical cima/baixo, e as 4 diagonais) a partir de cada célula.
- Reportar a Rhoney a lista completa de sessões com problemas semelhantes encontrados (palavra ausente, ou presente com letras trocadas/incorretas), antes de corrigir, para que ele tenha visibilidade da extensão real do problema.
- Corrigir cada grade problemática, garantindo que a palavra passe a existir corretamente — e revalidar após a correção com o mesmo processo automático.
- Investigar a causa raiz na lógica de **geração das grades de Caça-palavras** (é provável que o bug esteja no algoritmo gerador, não em cada grade individualmente — nesse caso, corrigir a causa raiz evita que o mesmo problema volte a aparecer em conteúdo futuro).

## 2. Melhoria visual — tratamento de palavras encontradas

### 2.1 Problema atual
Hoje, ao encontrar uma palavra, o único feedback visual é o nome da palavra na lista abaixo da grade recebendo um **risco (strikethrough) numa cor neutra/cinza**, igual para todas as palavras. Rhoney descreve esse tratamento como "muito neutro e apático", sem nenhuma sensação de conquista ou dinamismo — abaixo do padrão esperado para um desafio "nível profissional".

### 2.2 O que precisa mudar
- **Cada palavra encontrada deve receber uma cor própria e distinta**, tanto na grade (destacando visualmente as letras daquela palavra específica) quanto na lista de palavras abaixo — não mais um cinza uniforme para todas.
- Aplicar **efeitos de dinamismo** ao encontrar uma palavra: animação de destaque no momento da descoberta (ex.: leve "pulso", brilho, ou traço sendo desenhado sobre as letras encontradas na grade), reforçando a sensação de conquista.
- O conjunto de cores usado deve ser harmonioso com a identidade visual já estabelecida no MENTAL (mesma paleta usada em outros elementos de conquista do app), não cores aleatórias sem curadoria.
- Esse redesenho, assim como a correção do item 1, aplica-se a **todo o desafio de Caça-palavras como mecânica**, não a uma sessão isolada — é uma mudança no componente reutilizável usado por todas as sessões dessa categoria.

### 2.3 O que foi implementado
- `client/lib/screens/word_search_screen.dart` — paleta curada de 10 cores (`_kWordColors`, mesma família de tons do Mapa de Trajetória: `AppColors.gold/teal/purple/victory` + coral/rosa/ciano/lilás/verde/azul), atribuída por índice da palavra na sessão (determinística, cicla se houver mais de 10 palavras).
- `_foundCells` deixou de ser um `Set<_CellPos>` genérico e virou `Map<_CellPos, String>` (célula → palavra dona), pra cada letra encontrada na grade saber de quem puxar a cor.
- Pulso de destaque no momento da descoberta: `_justFoundCells` marca as células recém-encontradas, disparando `AnimatedScale` (1.0 → 1.28 → 1.0, ~480ms no total) só uma vez por descoberta, mais `AnimatedContainer` pra transição suave da cor de fundo.
- Lista de palavras: `Chip` de cada palavra encontrada ganha borda/texto na cor própria + ícone de check (`Icons.check_circle_rounded`) — acessibilidade (§3 do doc): a distinção nunca depende só de cor, o risco (strikethrough) e o ícone continuam sendo o sinal principal.
- Testes: `client/test/word_search_screen_test.dart` (2 testes — palavra não encontrada sem risco/ícone; arrastar sobre a palavra na grade marca risco + ícone, simulando o gesto real via `TestGesture`).

## 3. Escopo técnico (a propor em detalhe por Claude Code)

- Implementar (ou revisar, se já existir) a função de validação de palavra-em-grade percorrendo as 8 direções, para uso tanto na auditoria de conteúdo existente quanto, idealmente, como validação automática no momento da geração de qualquer novo Caça-palavras futuro (evitando que o bug se repita).
- Redesenhar o componente visual de "palavra encontrada" no Flutter, incluindo paleta de cores distintas por palavra e a animação de destaque no momento da descoberta.
- Considerar acessibilidade: garantir contraste suficiente entre as cores escolhidas e o fundo, e que a distinção entre palavras não dependa exclusivamente de cor (para usuários com daltonismo), complementando com algum outro indicador visual se necessário.

## 4. Critério de aceite

- Todas as sessões de Caça-palavras do app auditadas, com relatório de quais tinham palavras inválidas na grade.
- Todas as grades problemáticas corrigidas e revalidadas.
- Causa raiz do bug investigada e, se estiver no gerador, corrigida para prevenir recorrência em conteúdo futuro.
- Cada palavra encontrada, em qualquer sessão de Caça-palavras do app, exibe cor própria e distinta, com efeito de destaque ao ser descoberta.
- Tratamento visual aplicado de forma consistente a todo o tipo de desafio, não a uma sessão isolada.
