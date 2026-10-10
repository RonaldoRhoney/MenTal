-- Par Perfeito de Inglês — formato "Pares de cards" (Fase B, pedido de
-- Rhoney 08-09/10/2026: "não está como eu queria", com imagem de
-- referência do formato de 2 colunas de cards). MUNDO_IDIOMAS_INGLES_
-- PAR_PERFEITO_V1.md §3/§14 — tabela nova (não reaproveita Challenge,
-- mesmo raciocínio de word_puzzles em 045_jogos_de_palavras_caca_
-- palavras.sql: a rodada inteira é visível desde o início, sem resposta
-- escondida pra proteger).
--
-- CONTEÚDO carregado DEPOIS, via scripts/append_production_
-- par_perfeito_items.py content/par_perfeito_ingles_basico_lote1.json.

create table if not exists mental.par_perfeito_items (
    id uuid primary key,
    territory_id varchar not null references mental.territories(id),
    difficulty_level integer not null default 1,
    word_en varchar not null,
    meaning_pt varchar not null,
    age_reviewed boolean not null default false
);

create table if not exists mental.par_perfeito_matches (
    id uuid primary key,
    user_id uuid not null,
    item_id uuid not null references mental.par_perfeito_items(id),
    xp_awarded integer not null default 0,
    created_at timestamp not null default now()
);

create index if not exists ix_par_perfeito_matches_user_id on mental.par_perfeito_matches (user_id);
