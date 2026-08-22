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
    "age_reviewed": true
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
