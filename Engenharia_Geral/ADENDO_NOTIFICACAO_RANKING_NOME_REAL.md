# MENTAL — Regra Geral: Nome Real em TODA Interação do App (sem exceção)

**Status:** Implementado (12/09/2026) — ver seção 5.
**Documento relacionado:** NOME_REAL_E_FOTO_EM_TODO_LUGAR_V1.md — este documento eleva o escopo daquela correção de uma lista de pontos específicos para uma **regra geral e permanente**, após novo caso real encontrado (notificação de mudança de Ranking) que não estava na lista original de 5 pontos mapeados.

---

## 1. Evidência que motivou a mudança de escopo

Captura de notificação real do Android (12/09, MENTAL, "O ranking mudou"):
> "Jogador-00e350f4 passou você no ranking. Hora de reconquistar?"

Esta é a **sexta ocorrência** do mesmo problema (nickname genérico em vez de nome real), depois dos 5 pontos já mapeados em services.py (Batalha, Torcida, convite de Movimento) e do Painel Admin. Isso confirma que corrigir ponto a ponto, conforme cada caso aparece na prática, não é uma estratégia eficiente — o problema está espalhado por partes do código escritas em momentos diferentes.

## 2. Nova regra geral, sem exceção

**Toda e qualquer interação do app que exiba identificação de um usuário para outro usuário — no texto de qualquer tela, notificação push, e-mail, ou qualquer outro canal — deve exibir o nome real do usuário, nunca o apelido genérico "Jogador-XXXXX".**

Isso vale para todo ponto já existente no app (mapeado ou não) e para **todo ponto que vier a ser criado no futuro**, sem exceção e sem precisar de nova aprovação específica cada vez — esta regra passa a valer permanentemente como padrão de desenvolvimento do MENTAL a partir de agora.

O apelido genérico deixa de ter função de exibição para outros usuários. Seu único uso remanescente aceitável é como identificador técnico interno (ex.: chave em banco de dados, log de sistema), nunca como texto visível a uma pessoa.

## 3. Ação solicitada — busca ampla, não mais correção pontual

Em vez de corrigir apenas a notificação de Ranking isoladamente, realizar uma **varredura completa** em todo o código (backend e client) por qualquer ocorrência de `.nickname` (ou campo equivalente) usada em:
- Texto de notificação push.
- Texto exibido em qualquer tela do client.
- Qualquer resposta de API que alimente uma tela onde um usuário vê a identificação de outro.

Aplicar o padrão já estabelecido (`profile.real_name or profile.nickname`, como fallback apenas para o raro caso de nome real ainda não preenchido) em toda ocorrência encontrada, não apenas nas já listadas anteriormente.

## 4. Critério de aceite

- Relatório de busca ampla, listando todas as ocorrências de nickname exibidas a usuário encontradas no código (incluindo a de Ranking, mas não se limitando a ela).
- Todas as ocorrências corrigidas para usar nome real com fallback, sem exceção.
- Regra documentada como padrão permanente de desenvolvimento (ex.: anotação em guia de contribuição/documentação técnica do projeto, se existir), para que qualquer código novo já nasça seguindo essa regra sem precisar de correção posterior.
- Nenhum ponto do app, hoje ou a partir de agora, deve exibir "Jogador-XXXXX" como identificação visível a outro usuário.

## 5. Implementação (12/09/2026)

Varredura ampla feita em todo `backend/` (grep por `.nickname` em todos os
routers/services/notifications) e em todo `client/lib/` (grep por
`nickname` em todas as telas). Achados corrigidos, além da notificação
de Ranking que motivou este documento:

- `backend/app/notifications.py` — `_check_social_overtakes` (a própria
  notificação "O ranking mudou" do print que motivou este documento).
- `backend/app/services.py` — evento de Feed `"battle_won"`
  (`opponent_nickname` no payload, exibido depois no texto "...venceu
  uma Batalha contra {opponent_nickname}").
- `backend/app/routers/challenges.py` — `dethroned_nickname` (campo
  ainda sem consumidor no client, corrigido preventivamente).
- `backend/app/routers/social.py` — `reported_nickname` em
  `GET /admin/reports` (endpoint ainda sem UI no client, corrigido
  preventivamente).

Todos os demais pontos de `.nickname` encontrados na varredura já
tinham o padrão `real_name or nickname` aplicado (correção anterior,
`NOME_REAL_E_FOTO_EM_TODO_LUGAR_V1.md`) ou já enviam `real_name` como
campo irmão pro client escolher — nenhum outro "Jogador-XXXXX" visível
a terceiros foi encontrado.

Regra documentada como padrão permanente no agente `mental-security`
(`.claude/agents/mental-security.md`, checklist de qualidade de código,
item 6) — passa a ser checada em toda revisão futura.

Suíte: 407/407 backend (3 testes estendidos com asserção de nome real).
