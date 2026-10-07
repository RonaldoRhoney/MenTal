# MENTAL — Par Perfeito: Diagnóstico Técnico e Proposta

Companion de `MUNDO_IDIOMAS_INGLES_PAR_PERFEITO_V1.md` (aprovado 05/10/2026) — resposta ao §14 daquele documento ("escopo técnico a propor em detalhe por Claude Code"). **Nada aqui foi implementado** — é proposta, aguardando decisão de Rhoney nos pontos marcados.

---

## 1. Por que não reaproveita o modelo `Challenge` existente

Toda frente do Mundo dos Idiomas até hoje (Phrasal Verbs, Preposições, Listening Ativo, Discurso Indireto, Gírias, AmE/BrE) usa o mesmo molde: uma pergunta (`prompt`), 4 alternativas (`options`), uma resposta certa (`correct_answer`). Mesmo os formatos "especiais" (Detetive Mental com `clues`, Ouvido Afiado com `audio_url`, Mundo dos Valores com `reading_passage`) são esse mesmo molde com um campo opcional a mais.

Par Perfeito **não cabe nesse molde**, por dois motivos:
1. **Pares de cards** (formato central, §3) não é pergunta-e-resposta — é combinar dois itens de duas colunas. Não existe "a alternativa certa entre 4".
2. Um mesmo par (ex.: *ship/sheep*) pode aparecer em **formatos diferentes** (pares de cards, ouça e escolha, qual soa diferente) — o conteúdo curado é o **par em si** (palavra + IPA por sotaque + fontes), não uma pergunta fixa. A pergunta é derivada do par conforme o formato, igual a Constelação de Palavras já deriva sua rodada a partir de `Challenge.correct_answer` sem guardar estado.

**Proposta:** nova tabela `par_perfeito_items` (conteúdo curado) + endpoints que **derivam** a rodada de cada formato a partir dela, no mesmo espírito do já existente `GET /challenges/{id}/word-constellation` (deriva de `Challenge`, nunca persiste o que foi mostrado).

## 2. Estrutura de dados proposta

```
ParPerfeitoItem
  id (uuid)
  territory_id        — território desta família/nível (ver §5)
  tipo                — "homofono" | "par_minimo" | "homografo" | "confundivel" | "ough" | "dependente_sotaque"
  nivel               — 1 (básico) | 2 (intermediário) | 3 (avançado) — já existe o mesmo campo em Challenge
  palavra_a, palavra_b          — o par (palavra_b nulo nos formatos de palavra única, ex. homógrafo com 2 pronúncias da MESMA grafia)
  ipa_a_us, ipa_a_uk            — transcrição fonética de palavra_a, por sotaque (um dos dois pode faltar se não documentado)
  ipa_b_us, ipa_b_uk            — idem pra palavra_b, quando existir
  significado_pt                — significado em português (nível básico/intermediário)
  significado_en                — significado em inglês (nível avançado, §4 do doc principal)
  frase_apoio                   — frase original (nunca copiada de dicionário, §5.6)
  dica                          — "por que soa parecido" (fecho de rodada, §3)
  etiqueta_sotaque               — "us" | "uk" | "universal"
  fontes (JSON)                  — lista de {nome, url, trecho_conferido} — mínimo 2 por afirmação de som (§5.2)
  audio_fonte                    — "tts" | "gravacao_licenciada" (§6, fallback quando a voz sintética falha no teste)
  audio_licenciado_url/source_name/source_url  — preenchido só quando audio_fonte = gravacao_licenciada
  age_reviewed
  created_at
```

Reaproveita o padrão **tudo-ou-nada** já usado em `audio_url`/`vocab_media_url` do `Challenge` (ex.: `audio_licenciado_url` só existe com as duas fontes preenchidas).

## 3. Como cada formato deriva da mesma tabela

