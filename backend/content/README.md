# Curadoria de conteúdo — MENTAL

Esta pasta é onde conteúdo novo de desafio (curado manualmente por Rhoney
ou outra pessoa autorizada — **nunca gerado por IA**, `RISKS_AND_OPEN_DECISIONS.md`
§2) entra no projeto antes de ir pro banco de dados.

## Formato de um arquivo de conteúdo

Um arquivo JSON com uma lista de objetos, cada um representando um
desafio de múltipla escolha:

```json
[
  {
    "territory_id": "conhecimento",
    "subject": "geografia",
    "difficulty_level": 1,
    "prompt": "Qual é a capital do Brasil?",
    "options": ["Rio de Janeiro", "São Paulo", "Brasília", "Salvador"],
    "correct_answer": "Brasília",
    "explanation": "Brasília é a capital federal do Brasil desde 1960.",
    "hints": ["Não é a cidade mais populosa do país.", "Foi inaugurada em 1960."],
    "age_reviewed": true,
    "prompt_image": "🏛️"
  }
]
```

| Campo | Obrigatório | Regra |
|---|---|---|
| `territory_id` | sim | precisa ser um território que já existe (`app/seed.py TERRITORIES`) |
| `subject` | não | só organização/referência (ex.: "geografia", "história") — não é uma coluna do banco hoje, fica solto no arquivo pra facilitar revisão humana |
| `difficulty_level` | sim | `1`, `2` ou `3` |
| `prompt` | sim | pergunta, texto único (não pode repetir um `prompt` já existente no mesmo território, nem dentro do arquivo) |
| `options` | sim | exatamente 4 alternativas, todas diferentes entre si |
| `correct_answer` | sim | precisa ser IDÊNTICO a um dos itens de `options` |
| `explanation` | sim | frase curta explicando a resposta certa |
| `hints` | sim | exatamente 2 dicas progressivas (a segunda mais reveladora que a primeira) |
| `age_reviewed` | sim | `true` só depois de checado manualmente que o conteúdo é apropriado pro público misto (inclusive crianças) do MENTAL — nunca `true` por padrão |
| `prompt_image` | não | um emoji Unicode (ex.: `"🏛️"`) exibido junto com a pergunta — CONHECIMENTO_CONTEUDO_GERAL_E_IMAGEM.md §3, decisão de arquitetura 2026-08-22: só emoji nesta etapa, nunca upload de foto/ilustração real (zero custo, zero risco de direito autoral, mesmo catálogo já usado nos avatares). Omitir o campo (ou deixar `null`) quando a pergunta não precisa de reforço visual — a maioria dos casos. **Imagem nas próprias alternativas de resposta** (§3 do documento, casos 2-3) fica fora desta etapa — mudaria a estrutura de `options`, usada em todo o app; ver V2_KICKOFF.md §11 pro raciocínio completo. |

## Fluxo

1. Curar o conteúdo neste formato num arquivo `backend/content/<nome>.json`
   (ex.: `conhecimento_geral.json`).
2. Validar: `python3 scripts/validate_content.py content/<nome>.json` —
   pega erro de formato ANTES de qualquer coisa tocar o banco. Só valida
   estrutura, nunca julga se o conteúdo em si está certo ou factualmente
   correto (isso é responsabilidade de quem curou).
3. Testar em dev (SQLite local): `python3 scripts/append_production_content.py content/<nome>.json`
   com `MENTAL_DATABASE_URL` apontando pro banco de dev.
4. Só depois de aprovado, rodar o mesmo script contra produção (mesma
   disciplina de sempre: nunca automático, sempre sob execução manual
   explícita).

Diferente de `scripts/seed_production_content.py` (carga ÚNICA inicial,
aborta se `mental.challenges` já tiver qualquer linha),
`append_production_content.py` é incremental — idempotente por
`(territory_id, prompt)`, pula silenciosamente o que já existe, nunca
duplica, e pode ser rodado várias vezes conforme novo conteúdo for
curado ao longo do tempo.

## Pausa para Aprender (V3.2, V3/V3.2_TECNOLOGIA.md §3)

Estrutura de conteúdo DIFERENTE de um desafio — é leitura, sem
options/correct_answer/hints/timer. Arquivo próprio, formato:

```json
[
  {
    "territory_id": "tecnologia_fronteira",
    "difficulty_level": 3,
    "text": "Um modelo de IA generativa não \"sabe\" fatos como um banco de dados — ele aprendeu padrões estatísticos de linguagem a partir de bilhões de exemplos, e prevê a próxima palavra mais provável. É por isso que às vezes ele erra com muita confiança: não está mentindo, está completando um padrão.",
    "age_reviewed": true,
    "prompt_image": "🤖"
  }
]
```

| Campo | Obrigatório | Regra |
|---|---|---|
| `territory_id` | sim | precisa existir (`app/seed.py TERRITORIES`) |
| `difficulty_level` | sim | `1`, `2` ou `3` |
| `text` | sim | texto de leitura curto (§3.3: "rápida e prazerosa", nunca um texto longo que canse) — não pode repetir um `text` já existente no mesmo território |
| `age_reviewed` | sim | mesma disciplina de desafios — `true` só depois de checado manualmente |
| `prompt_image` | não | emoji opcional, mesmo catálogo de sempre |

Fluxo idêntico ao de desafios, só trocando os scripts:
1. Curar em `backend/content/<nome>_pausas.json`.
2. `python3 scripts/append_learning_pauses.py content/<nome>_pausas.json` — valida e insere (já valida por dentro, mesmo padrão de append_production_content.py — aborta sem tocar o banco se algo estiver errado).
3. Testar em dev antes de rodar contra produção, mesma disciplina de sempre.
