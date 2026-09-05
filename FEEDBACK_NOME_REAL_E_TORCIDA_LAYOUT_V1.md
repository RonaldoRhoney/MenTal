# MENTAL — Feedback com Nome Real do Autor + Correção de Layout da Torcida

**Status:** Aprovado para implementação.
**Documento relacionado:** APROVACAO_CORRECOES_PRE_AAB_V1.md (item A1 — bloqueio de usuário deve valer em todo contato) — a correção A1 deve estar aplicada antes ou junto desta mudança, ver seção 2.

---

## 1. Feedback: exibir nome real do autor, não "Jogador-XXXXX"

### 1.1 Contexto e justificativa
O mural de Feedback hoje exibe o apelido genérico "Jogador-XXXXX" para identificar quem escreveu cada comentário. Essa proteção fazia sentido quando o MENTAL era destinado a incluir menores de idade, mas deixou de fazer sentido desde a decisão de tornar o app exclusivo para maiores de 18 anos (MENTAL-DIR-001) — decisão que já levou o app a exibir nome real e foto aprovada publicamente por padrão em outras telas (Perfil, Ranking), conforme USER_PROFILE.md.

Confirmado: a política de Conteúdo Gerado por Usuário (UGC) do Google Play não exige anonimato de usuário — a exigência real é a existência de denúncia e bloqueio funcionando efetivamente. Não há, portanto, impedimento de política para esta mudança.

### 1.2 Mudança
- O mural de Feedback passa a exibir o **nome real** do autor de cada comentário (o mesmo nome já usado publicamente em Perfil e Ranking), em vez do apelido genérico "Jogador-XXXXX".
- Essa mudança vale igualmente para comentários novos e para o histórico de comentários já existentes — não é necessário reprocessar comentários antigos de forma diferente, apenas exibir o nome real vinculado ao autor de cada um, presente ou passado.

## 2. Pré-requisito obrigatório: bloqueio efetivo antes desta mudança

Como identificar o autor do comentário aumenta a superfície de exposição pessoal, a correção **A1** (já aprovada em APROVACAO_CORRECOES_PRE_AAB_V1.md — aplicar `is_blocked_either_way` em `get_public_profile` e `send_torcida`) deve estar implementada e validada **antes ou junto** desta mudança de Feedback.

Adicionalmente, aplicar essa mesma checagem de bloqueio também à listagem de comentários do mural: um usuário bloqueado por outro não deve ver o nome real do bloqueador (nem vice-versa) na tela de Feedback, mesmo que ambos os comentários continuem visíveis ao restante da comunidade. Onde a exibição do nome real for suprimida por bloqueio, usar um rótulo genérico (ex.: "Usuário") apenas para essa relação específica, não para o restante dos usuários.

## 3. Torcida: corrigir corte de layout na tela de Perfil

### 3.1 Problema
Na tela de Perfil (visita a outro usuário), os 4 ícones de reação de Torcida (vibração, balão, coraçãozinho, joinha) estão sendo cortados na parte inferior da tela — o layout atual não reserva espaço suficiente para exibi-los por completo, ficando parcialmente sobrepostos/cortados pela área de navegação do sistema Android.

### 3.2 Comportamento esperado
- Os 4 ícones de reação devem sempre aparecer completos e totalmente visíveis, sem corte, em qualquer tamanho de tela suportado pelo app.
- A tela de Perfil deve ser revisada para garantir que todo o conteúdo abaixo de "Mundos" (incluindo o bloco "Mande uma torcida!" e os 4 ícones) tenha espaço reservado corretamente, considerando a área segura do sistema (safe area) e a barra de navegação do Android.
- Se necessário, a tela deve permitir rolagem (scroll) suficiente para que os 4 ícones fiquem completamente acessíveis ao toque, sem exigir gestos ou ajustes especiais do usuário.

## 4. Escopo técnico (alto nível — arquitetura detalhada a propor por Claude Code)

- Feedback: substituir a referência ao apelido genérico pela mesma fonte de nome real já usada em Perfil/Ranking, aplicando a checagem de bloqueio descrita na seção 2 antes de exibir.
- Torcida: ajustar o layout da tela de Perfil (padding inferior, safe area, ou scroll) para eliminar o corte dos 4 ícones, testando em pelo menos um dispositivo Android real com barra de navegação por gestos e outro com barra de navegação tradicional (3 botões), já que o corte pode se comportar de forma diferente entre os dois modelos de navegação do Android.

## 5. Critério de aceite

- Mural de Feedback exibe nome real do autor de cada comentário, novo ou antigo.
- Usuários bloqueados entre si não veem o nome real um do outro no mural de Feedback, mesmo que os comentários de ambos continuem visíveis à comunidade em geral.
- A correção A1 (bloqueio em Perfil Público/Torcida) está implementada e validada antes desta entrega ir ao ar.
- Os 4 ícones de Torcida aparecem completos, sem corte, testados em pelo menos dois modelos de navegação Android (gestos e 3 botões).
