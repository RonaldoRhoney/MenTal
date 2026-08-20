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

## Autenticação (gap conhecido do V1)

Não existe ainda projeto Supabase provisionado para o MENTAL. Sem a
variável `SUPABASE_JWT_SECRET` definida, o backend roda em modo
`DEV_INSECURE` (`app/auth.py`): o token Bearer enviado é tratado
diretamente como `user_id`. **Nunca rodar assim em produção** — ver
`docs/02_IMPLEMENTATION/VERTICAL_SLICE_01_REPORT.md` para o plano de
substituição por Supabase Auth real.

## Testes

```bash
python -m pytest -q
```

16 testes cobrindo: age gate / child_safe_mode, core loop completo
(desafio → resposta → XP → progresso), idempotência de `attempt_id`
(incluindo reenvio e tentativa de adulteração), fórmula de penalidade de
dica, amostra grátis em território pago, limite diário gratuito,
bypass por assinatura ativa, parental gate, e ranking sem exposição de
dado pessoal.