| Formato (§3 do doc) | Como deriva de `ParPerfeitoItem` | Precisa de quê novo |
|---|---|---|
| Pares de cards | `palavra_a` + `significado_pt/en` nas duas colunas | Endpoint que sorteia N itens do nível + componente de UI de "ligar" (linha de luz ao acertar, §9) |
| Ouça e ligue | `palavra_a` (texto) + áudio (TTS ou licenciado) | Mesmo endpoint acima, variação de card (ícone de áudio em vez de texto) |
| Qual soa diferente? | 3 `palavra_a` de **pares mínimos** do mesmo grupo fonético, 2 compartilham o som-alvo | Agrupamento por "grupo mínimo" — precisa de um campo extra `grupo_minimo_id` pra saber quais 3 formam o trio |
| Ouça e escolha | `palavra_a` x `palavra_b` como as 2-3 opções, áudio de uma delas | Reaproveita bastante a estrutura de MCQ existente |
| Complete a frase | `frase_apoio` com lacuna + `palavra_a`/`palavra_b` como opções | Mais próximo do `Challenge` tradicional — candidato a usar a tabela normal `challenges` em vez de `par_perfeito_items`, ver §4 |
| Pronúncia por sentido | `palavra_a` (homógrafo) com 2 leituras (`ipa_a_us` dobrado em 2 variantes, ex. "read" presente/passado) — **esse caso pede um 2º par de IPA pro mesmo `palavra_a`**, revisar modelo | A definir com Rhoney (ver pergunta 3 abaixo) |
| Compare os sotaques | `ipa_a_us` x `ipa_a_uk` lado a lado, 2 áudios (voz EUA + voz Reino Unido) | Reaproveita o mesmo item, troca só a apresentação |

**Achado ao desenhar isso:** o formato **"Pronúncia por sentido"** (homógrafos tipo *read/lead/wind*) precisa de **duas pronúncias para a MESMA palavra_a**, o que a estrutura acima (1 campo IPA por idioma) não comporta bem. Proposta: homógrafos usam `palavra_b = palavra_a` (mesma grafia) e os pares `ipa_a_*`/`ipa_b_*` guardam as duas leituras — funciona, mas é uma convenção que precisa ficar documentada pra não confundir a curadoria.

## 4. "Complete a frase" pode não precisar de tabela nova

Esse formato especificamente (§3: "Lacuna com to/too/two, their/there etc.") é estruturalmente **idêntico** ao MCQ já usado em Preposições e Artigos — pergunta com lacuna, 4 alternativas, 1 certa. **Pergunta pra Rhoney:** esse formato pode entrar como território MCQ comum (`challenges`, reaproveitando 100% o pipeline de curadoria/deploy já existente), e só os outros 6 formatos usam a tabela nova? Isso reduziria a complexidade do primeiro lote.

## 5. Onde entra na sequência do Inglês (§4 do doc principal — pergunta em aberto)

Levantamento do bloco "ingles" hoje: 10 famílias já existem (vocabulário clássico, Phrasal Verbs, Expressões, Conjugação, Compostas, Contrações, Compreensão, Falsos Cognatos, Preposições, Listening, Discurso Indireto, Gírias, AmE/BrE — cada uma com sua própria sequência Básico→Intermediário→Avançado→Relâmpagos, independente das demais, via o mecanismo de família por sufixo de nome já existente).

**Proposta: Par Perfeito vira mais uma família independente**, mesmo padrão — `ingles_parperfeito_basico/intermediario/avancado` [+ `_relampago_*`], sequenciada sozinha, sem depender de nenhuma outra família terminar primeiro. É a opção que não exige nenhuma mudança no mecanismo de progressão já implementado (ele já suporta famílias múltiplas dentro do mesmo bloco) e mantém a liberdade do jogador de escolher qualquer família pra começar.

## 6. Seleção de voz por sotaque — precisa de validação técnica real

Hoje `idioma_voices.dart` só usa `en-US-AriaNeural` pra todo o inglês. O catálogo do Edge TTS (usado pelo `flutter_edge_tts` já em produção) inclui vozes britânicas (ex.: `en-GB-SoniaNeural`, `en-GB-RyanNeural`), mas **isso precisa ser testado de verdade antes de prometer no produto** — mesma disciplina já seguida quando o TTS foi integrado originalmente (MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md §2.1: "validar tecnicamente a integração antes de comprometer a arquitetura final, incluindo teste real de qualidade de voz"). Não vou afirmar que uma voz soa bem sem ouvir.

**Proposta de arquitetura** (genérica, consistente com o §2.3 do doc de áudio original — idioma/sotaque como parâmetro, nunca hardcoded): `idioma_voices.dart` ganha um mapa por sotaque em vez de 1 voz fixa por idioma:
```dart
const Map<String, Map<String, String>> _kVozesPorSotaque = {
  'ingles': {'us': 'en-US-AriaNeural', 'uk': 'en-GB-SoniaNeural'},
};
```
com fallback pra `us` em qualquer território de Inglês que não seja Par Perfeito (preserva 100% o comportamento atual do resto do Mundo dos Idiomas).

