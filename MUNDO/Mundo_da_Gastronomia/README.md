# Mundo da Gastronomia

**Status:** Implementado no código (07/09/2026) — ver "Arquitetura
implementada" abaixo. Falta rodar a migration e carregar o conteúdo em
produção (ver "Pendências").

## Arquitetura implementada em 07/09/2026

Mesma decisão de arquitetura já usada em Valores/Trânsito: o formato
"cápsula de texto + perguntas" (sem timer, sem penalidade de
velocidade) reaproveita 100% o `Challenge` normal, em vez de criar uma
mecânica nova.

- **Novo World**: `gastronomia` (Mundo da Gastronomia), display_order 14.
- **5 territórios** (migration `068_mundo_gastronomia.sql`), do todo
  pro específico: `gastro_mundo`, `gastro_brasil`,
  `gastro_norte_nordeste`, `gastro_centrooeste_sudeste`,
  `gastro_sul_fusao` — cada "pergunta" de uma cápsula vira um
  `Challenge` normal (difficulty_level fixo em 1, mesmo raciocínio de
  Valores/Trânsito — ver `SINGLE_DIFFICULTY_TERRITORY_IDS` nos testes).
- **Nunca cronometrado, mesmo com `mode=relampago`**: os 5 territórios
  entram em `config.NEVER_TIMED_TERRITORY_IDS` — o backend ignora o
  pedido do client, nunca confia nele pra decidir isso. O client também
  não oferece o botão "Relâmpago" pra esses territórios
  (`kNeverTimedTerritoryIds`, `client/lib/territories.dart`).
- **Conteúdo**: 120 desafios (24 por território, 5 territórios),
  convertidos de `mundo_gastronomia_bloco*.json` (formato bruto:
  cápsulas com texto + perguntas, mesmo formato de Valores/Trânsito)
  via `backend/scripts/convert_gastronomia_content.py` — hints gerados
  automaticamente, carregados direto de
  `backend/content/gastronomia_*.json` no `seed.py` (nunca duplicados
  inline). Zero exclusões na conversão (nenhum prompt duplicado,
  nenhuma opção repetida, nenhuma resposta fora das opções).
- **Curadoria de conteúdo** (ver `meta.checagem_direitos_autorais` e
  `meta.checagem_seguranca` de cada arquivo fonte): todo texto reescrito
  com palavras próprias a partir de fatos verificados, nenhuma
  reprodução literal de fonte; conteúdo cultural/histórico neutro
  (`POLITICA_CONTEUDO_SEGURO_QUALQUER_IDADE.md`) — a lenda da pizza
  Margherita, por exemplo, é apresentada com ressalva explícita de que
  sua veracidade histórica é contestada.
- Testes: `backend/tests/test_gastronomia_content.py` (territórios,
  campo `reading_passage`, nunca cronometrado mesmo com
  `mode=relampago`, fluxo de resposta normal). Suíte backend: 382/382.

## Pendências

- Rodar `migrations/068_mundo_gastronomia.sql` em produção (Supabase
  SQL Editor).
- Rodar `scripts/append_production_content.py` com os 5 arquivos
  `content/gastronomia_*.json` em produção (mesmo fluxo já usado pra
  idiomas/valores/trânsito).
- Testar no dispositivo real antes de considerar o Mundo da
  Gastronomia concluído.
- Ícone/cor de identidade visual do Mundo da Gastronomia na Home: já
  decidido (`Icons.restaurant_rounded`, `client/lib/screens/
  home_screen.dart::_worldIcon`).

## Próximo passo

Confirmar com Rhoney o deploy em produção (migration + carga de
conteúdo) e validar visualmente no app antes de fechar esta etapa.
