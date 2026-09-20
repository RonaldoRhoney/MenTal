# MENTAL — Palavras Relâmpago (modo de múltipla escolha com tempo)

**Status:** Aprovado para implementação — item 15 da V2, entra na fila após o Grupo 2 (Amigos, Disputa territorial, Batalha assíncrona).
**Documentos relacionados:** V2_KICKOFF.md, DESIGN_SYSTEM.md, MICROINTERACTIONS.md, FAMILY_SAFETY.md

---

## 1. Conceito

Um modo novo dentro do território **Palavras**, que convive com o formato atual (resposta digitada) — não o substitui. O usuário recebe uma palavra de nível médio ou difícil e **3 alternativas de resposta**, com um **tempo regressivo** para clicar na correta. Testa velocidade de reconhecimento e decisão sob leve pressão, em vez de recordação/digitação livre.

- Disponível apenas para níveis **médio e difícil** — nível fácil permanece exclusivamente no formato digitado atual (decisão já tomada: nível fácil não entra neste modo).
- O usuário escolhe/alterna entre os dois formatos (exato mecanismo de seleção de UI a definir na implementação — ex.: toggle na tela do território, ou variação natural conforme o desafio sorteado).

---

## 2. Tempo regressivo — escalonado por nível

- **Médio:** tempo maior (ex.: 10s — valor exato de referência, configurável via `config.py`, não hardcoded no cliente).
- **Difícil:** tempo menor (ex.: 6-7s — valor exato a definir na implementação, seguindo a mesma lógica: mais difícil = menos tempo, mais pressão).
- Os valores exatos de segundos por nível são parâmetro de configuração central (backend), podendo ser ajustados sem alterar o cliente — mesmo padrão de autoridade central já usado em todo o MENTAL.

---

## 3. Tempo esgotado — tratamento suave (Princípio de Não-Humilhação aplicado)

Quando o tempo acaba sem o usuário escolher uma alternativa:

- **Não conta como erro pleno.** Mensagem e visual mais suaves que um erro normal — ex.: "Quase lá! Tenta de novo" em vez do feedback padrão de resposta incorreta.
- Isso reconhece que estourar o tempo é uma categoria diferente de "saber errado" — pode ser distração, lentidão momentânea, ou simplesmente o timer ser apertado demais pra aquela pessoa naquele momento. Coerente com o mesmo cuidado já aplicado a idosos/crianças em outras partes do produto.
- Detalhe de implementação (registrar para Claude Code decidir com base no que já existe): se o tempo esgotado ainda permite nova tentativa na mesma questão, ou avança para a próxima com o tom suave de feedback — ambos compatíveis com o princípio acima, mas geram fluxos ligeiramente diferentes.

---

## 4. Pontuação — bônus por velocidade

- A resposta correta gera XP proporcional à rapidez: **responder mais rápido vale mais XP** que responder no fim do tempo disponível.
- Modelo proposto (referência para Claude Code parametrizar em `config.py`, mesmo padrão do bônus escalonado de passos): XP base do desafio × multiplicador decrescente conforme o tempo consumido (ex.: responder nos primeiros 30% do tempo = bônus máximo; responder nos últimos 30% = XP base sem bônus, mas ainda conta o acerto normalmente).
- Isso é bônus **adicional** ao XP normal do desafio — não penaliza quem responde mais devagar (dentro do tempo), só recompensa extra quem for mais rápido. Mesma filosofia usada no bônus de passos (nunca punir, só premiar o extra).

---

## 5. Escopo técnico (alto nível, arquitetura detalhada a propor por Claude Code)

- Reaproveita a estrutura de desafio já existente do território Palavras (banco de palavras, níveis) — não precisa de conteúdo novo, só um novo formato de apresentação/resposta para o conteúdo já curado.
- Novo campo de configuração de tempo por nível, novo cálculo de bônus por velocidade no backend (autoridade de XP permanece 100% no FastAPI, cliente só envia o tempo de resposta, backend decide o XP final — mesmo princípo de segurança de toda a arquitetura).
- Sem tabela nova esperada — provavelmente só campos adicionais no registro de tentativa (`attempt`) para registrar tempo de resposta, seguindo o padrão de idempotência via `attempt_id` já em uso.
- Nenhuma mudança na estrutura de mundos, badges ou territórios — é puramente um novo formato de interação dentro do território Palavras já existente.

---

## 6. Fora de escopo agora

- Não se aplica a outros territórios (Números, Lógica, etc.) — registrado aqui só para Palavras. Se funcionar bem, pode ser avaliado como padrão a expandir para outros territórios em versão futura (não decidido, não prioritizado).
- Nível fácil continua exclusivamente digitado — sem modo relâmpago nesse nível.
