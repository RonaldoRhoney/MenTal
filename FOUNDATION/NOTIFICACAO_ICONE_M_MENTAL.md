# MENTAL — Ícone Correto e Navegação da Notificação Persistente do Movimento

**Status:** Aprovado para implementação.
**Tipo:** Correção de bug/ajuste visual.

---

## 1. Descrição do problema

A notificação persistente de "MENTAL — Movimento ativo" (exibida enquanto o contador de passos em segundo plano está rodando) está mostrando um ícone genérico do sistema Android (círculo teal sem identidade visual), em vez do ícone real do app — o "M" com sinapses neurais já usado no ícone do app na tela inicial do celular e na Splash Screen.

## 2. Comportamento esperado

- A notificação deve exibir o **ícone oficial do app** (o mesmo já usado no launcher/ícone do celular e na Splash) como ícone pequeno da notificação (small icon), no lugar do ícone genérico atual.
- Isso vale tanto para a notificação persistente de Movimento em segundo plano quanto para qualquer outra notificação do MENTAL que hoje esteja usando o mesmo ícone genérico (push de streak, missão diária, Torcida, etc.) — a correção deve ser aplicada de forma centralizada, não só neste caso específico.
- Ao tocar na notificação persistente de Movimento, o app deve abrir diretamente na tela Movimento — não na Home nem em qualquer outra tela. Se o app já estiver aberto em outra tela no momento do toque, deve navegar até Movimento; se estiver fechado, deve abrir já nela.

## 3. Causa provável

Notificações Android exigem um "small icon" próprio, geralmente uma versão monocromática/simplificada do ícone do app (não o ícone colorido completo) — é comum esse recurso não ter sido configurado corretamente ao implementar as notificações, fazendo o sistema cair no ícone padrão genérico.

## 4. Navegação ao tocar na notificação

- A notificação persistente de Movimento deve ter uma ação de toque associada (deep link/intent interno) que leva o usuário diretamente à tela Movimento, sem etapas intermediárias.
- Isso vale tanto para toque no corpo da notificação quanto, se existir, em qualquer botão de ação dentro dela.
- Esse comportamento é específico da notificação de Movimento — não faz parte do escopo de correção do ícone genérico (seção 2), que continua valendo para todas as notificações do app.

## 5. Escopo técnico (alto nível — arquitetura detalhada a propor por Claude Code)

- Confirmar se existe um asset de ícone monocromático adequado para notificação (formato exigido pelo Android: versão simplificada, geralmente branca sobre fundo transparente, do "M" com sinapses) — se não existir, criar a partir do ícone oficial já existente do app.
- Configurar esse asset como o `smallIcon` usado em todas as notificações do MENTAL (persistente de Movimento e demais pushes via FCM), centralizando a configuração para evitar que o problema se repita em notificações futuras.
- Testar em pelo menos um dispositivo Android real, confirmando que o ícone aparece corretamente tanto na barra de status quanto na notificação expandida (como a da imagem de referência).
- Implementar o `PendingIntent`/deep link da notificação de Movimento apontando para a rota interna da tela Movimento, reaproveitando a navegação já existente no app (mesma rota usada pelo ícone de Movimento no grid de atalhos da Home).

## 6. Critério de aceite

- A notificação persistente de Movimento exibe o ícone real do MENTAL (o "M"), não mais o círculo genérico.
- Demais notificações do app (streak, missão diária, Torcida) também exibem o ícone correto, de forma consistente.
- Ícone aparece nítido e reconhecível tanto na barra de status (ícone pequeno) quanto na notificação expandida.
- Tocar na notificação persistente de Movimento abre o app diretamente na tela Movimento, com o app aberto ou fechado no momento do toque.
