# MENTAL — Redesenho e Destaque do Ícone de Acesso ao Mapa de Trajetória

**Status:** IMPLEMENTADO (18/09/2026). Este documento trata especificamente do **botão de acesso** ao Mapa de Trajetória (já especificado em MAPA_TRAJETORIA_MUNDOS_V1.md) — não da tela do mapa em si. Nota: o botão já não vive dentro de "Progresso" (referência do §3 desatualizada) — mora no card de perfil da Home desde DESTAQUE_ICONE_MAPA_TRAJETORIA (Home) / MAPA_TRAJETORIA_MUNDOS_V1.md (pedido de Rhoney, 18/09/2026).

## O que foi implementado
- `client/lib/screens/home_screen.dart::_TrajectoryMapLaunchButton` — substitui o ícone de "sparkles" (✨) genérico por uma miniatura do próprio planeta/anel usado na tela de destino (mesmo desenho de `trajectory_map_screen.dart::_RingPainter`, replicado em escala pequena como `_MiniRingPainter` — sem acoplar a Home à tela de feature), com rótulo "Trajetória" abaixo, no mesmo padrão dos 5 atalhos (Progresso/Ranking/Amigos/Movimento/Feed).
- Dimensionamento: nome do usuário e botão do mapa dividem o espaço livre entre avatar e chip de MentalCoins em **50/50** (`Expanded(flex: 1)` para cada), responsivo a qualquer tamanho de nome — testado com "Rhoney" (curto) num build real no celular.
- Validado com build real instalado no Moto G22, contra a conta admin real (Nível 252): botão visualmente perceptível, clique leva corretamente ao Mapa de Trajetória.
- Testes: `client/test/home_screen_test.dart` (suíte existente, 12/12 passando sem regressão).

---

## 1. Problema identificado

No card de perfil da Home (onde aparecem nome do usuário, nível, barra de XP e estatísticas), existem hoje dois elementos circulares lado a lado, próximos ao topo direito do card:
1. Um círculo com ícone de "sparkles" (✨), que é o atual ponto de entrada para o Mapa de Trajetória.
2. O círculo dourado com "M 660" (saldo de MentalCoins).

O primeiro ícone (sparkles) está **visualmente genérico e pouco perceptível** — não comunica que ali existe uma funcionalidade importante (visualizar o próprio progresso/trajetória no app) e passa despercebido pelo usuário ao entrar na Home.

## 2. O que precisa mudar

### 2.1 Redesenho do ícone
- Substituir o ícone genérico de sparkles por uma **ilustração que remeta claramente a mapa/trajetória/percurso** — coerente com a metáfora de Universo/Galáxia já definida para a própria tela do mapa (ver MAPA_TRAJETORIA_MUNDOS_V1.md), para que o botão já "anuncie" visualmente o que o usuário vai encontrar ao tocar nele.

### 2.2 Rótulo textual
- Adicionar um **nome/rótulo abaixo do ícone**, seguindo o mesmo padrão já usado nos botões de atalho logo acima na Home (Progresso, Ranking, Amigos, Movimento, Feed — todos têm ícone + texto embaixo). Sugestão de nome a validar com Rhoney: "Trajetória", "Meu Mapa" ou "Progresso" (evitar duplicar exatamente o nome do botão "Progresso" já existente no menu de atalhos, para não gerar confusão sobre serem a mesma coisa).

### 2.3 Dimensionamento e destaque
- O elemento (ícone + rótulo) deve ocupar aproximadamente **50% do espaço horizontal disponível** entre o nome do usuário (à esquerda) e o ícone de MentalCoins (à direita), dentro do card de perfil — independentemente do tamanho do nome do usuário exibido. Ou seja, o layout precisa ser responsivo a nomes de diferentes tamanhos, mantendo essa proporção de destaque.
- O objetivo é que, ao entrar na Home, o usuário perceba imediatamente que ali existe um elemento clicável relevante — não mais um detalhe pequeno e secundário.

### 2.4 Harmonização visual
- A nova versão do ícone/botão deve manter coerência com a identidade visual já estabelecida no restante do card (paleta de cores, estilo dos demais ícones, acabamento visual), evitando destoar do conjunto apesar do maior destaque.
- Tratar como um trabalho de UX/UI completo — não uma troca simples de ícone, e sim um componente redesenhado com intenção clara de chamada visual.

## 3. Escopo técnico (a propor em detalhe por Claude Code)

- Redesenhar o componente do botão no Flutter, incluindo o ícone temático de mapa/trajetória e o rótulo textual abaixo.
- Implementar o dimensionamento responsivo (aproximadamente 50% do espaço entre nome do usuário e ícone de MentalCoins), testando com nomes de usuário curtos e longos para garantir que o layout não quebra.
- Confirmar que o destino do clique continua sendo a tela do Mapa de Trajetória (dentro do menu Progresso, conforme já definido).
- Validar a proposta visual com Rhoney (ex.: protótipo/preview) antes da implementação final, dado que envolve decisão de design significativa dentro de um card já denso de informação.

## 4. Critério de aceite

- Ícone redesenhado remete visualmente a mapa/trajetória, coerente com a metáfora de Universo/Galáxia da tela de destino.
- Rótulo textual visível abaixo do ícone, no mesmo padrão dos demais atalhos da Home.
- Elemento ocupa aproximadamente 50% do espaço horizontal entre nome do usuário e ícone de MentalCoins, de forma responsiva a diferentes tamanhos de nome.
- Usuário reconhece com facilidade, ao entrar na Home, que aquele é um botão importante e clicável.
- Clique leva corretamente à tela do Mapa de Trajetória.
