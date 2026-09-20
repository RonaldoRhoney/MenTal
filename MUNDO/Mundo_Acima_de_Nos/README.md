# Mundo Acima de Nós (Espaço)

**Status:** Implementado no código (07/09/2026) — ver "Arquitetura
implementada" abaixo. Falta rodar a migration e carregar o conteúdo em
produção (ver "Pendências"). Nome da pasta sem acento/parênteses por
convenção de nome de diretório; o nome oficial do Mundo, "Mundo Acima
de Nós (Espaço)", é o que aparece na Home/documentação de produto.

## Arquitetura implementada em 07/09/2026

Mesma decisão de arquitetura já usada em Valores/Trânsito/Gastronomia/
Oceanos: o formato "cápsula de texto + perguntas" (sem timer, sem
penalidade de velocidade) reaproveita 100% o `Challenge` normal, em vez
de criar uma mecânica nova.

- **Novo World**: `espaco` (Mundo Acima de Nós (Espaço)), display_order
  16.
- **5 territórios** (migration `070_mundo_espaco.sql`), do todo pro
  específico: `espaco_universo`, `espaco_planetas`, `espaco_estrelas`,
  `espaco_exploracao`, `espaco_brasil` — cada "pergunta" de uma cápsula
  vira um `Challenge` normal (difficulty_level fixo em 1, mesmo
  raciocínio de Valores/Trânsito/Gastronomia/Oceanos — ver
  `SINGLE_DIFFICULTY_TERRITORY_IDS` nos testes).
- **Nunca cronometrado, mesmo com `mode=relampago`**: os 5 territórios
  entram em `config.NEVER_TIMED_TERRITORY_IDS` — o backend ignora o
  pedido do client, nunca confia nele pra decidir isso. O client também
  não oferece o botão "Relâmpago" pra esses territórios
  (`kNeverTimedTerritoryIds`, `client/lib/territories.dart`).
- **Diferenciação do território "astronomia"** (Mundo da Descoberta):
  confirmado via `scripts/validate_content.py` que nenhum prompt deste
  lote colide com o de "astronomia" — são conteúdos distintos, sem
  duplicação.
- **Conteúdo**: 119 desafios (24 por território, exceto
  `espaco_exploracao` com 23), convertidos de
  `mundo_espaco_bloco*.json` (formato bruto: cápsulas com texto +
  perguntas) via `backend/scripts/convert_espaco_content.py` — hints
  gerados automaticamente, carregados direto de
  `backend/content/espaco_*.json` no `seed.py` (nunca duplicados
  inline). 1 exclusão na conversão: um prompt idêntico apareceu ENTRE
  dois blocos do próprio lote fonte (`bloco3_estrelas` x
  `bloco4_exploracao`) — a safety net de dedupe do script excluiu a
  segunda ocorrência automaticamente, nunca chegou a duplicar no banco.
- Testes: `backend/tests/test_espaco_content.py` (territórios, campo
  `reading_passage`, nunca cronometrado mesmo com `mode=relampago`,
  fluxo de resposta normal, contagem exata de 119 desafios).
- Nome oficial não segue o padrão "Mundo da/do/dos/das" usado pelos
  outros Mundos — `_shortWorldTitle()` (`client/lib/screens/
  home_screen.dart`) ganhou um caso especial pra este Mundo, mapeando
  pro rótulo curto "Espaço" no card compacto do carrossel da Home.

## Pendências

- Rodar `migrations/070_mundo_espaco.sql` em produção (Supabase SQL
  Editor).
- Rodar `scripts/append_production_content.py` com os 5 arquivos
  `content/espaco_*.json` em produção (mesmo fluxo já usado pra
  idiomas/valores/trânsito/gastronomia/oceanos).
- Testar no dispositivo real antes de considerar o Mundo Acima de Nós
  (Espaço) concluído.
- Ícone de identidade visual na Home: já decidido
  (`Icons.rocket_launch_rounded`, `client/lib/screens/
  home_screen.dart::_worldIcon`).

## Próximo passo

Confirmar com Rhoney o deploy em produção (migration + carga de
conteúdo) e validar visualmente no app antes de fechar esta etapa.
