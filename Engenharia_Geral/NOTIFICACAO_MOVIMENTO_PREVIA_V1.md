# MENTAL — Notificação de Movimento com Prévia de Ganhos + Navegação Direta

**Status:** IMPLEMENTADO (14/09/2026). Navegação direta pro toque na notificação já existia (NOTIFICACAO_ICONE_M_MENTAL.md §4, `MovementTaskHandler.onNotificationPressed`). Adicionado nesta leva: `MovementService.updateNotificationPreview()` (client/lib/services/movement_service.dart) atualiza o texto da notificação persistente com MentalCoins e XP já creditados HOJE (`MovementCycle.current_cycle`, sempre valor AUTORITATIVO do backend — XP nunca calculado no client, já que a conversão real tem faixas/bônus; MentalCoins usa a proporção flat 1000 passos = 5 MentalCoins, mesma de `config.py`). Chamado nos mesmos pontos que já buscam `GET /movement/status` (Home, tela Movimento) e logo após cada coleta automática — sem chamada de rede extra só pra isso. Sem botões de ação, mesmo formato compacto de uma linha (🚶 Passos · 🪙 MentalCoins · ⚡ XP — pedido de Rhoney, 14/09/2026, de incluir também os passos, não só os dois contadores derivados).

---

## 1. Contexto

Hoje, enquanto o Movimento está ativo (rastreando passos em segundo plano), a notificação exibida é genérica:

> **MENTAL — Movimento ativo**
> Contando seus passos em segundo plano.

Sem nenhum dado numérico visível, exigindo que o usuário abra o app pra saber o que já ganhou.

## 2. O que muda

### 2.1 Conteúdo da notificação
A notificação passa a exibir, no mesmo espaço, uma prévia do que o usuário já ganhou com a caminhada **do dia atual**:
- **MentalCoins** ganhos hoje com o Movimento
- **XP** ganho hoje com o Movimento

Ambos os contadores são **diários** — zeram a cada novo dia, refletindo apenas o progresso da caminhada em curso naquele dia, não o acumulado histórico do usuário.

### 2.2 Referência visual
Seguir o padrão de layout compacto do print anexado por Rhoney: ícone à esquerda, valores numéricos com seus respectivos ícones (moeda para MentalCoins, símbolo equivalente para XP), dispostos de forma legível numa única linha ou duas linhas curtas, mantendo a identidade visual do MENTAL (não copiar cores/ícones do app de referência, só a lógica de layout compacto e informativo).

### 2.3 Sem botões de ação
Diferente da referência, a notificação do MENTAL **não deve ter botões de ação** (nada equivalente a "Obter" ou "Feche" dentro da notificação). A notificação é puramente informativa — a ação de abrir o app acontece pelo toque na notificação como um todo, não por um botão específico dentro dela.

## 3. Comportamento ao tocar na notificação

Ao tocar na notificação de Movimento ativo, o app deve abrir **diretamente na tela de Movimentos** — sem passar pela Home ou por qualquer outra tela intermediária.

## 4. Escopo técnico (a propor em detalhe por Claude Code)

- Atualizar o template da notificação persistente/em segundo plano do Movimento para incluir os dois contadores diários (MentalCoins e XP), com atualização em tempo real ou em intervalos curtos conforme o usuário caminha.
- Confirmar a lógica de reset diário desses contadores (deve ser a mesma lógica já usada em qualquer outro contador diário do app, se existir, para evitar duplicar regra de negócio).
- Implementar deep link direto para a tela de Movimentos a partir do toque na notificação, testando que o comportamento funciona tanto com o app em segundo plano quanto totalmente fechado.
- Remover/não implementar nenhum botão de ação dentro da notificação — manter apenas o toque na área geral como forma de abrir o app.

## 5. Critério de aceite

- Notificação de Movimento ativo exibe corretamente MentalCoins e XP ganhos no dia atual, com layout compacto similar ao padrão de referência.
- Os valores exibidos zeram corretamente a cada novo dia.
- Nenhum botão de ação aparece dentro da notificação.
- Tocar na notificação leva o usuário diretamente à tela de Movimentos, sem passar por nenhuma tela intermediária.
