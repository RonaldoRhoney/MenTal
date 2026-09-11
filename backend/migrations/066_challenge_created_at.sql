-- Selo "Novo" em desafios recém-adicionados (pedido de Rhoney,
-- 06/09/2026, ao ver os 230 desafios do Mundo da Linguagem redistribuídos
-- entre níveis 1/2/3 "misturados" ao conteúdo antigo): created_at NULL
-- pra todo conteúdo já existente (nunca marcado como novo), preenchido
-- automaticamente (default no ORM, ver app/models.py) em toda inserção
-- futura — nenhum script de carga de conteúdo precisa mudar.
alter table mental.challenges
    add column if not exists created_at timestamp null;
