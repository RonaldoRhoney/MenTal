# MENTAL — Perfil Público de Outro Usuário (Visita + Torcida)

**Status:** Aprovado para implementação.
**Documentos relacionados:** USER_PROFILE.md (define quais dados já são públicos: nome real, foto, nível — este documento reaproveita exatamente esses campos, sem expor nada novo), RANKING.md, ADMIN_DASHBOARD_V1.md (moderação de denúncia/bloqueio já existente, reaproveitada aqui).

---

## 1. Conceito

Hoje, quando um usuário vê o nome/foto de outro em Ranking, Amigos ou Batalhas, não há como "entrar" e ver a jornada dessa pessoa — o dado já é público, mas não tem um lugar dedicado pra ser visto. Esta feature cria esse lugar: ao tocar em qualquer usuário nessas superfícies, abre-se um **perfil público de leitura**, mostrando progressão e conquistas.

Complementarmente, adiciona-se uma **reação leve** ("torcida") — não uma mensagem, não um chat — permitindo que um usuário reconheça o progresso de outro de forma positiva e de baixíssimo risco de moderação.

Uma segunda ideia, de "ajudar" o outro usuário de forma mais ativa, é deliberadamente **registrada como ideia futura, não especificada aqui** (ver seção 5) — ela mistura possibilidades muito diferentes entre si (reação simples, mensagem livre, mecânica de economia de jogo) que merecem decisão própria, cada uma com implicações distintas de moderação e de equilíbrio de jogo.

---

## 2. Escopo de dados exibidos no perfil público

**Regra central: nunca exibir dado que o próprio usuário não tenha já tornado público em algum outro lugar do app.** Esta feature é uma nova *vitrine* para dado que já existe, não uma nova coleta ou exposição de dado.

Exibir:
- Nome real e foto de perfil (já públicos, conforme USER_PROFILE.md).
- Nível atual e progresso de XP.
- Badges/conquistas desbloqueadas.
- Mundos completos/em progresso (Mundo da Linguagem, Mundo da Mente Lógica, e demais conforme V3 for lançada).
- Streak atual.
- Território(s) de melhor desempenho (mesma lógica já usada no ADMIN_DASHBOARD_V1.md para a tabela de "quem mais progrediu", agora espelhada para o próprio usuário ver sobre os outros).

**Nunca exibir:**
- E-mail, dados de conta, configurações.
- Localização granular (cidade/estado, se algum dia coletado com mais precisão do que hoje) além do que já for publicamente decidido em USER_PROFILE.md.
- Histórico de respostas individuais (acertos/erros pergunta a pergunta) — só agregados de progressão, nunca o detalhe de desempenho pergunta a pergunta de outra pessoa.
- Qualquer dado de saldo/economia (MentalCoins, se o usuário preferir manter privado — a definir se saldo de MentalCoins é público ou não; Hall da Fama já expõe isso para o Top 3 da semana, então pode ser tratado como já público por precedente, mas vale confirmar antes de implementar).

## 3. Acesso ao perfil

- Qualquer usuário pode visitar o perfil público de qualquer outro usuário com quem tenha algum ponto de contato no app (aparece em Ranking, é Amigo, ou está em uma Batalha em andamento/concluída com ele) — não é necessário ser amigo para visitar, já que o dado em si já é público nessas superfícies.
- Ponto de entrada: tocar no nome/foto/avatar do usuário em qualquer lista onde ele já aparece (Ranking, Amigos, histórico de Batalhas, Hall da Fama do MentalCoins).
- Sem busca livre por nome de usuário nesta fase — o acesso é sempre a partir de um contexto onde os dois usuários já se cruzaram (reduz superfície de uso indevido, ex.: alguém vasculhando perfis de estranhos sem relação nenhuma com o app).

## 4. Torcida (reação leve)

- Um usuário pode enviar uma reação positiva pré-definida (ex.: 👏, 🔥, ou equivalente visual consistente com a identidade do app) ao ver o perfil de outro — **nunca texto livre**.
- Limite razoável de reações por dia/por usuário-alvo, a definir com Claude Code, evitando spam de reação (mesmo sendo positiva, volume excessivo pode virar ruído).
- O destinatário recebe uma notificação simples ("Fulano torceu por você!") — mesmo padrão de notificação não-humilhante já usado em Batalhas e Disputa Territorial.
- **Sem risco de moderação de conteúdo livre**, porque não há texto — é a mesma razão pela qual isso é uma boa primeira entrega, versus qualquer mecanismo de mensagem.

## 5. Fora de escopo nesta entrega — "Ajudar" (ideia futura registrada)

A ideia original incluía também a possibilidade de um usuário "ajudar" outro. Isso fica deliberadamente fora desta entrega, porque "ajudar" pode significar coisas muito diferentes, cada uma com um nível de risco e esforço de design distinto:

- **Reação simples** (já coberta pela Torcida, seção 4) — resolvida nesta entrega.
- **Mensagem/dica em texto livre** — exigiria sistema de chat/mensagens com moderação de conteúdo gerado por usuário em tempo real, uma superfície de risco muito maior do que qualquer coisa já implementada no MENTAL (diferente de foto de perfil, que é moderação de imagem única e esporádica). Não especificado aqui.
- **Mecânica de jogo** (ex.: doar XP, liberar uma dica extra para um amigo destravar um território) — é decisão de economia de jogo, na mesma categoria de cuidado já aplicada a MentalCoins (nunca pode desequilibrar progressão ou parecer "pagar para vencer"). Não especificado aqui.

Quando/se a ideia de "ajudar" for retomada, ela deve ser detalhada em documento próprio, escolhendo explicitamente qual dessas formas (ou outra) fará sentido — não deve ser implementada por extensão informal desta feature de Torcida.

## 6. Escopo técnico (alto nível — arquitetura detalhada a propor por Claude Code)

- Reaproveita os dados de perfil já existentes (`Profile`, badges, progresso de mundos, streak) — não requer nova coleta de dado.
- Novo endpoint de leitura agregada por usuário (`GET /profile/{user_id}/public` ou equivalente), respeitando exatamente a lista de campos permitidos da seção 2.
- Nova estrutura simples para registrar reações de Torcida (quem torceu, para quem, quando) — não precisa de histórico rico, apenas contagem e notificação.
- Autoridade sobre quais dados são públicos permanece 100% no backend — o cliente nunca decide o que exibir, apenas renderiza o que a API retorna.

## 7. Critério de aceite

- Usuário consegue visitar o perfil de outro usuário a partir de Ranking, Amigos, Batalhas e Hall da Fama.
- Nenhum dado fora da lista da seção 2 é exposto no perfil público.
- Torcida funciona sem texto livre, com notificação simples ao destinatário.
- Nenhuma busca livre por nome de usuário é possível nesta fase.
- Nenhuma funcionalidade de "ajudar" além da Torcida é implementada nesta entrega.
