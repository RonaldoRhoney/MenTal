# MUNDO/ — conteúdo e histórico do MENTAL

Índice (criado em 20/09/2026, depois da reorganização feita por Rhoney).

- **`Mundo_*/`** — uma pasta por Mundo (16): documentos de arquitetura, fontes brutas de conteúdo (`*.json`) e o README de cada Mundo. Os conversores em `backend/scripts/convert_*.py` leem daqui (`REPO_ROOT / "MUNDO" / "Mundo_x"`).
- **`V1/` … `V4/`** — documentação por versão do produto (kickoffs, bugs, decisões, time de agentes em `V4/`).
- **`video/`** — material do vídeo de instrução para a loja.

Fluxo do conteúdo: fonte bruta em `Mundo_*/` → `backend/scripts/convert_*.py` → `backend/content/*.json` → carregado por `backend/app/seed.py` ou `append_production_content.py`.

Documentos de Mundos **ainda não implementados** ficam na raiz do repositório até serem implementados: `MUNDO_CONCURSOS_ARQUITETURA_V1.md`, `MUNDO_LINGUAGEM_ARQUITETURA_V1.md`, `MUNDO_IDIOMAS_NOVOS_TEMAS_AGENTE_V1.md`.

Regras e documentos de engenharia: `../Engenharia_Geral/` (regra oficial de gamificação em `REGRA_OFICIAL_GAMIFICACAO_MENTAL.md`).
