# Correção — Curiosidade Relâmpago: dificuldade retroativa dos itens curio-001 a curio-008

**Motivo:** os 7 itens novos (curio-009 a curio-015) têm dificuldade 1:2 / 2:3 / 3:2. Os 8 itens originais (curio-001 a curio-008) não tinham campo `dificuldade`. Sem essa atribuição, a distribuição total não bate o mínimo de 4+ por nível. Esta correção **não adiciona nenhum item novo** — apenas classifica os 8 originais, calibrado pela complexidade real de cada revelação (fatos mais amplamente conhecidos = dificuldade 1; fatos que exigem mais raciocínio ou são menos intuitivos = dificuldade 2/3).

## Atribuição de dificuldade (aplicar no arquivo `curiosidade_relampago.json` já em produção)

| ID | Item | Dificuldade atribuída | Justificativa |
|---|---|---|---|
| curio-001 | Gema de ovo (célula) | 2 | Fato biológico pouco intuitivo, mas com pista já razoavelmente acessível. |
| curio-002 | Honda Cub | 2 | Curiosidade histórica de veículo, exige algum conhecimento de contexto. |
| curio-003 | Diamante (bilhões de anos) | 3 | Conceito de escala de tempo geológico, mais abstrato. |
| curio-004 | Coração (energia própria) | 3 | Fato fisiológico contraintuitivo, exige mais raciocínio. |
| curio-005 | Bússola (campo magnético) | 1 | Fato relativamente simples e conhecido. |
| curio-006 | Cérebro (consumo de energia) | 2 | Fato curioso, mas de complexidade média. |
| curio-007 | Mel (durabilidade) | 1 | Curiosidade simples e amplamente conhecida em cultura geral. |
| curio-008 | Vidro (debate científico) | 3 | Envolve um debate científico genuíno, o mais complexo do lote original. |

## Distribuição final resultante (8 originais + 7 novos = 15, sem alteração de conteúdo)

- Dificuldade 1: curio-005, curio-007 (originais) + curio-009, curio-010 (novos) = 4 itens
- Dificuldade 2: curio-001, curio-002, curio-006 (originais) + curio-011, curio-012, curio-013 (novos) = 6 itens
- Dificuldade 3: curio-003, curio-004, curio-008 (originais) + curio-014, curio-015 (novos) = 5 itens

Total: 15 itens, com 4/6/5 por dificuldade — atende ao mínimo de 4+ em todos os níveis, sem adicionar ou remover nenhum item.

## Instrução para o Claude Code

Adicionar o campo "dificuldade" (valor inteiro 1, 2 ou 3) aos objetos curio-001 a curio-008 já existentes em curiosidade_relampago.json, conforme a tabela acima. Nenhum outro campo desses itens deve ser alterado.
