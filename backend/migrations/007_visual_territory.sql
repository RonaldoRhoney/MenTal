-- MENTAL — V2 item 4: Desafios visuais (V2_KICKOFF.md §6A)
-- Rodar no SQL Editor do projeto Supabase DEPOIS de 006_textos_territory.sql.
-- Nenhuma tabela/coluna nova, nenhum Storage/bucket — decisão de
-- armazenamento (confirmada com Rhoney antes de implementar, régua
-- Free-First): as opções visuais são ícones vetoriais do próprio
-- Flutter, codificados como string no campo "options" já existente
-- (formato "forma_preenchimento_cor_índice"), zero custo com certeza
-- absoluta. Mesmo padrão de 001/005/006: conteúdo do desafio não é
-- migrado via SQL, só o território (ver backend/app/seed.py).

insert into mental.territories (id, challenge_type, requires_subscription, free_sample_count, display_order) values
    ('visual', 'visual', true, 2, 7)
on conflict (id) do nothing;
