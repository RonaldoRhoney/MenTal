# MENTAL — V4 item 3: Redação

**Status:** Implementado e commitado (02/09/2026).
**Documento de origem:** `V4/V3_ENCERRAMENTO_PENDENCIAS_PARA_V4.md` §2.1 — Redação foi prometida em V3.1 pra V3.4, promessa nunca cumprida (V3.4 foi reformulado só pra Libras). Sem rascunho de mecânica aproveitável; este documento formaliza a decisão tomada ao implementar.

---

## 1. Decisão de mecânica

Múltipla escolha sobre **técnica de escrita** — mesmo formato de todos os outros territórios do MENTAL (`Challenge`: prompt + 4 opções + resposta correta + explicação + 2 dicas). Decisão tomada em 02/09/2026, confirmada com Rhoney entre duas alternativas:

- ❌ Pausa para Aprender + quiz de fixação (sugestão original do documento de encerramento da V3) — não escolhida.
- ✅ **Múltipla escolha direta sobre técnica** — escolhida.

Motivo: nenhum território do MENTAL hoje pede texto livre do usuário nem avalia redação alheia — introduzir isso exigiria moderação de conteúdo gerado por usuário em tempo real, uma superfície de risco muito maior que qualquer coisa já implementada no app (mesmo raciocínio já registrado em `PERFIL_PUBLICO_E_TORCIDA_V1.md` §5 pra descartar "ajudar" com mensagem livre). Múltipla escolha sobre técnica ensina o conceito sem essa exposição.

## 2. Escopo de conteúdo

Território `redacao`, Mundo da Linguagem (ao lado de Palavras/Textos/Enigmas — é sobre língua portuguesa/escrita, não trivia geral). 18 desafios curados (6 por nível de dificuldade 1-3, acima do piso de 15 total / 4 por nível exigido por `test_content_volume.py`):

- **Nível 1 (básico):** papel da introdução/tese/conclusão, o que é um parágrafo, o que é coesão, identificar redundância simples.
- **Nível 2 (intermediário):** coesão vs. coerência, tópico frasal, generalização vaga, argumento de autoridade, conectivos de oposição, repetição excessiva.
- **Nível 3 (avançado):** contra-argumentação, raciocínio circular, registro formal x informal, proposta de intervenção (estilo ENEM), falácia do espantalho.

Conteúdo escrito e revisado nesta sessão (`age_reviewed: true` em cada item), seguindo a mesma disciplina de conteúdo factualmente estável e sem ambiguidade já aplicada a outros territórios de trivia/técnica.

## 3. Escopo técnico

Reaproveita 100% a arquitetura de `Challenge` já existente — nenhuma coluna, tabela ou mecânica nova. Só:
- `TERRITORIES` (`backend/app/seed.py`): novo território `redacao`, `world_id="linguagem"`, `display_order=34` (33 reservado pro território "cruzadas", ainda em WIP não commitado).
- `CHALLENGES`: 18 itens novos.
- Migration `050_v4_redacao.sql` (Postgres de produção — `insert ... on conflict do nothing`).
- Client: `territories.dart` (id + label), `app_pt.arb` (`territoryRedacao`).

## 4. Critério de aceite

- Território aparece no Mundo da Linguagem, junto de Palavras/Textos/Enigmas.
- 18 desafios, 6 por nível de dificuldade — acima do piso de `test_content_volume.py`.
- Nenhum campo de texto livre do usuário em nenhum desafio.
- `test_worlds.py` atualizado pra refletir os 4 territórios do Mundo da Linguagem (antes 3).
- Suíte de testes de backend passando por completo com o território novo.
