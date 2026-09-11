# Mundo do Trânsito (V7)

**Status:** Implementado e em produção (06/09/2026) — código, migration
065, carga de conteúdo e deploy confirmados por Rhoney. Falta só o
ícone/cor de identidade visual na Home (ver "Pendências").

## Arquitetura implementada em 06/09/2026

Mesma decisão de arquitetura já usada no Mundo dos Valores: o formato
"cápsula de texto + perguntas" (sem timer, sem penalidade de
velocidade) reaproveita 100% o `Challenge` normal, em vez de criar uma
mecânica nova.

- **Novo World**: `transito` (Mundo do Trânsito), display_order 7.
- **5 territórios** (migration `065_mundo_transito.sql`):
  `educacao_legislacao`, `historia_curiosidades`,
  `transportes_terrestres`, `economia_transito`, `prevencao_seguranca`
  — cada "pergunta" de uma cápsula vira um `Challenge` normal
  (difficulty_level fixo em 1, mesmo raciocínio de idiomas/valores —
  ver `SINGLE_DIFFICULTY_TERRITORY_IDS`).
- **Nunca cronometrado, mesmo com `mode=relampago`**: os 5 territórios
  entram em `config.NEVER_TIMED_TERRITORY_IDS` — o backend ignora o
  pedido do client, nunca confia nele pra decidir isso. O client também
  não oferece o botão "Relâmpago" pra esses territórios
  (`kNeverTimedTerritoryIds`, `client/lib/territories.dart`).
- **Conteúdo**: 120 desafios (24 por território, 5 territórios),
  convertidos de `mundo_do_transito_bloco*.json` (formato bruto:
  cápsulas com texto + perguntas, mesmo formato de Valores) via
  `backend/scripts/convert_transito_content.py` — hints gerados
  automaticamente, carregados direto de `backend/content/transito_*.json`
  no `seed.py` (nunca duplicados inline). Zero exclusões na conversão
  (nenhum prompt duplicado, nenhuma opção repetida, nenhuma resposta
  fora das opções).
- **Curadoria de conteúdo** (ver `meta.principio` de cada arquivo
  fonte): sempre factual, sem opinião sobre severidade de lei, sem
  viés a favor/contra grupo de condutor, sem detalhe gráfico de
  acidente nem estatística de mortes/feridos — o bloco de prevenção
  (`bloco5_prevencao.json`) foi revisado com rigor redobrado por ser o
  mais sensível ("conscientizar, nunca assustar").
- Testes: `backend/tests/test_transito_content.py` (territórios, campo
  `reading_passage`, nunca cronometrado mesmo com `mode=relampago`,
  fluxo de resposta normal). Suíte backend: 360/360.

## Pendências

- ~~Rodar `migrations/065_mundo_transito.sql` em produção~~ — feito,
  confirmado por Rhoney.
- ~~Rodar `scripts/append_production_content.py` com os 5 arquivos
  `content/transito_*.json` em produção~~ — feito, confirmado por
  Rhoney ("deploy ok").
- ~~Ícone/cor de identidade visual do Mundo do Trânsito na Home~~ —
  decidido junto da implementação do carrossel de Mundos
  (REORGANIZACAO_MENUS_HOME_V1.md §9, 06/09/2026): `Icons.traffic_rounded`,
  cor dourada padrão dos cards de Mundo (`_worldIcon` em
  `client/lib/screens/home_screen.dart`).
- Testar no dispositivo real (visual do card do carrossel + conteúdo)
  antes de considerar o Mundo do Trânsito 100% fechado.

## Próximo passo

Validar visualmente no app real (device de teste) antes de fechar esta
etapa por completo.
