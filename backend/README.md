# MENTAL backend — Vertical Slice 01

FastAPI + SQLAlchemy. Segue `docs/01_FOUNDATION/ARCHITECTURE.md`,
`DATA_MODEL.md`, `API_CONTRACT.md` e `SECURITY.md`.

## Rodar localmente

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Banco padrão: SQLite local (`mental_dev.db`), criado e populado (seed dos
4 territórios + desafios de exemplo) automaticamente no startup. Para
apontar para Postgres/Supabase real:

```bash
export MENTAL_DATABASE_URL="postgresql://..."
```

## Autenticação

Projeto Supabase real já provisionado (`daogwiqwqplcvehdhksf`), testado
de ponta a ponta em 2026-08-19 — ver
`docs/02_IMPLEMENTATION/SUPABASE_SETUP.md`. Três modos, em ordem:

1. `SUPABASE_URL` definido → valida o JWT via JWKS (ES256/ECC, chave
   pública do projeto). **Modo real, usado em produção.**
2. `SUPABASE_JWT_SECRET` definido (sem `SUPABASE_URL`) → HS256 legado.
3. Nenhum dos dois → `DEV_INSECURE`: token Bearer tratado como o próprio
   `user_id`. Só para desenvolvimento local — **nunca em produção**.

```bash
export SUPABASE_URL="https://daogwiqwqplcvehdhksf.supabase.co"
export MENTAL_DATABASE_URL="postgresql+psycopg://postgres:<senha>@db.daogwiqwqplcvehdhksf.supabase.co:5432/postgres?options=-csearch_path%3Dmental,public"
```

## Monetização

`MONETIZATION_ENABLED` (env var, default `false`): MENTAL lança 100%
gratuito — ver `MONETIZATION_UPDATE_FREE_LAUNCH.md`. Com `false`, todo
território fica liberado para qualquer usuário, independente de
assinatura. Com `true`, volta a valer o modelo freemium documentado em
`MONETIZATION.md` (território pago exige assinatura após amostra grátis).
Ponto único de verificação: `services.is_territory_unlocked`. Nenhuma
tabela/endpoint de assinatura é removida com a flag desligada — a
estrutura inteira continua existindo, só não é aplicada.

O **limite diário de desafios continua ativo independente da flag**
(`DAILY_FREE_CHALLENGE_LIMIT = 24`, `config.py`) — não é mecanismo de
monetização, é ritmo de uso/retenção via streak.

```bash
export MONETIZATION_ENABLED="true"   # ativa o modelo freemium; default é false
```

## Testes

```bash
python -m pytest -q
```

32 testes cobrindo: age gate / child_safe_mode, core loop completo
(desafio → resposta → XP → progresso), idempotência de `attempt_id`
(incluindo reenvio e tentativa de adulteração), fórmula de penalidade de
dica, amostra grátis em território pago (com `MONETIZATION_ENABLED=true`),
os dois estados da flag de monetização, limite diário gratuito (24/dia),
bypass por assinatura ativa, parental gate (incluindo expiração de 10 min
e revalidação por tentativa de compra), ranking sem exposição de dado
pessoal, e normalização de resposta (case-insensitive + trim) nos 4 tipos
de desafio.
