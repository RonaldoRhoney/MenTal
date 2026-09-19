# MENTAL — Organização Visual por Seção/Idioma/Categoria em Todos os Mundos

**Status:** IMPLEMENTADO (19/09/2026). Escopo é **todos os Mundos do app**, não apenas o Mundo dos Idiomas. Reaproveita o princípio já estabelecido em ARQUITETURA_SUBMUNDOS_V1.md, aplicando-o também como padrão de organização visual/navegação, não apenas como estrutura de dados.

## Relatório de levantamento (§3, antes da implementação)

Não existe uma tela própria por Mundo — todos os Mundos de território/quiz passam pela MESMA tela genérica (`_WorldDetailScreen`/`_TerritoryGroup` em `client/lib/screens/home_screen.dart`), que já agrupa territórios por `block_id` desde BLOCOS_MENUS.md. Ou seja, o mecanismo de "seção com cabeçalho" **já era genérico e único** — o problema nunca foi "cada Mundo organiza diferente", e sim que o cabeçalho em si (§2.1.1) era visualmente fraco (rótulo cinza 12px) e que **3 blocos de conteúdo específicos nunca tinham ganhado `block_id`**:

- Inglês/Espanhol/Francês (Mundo dos Idiomas) — os 9 territórios apareciam soltos numa grade única, misturados. Libras, Internet (Tecnologia), Futebol e Copa do Mundo (Esportes) já tinham `block_id` e já apareciam corretamente separados.
- Nenhum outro Mundo do app foi encontrado com essa mesma mistura — os demais ou são de categoria única (sem necessidade de seção) ou já usam Bloco corretamente.

Conclusão prática: não havia necessidade de "reorganizar Mundo por Mundo" — bastava (1) dar `block_id` a Inglês/Espanhol/Francês e (2) melhorar o componente de cabeçalho UMA vez, já que é compartilhado por todos os Mundos automaticamente.

## O que foi implementado

- `backend/migrations/080_blocos_idiomas.sql` + `backend/app/seed.py` — 3 blocos novos (`ingles`/`espanhol`/`frances`), com os 9 territórios de Idiomas recebendo `block_id` (puramente organizacional, mesmo padrão de `migrations/072/074/076` — nenhuma mudança de progresso/XP/navegação).
- `client/lib/screens/home_screen.dart::_SectionHeader` (§4, componente reutilizável) — substitui o rótulo cinza por: ícone temático por `block_id` (registro explícito `_kSectionIcons`, com fallback genérico pra bloco não mapeado), tipografia `titleMedium` em negrito, e uma linha de destaque em gradiente dourado. Usado automaticamente por QUALQUER Bloco/SubMundo em qualquer Mundo, já que `_TerritoryGroup` é compartilhado.
- Testes: `backend/tests/test_blocks.py` (novo teste dos 3 blocos de Idiomas + ajuste do teste de contagem total de blocos); suíte completa backend+client sem regressão.

---

## 1. Problema identificado

No print da tela do Mundo dos Idiomas (analisado com Rhoney em 19/09/2026), o conteúdo aparece numa grade contínua de 2 colunas, misturando Inglês, Espanhol e Francês sem nenhuma separação visual clara — os três idiomas ficam lado a lado, exigindo que o usuário identifique a qual idioma cada card pertence só pelo nome escrito nele. **Apenas Libras aparece corretamente separado**, com um rótulo de seção próprio ("Libras") acima de seu conteúdo.

Esse padrão de mistura sem organização clara provavelmente se repete em outros Mundos do app, não apenas no dos Idiomas.

## 2. O que precisa mudar

### 2.1 Princípio geral
Todo Mundo do MENTAL deve organizar seu conteúdo em **seções claramente identificadas por título/cabeçalho**, agrupando tudo que pertence a uma mesma categoria/idioma/tema — seguindo o mesmo exemplo que Libras já demonstra corretamente hoje. Cada seção reúne seu conteúdo completo (níveis de dificuldade, Relâmpago correspondente, e qualquer outro elemento associado) de forma visualmente coesa, com um cabeçalho separando claramente uma seção da próxima.

