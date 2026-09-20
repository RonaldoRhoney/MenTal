# MENTAL — Batalha Assíncrona (item 14)

**Status:** Aprovado para implementação — item 14 da V2.
**Documentos relacionados:** V2_KICKOFF.md §4, item 12 (Amigos), NOTIFICATIONS.md, MICROINTERACTIONS.md

---

## 1. Conceito

Um jogador desafia um amigo (reaproveitando a lista de Amigos do item 12) para uma disputa de desempenho, resolvida de forma assíncrona — cada um responde no seu próprio tempo, sem precisar estar online simultaneamente.

---

## 2. Mecânica

1. **Jogador A desafia Jogador B** (amigo já existente) — escolhe um território (ou aleatório) e um nível de dificuldade.
2. **O sistema sorteia um desafio para o Jogador A** dentro daquele território/nível, do banco de conteúdo já existente. Jogador A responde na hora.
3. **O sistema sorteia um desafio diferente para o Jogador B**, do mesmo território e mesmo nível de dificuldade (não é o mesmo desafio — apenas comparável em dificuldade). Jogador B é notificado ("Fulano te desafiou! 🎯") e responde quando quiser.
4. **Resultado revelado somente após ambos responderem** — nenhum dos dois vê o resultado do outro antes de ter respondido sua própria parte (evita vantagem de copiar resposta ou ajustar estratégia).
5. **Critério de vitória:**
   - Acertou > errou (quem acertou vence quem errou, independentemente de tempo).
   - Entre dois acertos, vence quem respondeu mais rápido.
   - Entre dois erros, é empate (sem vencedor, sem XP bônus para nenhum lado).

---

## 3. Limite de envio — antispam

- **Limite diário de desafios enviados por usuário: 3 por dia** (valor de referência, parametrizável em `config.py`, sem hardcode no cliente).
- O limite é sobre desafios **enviados**, não recebidos — um jogador pode receber quantos desafios diferentes amigos quiserem mandar, mas só pode iniciar até 3 batalhas novas por dia.
- Limite reseta a cada 24h, seguindo o mesmo padrão de reset já usado no limite de 24 desafios diários gratuitos (mesmo tipo de regra, escopo diferente).

---

## 4. Recompensa — XP bônus para o vencedor

- **Vencedor:** XP normal do desafio + bônus fixo de vitória (`config.BATTLE_WIN_BONUS_XP`, valor de referência a definir, mesmo padrão do `WORLD_COMPLETION_BONUS_XP` já usado no item 11).
- **Perdedor:** apenas o XP normal do desafio que respondeu — sem penalidade, sem perda de XP. Perder uma batalha nunca custa nada além de não ganhar o bônus extra.
- **Empate (ambos erraram):** ambos recebem apenas o XP normal (que pode ser zero, dependendo da resposta) — sem bônus para nenhum lado, sem penalidade adicional.

---

## 5. Tom de comunicação (Princípio de Não-Humilhação aplicado)

- Notificação de desafio recebido: tom de convite/diversão, nunca de provocação. Ex.: "Fulano te desafiou em Território X! Bora responder? 🎯"
- Notificação de resultado: comemora o vencedor sem humilhar o perdedor. Ex. vencedor: "Você venceu a batalha contra Fulano! 🏆". Ex. perdedor: tom neutro/gentil, nunca "você perdeu para Fulano" com ênfase na derrota — algo como "Batalha encerrada — Fulano levou essa. Bora tentar outra? 💪".
- Mesma regra do `child_safe_mode` já aplicada em ranking/notificação social: se aplicável, nomes de amigos em contexto de derrota devem seguir a mesma política de anonimização já usada no ranking semanal (a confirmar se batalha entre amigos já confirmados precisa do mesmo tratamento, já que aqui os dois já se conhecem via convite — diferente do ranking geral).

---

## 6. Escopo técnico (alto nível — arquitetura detalhada a propor por Claude Code)

- Tabela nova esperada: `battles` (ou nome similar) — registra desafiante, desafiado, território/nível, desafio sorteado para cada um, respostas (acerto/erro + tempo), status (pendente/resolvida), timestamp.
- Reaproveita o banco de desafios já existente (sem conteúdo novo) — só sorteio dentro do território/nível escolhido.
- Reaproveita a infraestrutura de notificações já existente (FCM, mesma autoridade central de decisão no FastAPI).
- Autoridade de XP e resultado permanece 100% no backend — cliente nunca decide vencedor nem calcula bônus.

---

## 7. Fora de escopo agora

- Torneios ou disputas com mais de 2 jogadores — fora de escopo, isso é 1x1 apenas.
- Histórico de "quem venceu mais vezes contra quem" como estatística exposta — não incluído nesta versão (pode gerar comparação constante entre amigos, revisar necessidade no futuro se pedido).
- Revanche automática ou notificação de "desafie de volta" — não incluído agora; o jogador pode desafiar de volta manualmente, respeitando o mesmo limite diário de 3 envios.
