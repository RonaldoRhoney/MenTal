# Mundo dos Oceanos

**Status:** Implementado no código (07/09/2026) — ver "Arquitetura
implementada" abaixo. Falta rodar a migration e carregar o conteúdo em
produção (ver "Pendências").

## Arquitetura implementada em 07/09/2026

Mesma decisão de arquitetura já usada em Valores/Trânsito/Gastronomia:
o formato "cápsula de texto + perguntas" (sem timer, sem penalidade de
velocidade) reaproveita 100% o `Challenge` normal, em vez de criar uma
mecânica nova.

- **Novo World**: `oceanos` (Mundo dos Oceanos), display_order 15.
- **5 territórios** (migration `069_mundo_oceanos.sql`), do todo pro
  específico: `oceano_mundo`, `oceano_vida_marinha`,
  `oceano_profundezas`, `oceano_clima`, `oceano_brasil` — cada
  "pergunta" de uma cápsula vira um `Challenge` normal (difficulty_level
  fixo em 1, mesmo raciocínio de Valores/Trânsito/Gastronomia — ver
  `SINGLE_DIFFICULTY_TERRITORY_IDS` nos testes).
- **Nunca cronometrado, mesmo com `mode=relampago`**: os 5 territórios
  entram em `config.NEVER_TIMED_TERRITORY_IDS` — o backend ignora o
  pedido do client, nunca confia nele pra decidir isso. O client também
  não oferece o botão "Relâmpago" pra esses territórios
  (`kNeverTimedTerritoryIds`, `client/lib/territories.dart`).
- **Conteúdo**: 120 desafios (24 por território, 5 territórios),
  convertidos de `mundo_oceanos_bloco*.json` (formato bruto: cápsulas
  com texto + perguntas, mesmo formato de Valores/Trânsito/Gastronomia)
  via `backend/scripts/convert_oceanos_content.py` — hints gerados
  automaticamente, carregados direto de `backend/content/oceanos_*.json`
  no `seed.py` (nunca duplicados inline). Zero exclusões na conversão
  (nenhum prompt duplicado, nenhuma opção repetida, nenhuma resposta
  fora das opções).
- Testes: `backend/tests/test_oceanos_content.py` (territórios, campo
  `reading_passage`, nunca cronometrado mesmo com `mode=relampago`,
  fluxo de resposta normal).

## Pendências

- Rodar `migrations/069_mundo_oceanos.sql` em produção (Supabase SQL
  Editor).
- Rodar `scripts/append_production_content.py` com os 5 arquivos
  `content/oceanos_*.json` em produção (mesmo fluxo já usado pra
  idiomas/valores/trânsito/gastronomia).
- Testar no dispositivo real antes de considerar o Mundo dos Oceanos
  concluído.
- Ícone/cor de identidade visual do Mundo dos Oceanos na Home: já
  decidido (`Icons.waves_rounded`, `client/lib/screens/
  home_screen.dart::_worldIcon`).

## Próximo passo

Confirmar com Rhoney o deploy em produção (migration + carga de
conteúdo) e validar visualmente no app antes de fechar esta etapa.
