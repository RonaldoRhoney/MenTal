-- NOTIFICACAO_CONTEUDO_ATUALIZADO_V1.md (19/09/2026, aprovado) — nova
-- notificação na Central avisando qual Mundo/SubMundo/Território teve
-- conteúdo atualizado desde o último login. Decisão explícita de
-- Rhoney: null aqui para todo território existente (não retroagir a
-- auditoria de conteúdo já feita antes desta feature) — a coluna só
-- passa a ser preenchida a partir de agora, por
-- services.touch_territory_content_updated(), chamada pelos scripts de
-- carga/correção de conteúdo.

alter table mental.territories add column if not exists content_updated_at timestamp;