### 2.1.1 Destaque visual do cabeçalho (reforço de UX de Rhoney)
O cabeçalho de cada seção não deve ser um texto simples e discreto (como o "Libras" atual, que é apenas um rótulo cinza pequeno) — ele precisa ter **destaque visual real**, para que o usuário identifique imediatamente, ao rolar a tela, onde uma seção termina e a próxima começa. Diretrizes de UX para esse cabeçalho:
- Tipografia com peso/tamanho maior que o texto comum da tela, coerente com a hierarquia visual já usada em outros títulos de destaque do app (ex.: nomes de Mundo nas telas de navegação).
- Elemento visual de apoio que reforce a identidade daquela seção — pode incluir um ícone temático (ex.: uma bandeira estilizada ou ícone remetendo ao idioma, no caso do Mundo dos Idiomas; ícone temático equivalente em outros Mundos), acompanhando o texto do cabeçalho, não apenas texto puro.
- Uso de cor/destaque (ex.: leve realce de fundo, linha divisória estilizada, ou gradiente sutil) que separe visualmente a seção sem comprometer a legibilidade nem destoar da paleta já estabelecida do MENTAL.
- Tratamento consistente entre todos os Mundos — o mesmo componente de cabeçalho de seção deve ser reutilizado em todo o app, para que o usuário aprenda o padrão uma vez e reconheça instantaneamente em qualquer Mundo.
- O resultado final deve transmitir acabamento **profissional, dinâmico e estiloso** — não um divisor genérico de lista, e sim um elemento de design que eleva a percepção de qualidade da navegação como um todo, na mesma linha de cuidado já pedida para o Caça-palavras (CACA_PALAVRAS_BUG_E_VISUAL_V1.md) e para o ícone de acesso ao Mapa de Trajetória (DESTAQUE_ICONE_MAPA_TRAJETORIA_V1.md).

### 2.2 Conexão com a arquitetura de SubMundos já existente
Rhoney confirmou que esse princípio deve seguir a mesma lógica já estabelecida em ARQUITETURA_SUBMUNDOS_V1.md (Mundo → SubMundo → Bloco → Desafio), aplicada tanto à **estrutura de dados** quanto à **organização visual/navegação** — ou seja, cada idioma (Inglês, Espanhol, Francês, Libras, e futuros) passa a ser tratado com a mesma consistência estrutural já usada nos SubMundos do Mundo da Internet e do Mundo dos Esportes, e a interface deve refletir essa hierarquia de forma visualmente clara, não apenas internamente no banco de dados.

### 2.3 Exemplo de aplicação no Mundo dos Idiomas
- Seção "Inglês" — reunindo Desafio Básico, Intermediário, Avançado, e seus respectivos Relâmpagos, com um único cabeçalho "Inglês" no topo.
- Seção "Espanhol" — mesma lógica.
- Seção "Francês" — mesma lógica.
- Seção "Libras" — já está correta hoje, serve de modelo/referência visual para as demais.

## 3. Escopo — todos os Mundos, levantamento completo obrigatório

Rhoney determinou que esta reorganização **não se limita ao Mundo dos Idiomas** — deve ser aplicada de forma consistente em todos os Mundos do app. Como o padrão de organização atual de cada Mundo não está mapeado neste documento, Claude Code deve:

1. **Levantar todos os Mundos existentes hoje no MENTAL** e, para cada um, reportar se o conteúdo já está organizado em seções claras (com cabeçalho por categoria/tema) ou se está misturado numa grade contínua, como identificado no Mundo dos Idiomas.
2. Entregar esse relatório a Rhoney **antes de qualquer reorganização visual ser implementada**, para que ele tenha visibilidade real da extensão do trabalho e possa priorizar.
3. Após aprovação, aplicar a reorganização visual Mundo por Mundo, seguindo o padrão descrito na seção 2.

## 4. Escopo técnico (a propor em detalhe por Claude Code)

- Desenhar um componente reutilizável de "seção com cabeçalho" para uso em qualquer Mundo, evitando implementação repetida e inconsistente entre diferentes telas. Este componente deve incorporar o destaque visual descrito na seção 2.1.1 (tipografia, ícone temático, elemento de cor/realce) desde a primeira versão — não como um divisor simples a ser "embelezado" depois.
- Aplicar esse componente ao Mundo dos Idiomas primeiro (caso já identificado e validado neste documento), depois aos demais Mundos conforme o relatório da seção 3.
- Garantir que a mudança seja puramente organizacional/visual — não deve alterar a lógica de navegação, progresso ou dados já existentes, apenas a forma como o conteúdo é apresentado ao usuário.
- Considerar a arquitetura de SubMundos já implementada (Internet, Esportes) como referência de como estruturar tecnicamente essa hierarquia, reaproveitando padrões já validados em vez de criar uma abordagem nova e divergente.

## 5. Critério de aceite

- Relatório de todos os Mundos do app entregue a Rhoney, indicando quais já têm organização por seção e quais precisam de reorganização.
- Mundo dos Idiomas reorganizado com seções claras por idioma (Inglês, Espanhol, Francês, Libras), cada uma com cabeçalho próprio agrupando todo o conteúdo daquele idioma.
- Cabeçalho de cada seção com destaque visual real (tipografia maior, ícone temático, elemento de cor/realce), com acabamento profissional, dinâmico e estiloso — não um divisor de lista genérico.
- Componente de seção reutilizável aplicado de forma consistente nos demais Mundos identificados como pendentes, após priorização aprovada por Rhoney.
- Nenhuma alteração de dados, progresso ou lógica de navegação foi introduzida — apenas reorganização visual.
