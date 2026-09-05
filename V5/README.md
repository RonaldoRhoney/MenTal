# V5

**Status:** Encerrada em 04/09/2026. Mundo dos Idiomas em produção —
migração aplicada, 520 desafios carregados, backend deployado, testado
no dispositivo real (pergunta de vocabulário + desafio de tradução com
`accepted_answers`, XP concedido corretamente, sem crash).

## Mundo dos Idiomas — arquitetura implementada em 04/09/2026

- 9 territórios (não um só "idiomas" com sub-navegação): `ingles_basico`,
  `ingles_intermediario`, `ingles_avancado`, `espanhol_basico`,
  `espanhol_intermediario`, `espanhol_avancado`, `frances_basico`,
  `frances_intermediario`, `frances_avancado` — cada nível é um
  território próprio, com progresso/XP independente, mesmo padrão do
  resto do app. Novo World `idiomas` (`migrations/060_mundo_idiomas.sql`).
- Requer assinatura, com 3 tentativas grátis por território
  (`requires_subscription=true`, `free_sample_count=3`), igual ao padrão
  do resto do conteúdo denso do app.
- Desafio de tradução em texto livre ganhou suporte a mais de uma
  resposta correta: campo novo `Challenge.accepted_answers` (JSON,
  opcional), comparado em `services.is_submitted_answer_correct()`. Ver
  `backend/content/README.md` §"Desafio de texto livre".
- Conteúdo bruto (`mundo_dos_idiomas_*.json`, formato de blocos) é
  convertido pro formato plano do app via
  `backend/scripts/convert_idiomas_content.py`, que também GERA hints
  automaticamente (o arquivo bruto não tinha esse campo — decisão:
  gerar genéricas em vez de bloquear o lançamento, ex.: "É uma palavra
  do tema 'Em casa'." / "Começa com 'H'."). Resultado em
  `backend/content/idiomas_*.json`, carregado por `app/seed.py`
  diretamente (não duplicado inline como o resto do arquivo — divergência
  deliberada do padrão, pra não arrastar ~1500 linhas de texto repetido e
  nunca divergir da fonte usada em produção).

### 20 itens excluídos por bug de curadoria na fonte original

O conversor detecta e pula automaticamente (nunca entram no banco):
18 itens com uma alternativa duplicada dentro de `options` (a resposta
certa aparecia 2x na lista, ex. `['Work', 'Work', 'Werk', 'Wrok']`), 1
prompt repetido entre `ingles_intermediario`/`ingles_avancado` (mesma
frase "a menos que" ensinada duas vezes) e 1 prompt duplicado dentro do
próprio `frances_avancado` (item "... novamente para fixar em
francês?", claramente um preenchimento acidental). Rodar o script de
novo (`cd backend && python3 scripts/convert_idiomas_content.py`)
imprime a lista completa com território e motivo de cada exclusão. Se
algum dia corrigir a fonte (`V5/mundo_dos_idiomas_*.json`), o item volta
a entrar automaticamente na próxima conversão.

### Testes

- Backend: `test_idiomas_content.py` (accepted_answers aceita variação,
  rejeita resposta fora do conjunto) + `test_content_volume.py` (piso de
  volume, com exceção documentada pra não exigir 3 níveis de dificuldade
  DENTRO de um território que já É um nível) + `test_worlds.py`
  (mundo novo aparece em `/progress`).
- Client: rótulos dos 9 territórios em `territories.dart` +
  `app_pt.arb`. Nenhuma tela nova precisou ser escrita — Home já lista
  Mundos genericamente, e o desafio de texto livre já reaproveita o
  mesmo campo de texto usado no anagrama de "palavras".

## Concluído em produção (04/09/2026)

1. ✅ Migração `060_mundo_idiomas.sql` rodada no Supabase.
2. ✅ 520 desafios carregados via `append_production_content.py` (não
   521 como uma versão anterior deste documento dizia — a exclusão
   global de prompt duplicado entre níveis, seção acima, pegou mais um
   item depois daquela contagem inicial).
3. ✅ Backend deployado no Render.
4. ✅ Testado no dispositivo real: "Mundo dos Idiomas" aparece na Home
   com os 9 territórios rotulados corretamente; pergunta de vocabulário
   (múltipla escolha) funciona normal; desafio de tradução aceitou a
   variação "He drives very fast on the street." (com ponto final,
   diferente do `correct_answer` exato) como correta, XP concedido, sem
   crash no logcat.

## Candidatos registrados (herdados de V4_NOVOS_TERRITORIOS.md §6, ainda sem dono de fase)

Ideias adiadas em fases anteriores, sem mecânica nem conteúdo desenhados
ainda — revisar se algum deles vira o escopo da V6:

- Inteligência Emocional e Habilidades Socioemocionais (exige desenho pedagógico mais cuidadoso — risco de parecer conselho/diagnóstico se mal curado).
- Decifra o Símbolo (decodificação visual de ícones e sinais do mundo real).
- Corpo Humano em Profundidade (funcionamento biológico, distinto de Saúde e Bem-estar).
- Bandeiras, Mapas e Geografia do Mundo.
- Dinheiro e Objetos que Mudaram de Valor (curiosidade histórica/anedótica, distinta de Finanças Pessoais).