## 7. Preferência de sotaque do usuário

§6 do doc principal: "o usuário pode escolher o sotaque que quer treinar". Proposta mínima: um toggle US/UK local à tela de Par Perfeito (guardado via `SharedPreferences`, mesmo padrão de `WorldCelebrationService`/`OnboardingTutorialService`) — não precisa de campo novo no perfil do backend, é preferência de exibição, não de progresso.

## 8. Regra de XP "só na 1ª tentativa" — precisa de aprovação própria antes de valer

O doc principal (§10) já registra isso como **proposta**, não regra decidida: *"Qualquer recompensa adicional exige revisão formal da Regra Oficial."* Confirmando: essa regra **não entra em vigor só por estar neste documento** — precisa virar uma entrada formal em `Engenharia_Geral/REGRA_OFICIAL_GAMIFICACAO_MENTAL.md`, com a mesma aprovação explícita de Rhoney que toda mudança de XP já passa (e revisão do agente `mental-security`, por mexer em XP). Registro aqui só pra não esquecer — não vou implementar o cálculo de XP do Par Perfeito até essa aprovação separada acontecer.

## 9. Pipeline do agente de curadoria — registro de fonte e relatório de descartados

Reaproveita a mesma disciplina já usada no resto do app (JSON de lote + `content_validation.py`), com validações **novas e mais rígidas** por causa do §5 do doc principal:
- Todo item precisa de `fontes` com 2+ entradas preenchidas antes de entrar no lote (validação estrutural, não de conteúdo — o agente de curadoria é quem garante que as fontes são reais, aqui só garante que o campo não está vazio).
- Itens sem confirmação de 2 fontes **não entram no lote** — ficam numa lista separada "descartados por falta de fonte", reportada a Rhoney junto com o lote (não silenciosamente ignorados).

## 10. Integração com Constelação de Palavras — risco de redundância (§9 do doc principal)

A Constelação de Palavras já testa reconhecimento de significado (palavra→PT) ou reconstrução por peças, ao final de qualquer Desafio de Idiomas. O formato **"Pares de cards"** do Par Perfeito é conceitualmente parecido (ligar palavra a significado). **Avaliação:** não acho que compete de verdade — Constelação é um *bônus rápido pós-desafio* sobre o item que acabou de ser respondido; Par Perfeito é o *desafio principal*, com conteúdo curado especificamente pra pares confundíveis. Ambos continuam coexistindo sem conflito, mas recomendo **não aplicar Constelação de Palavras ao final de um Desafio de Par Perfeito** (ficaria redundante demais, dois "jogos de ligar" seguidos) — proponho isso como exceção explícita, a confirmar.

## 11. Formato do lote de revisão e fasamento proposto

Dado o volume de trabalho novo (tabela nova, 7 componentes de UI, validação de voz), recomendo **fasear a entrega** em vez de construir tudo de uma vez:

- **Fase A (mecanismo + 1º lote pequeno):** estrutura de dados, os formatos mais simples de construir primeiro (Ouça e escolha, Complete a frase — se a pergunta 4 for "sim", esse nem precisa de tabela nova), validação de voz UK, ~15-20 pares por nível (45-60 no total) pra Rhoney revisar o formato e a qualidade antes de ir fundo.
- **Fase B:** formatos restantes (Pares de cards com a animação de linha de luz, Qual soa diferente, Pronúncia por sentido, Compare os sotaques) + resto do volume até as 150 unidades propostas no §8 do doc principal.

## 12. Perguntas que preciso que você responda antes de eu propor implementação

1. **"Complete a frase" vira território MCQ comum** (reaproveitando `challenges`) e só os outros 6 formatos usam a tabela nova, ou todos os 7 usam a estrutura nova por consistência?
2. **Fasear em A/B como proposto no §11**, ou prefere tudo de uma vez?
3. Pra homógrafos (mesma grafia, 2 pronúncias — *read/lead/wind*), confirma a convenção `palavra_b = palavra_a` com os 2 pares de IPA guardando as duas leituras (§3, achado)?
4. Autorizo eu **testar tecnicamente** a voz `en-GB-SoniaNeural` (ou equivalente) antes de prosseguir, reportando qualidade real como foi feito na integração original do TTS?

Nenhuma implementação começa até essas 4 respostas.
