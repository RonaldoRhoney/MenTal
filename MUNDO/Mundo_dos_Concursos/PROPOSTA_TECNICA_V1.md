# Mundo dos Concursos — Proposta técnica V1 (para aprovação de Rhoney)

**Status:** proposta, nada implementado. Base: `MUNDO_CONCURSOS_ARQUITETURA_V1.md` (esfera Federal, aprovado) + pedido de Rhoney de 25/09/2026 de abranger Federais, Estaduais e Municipais e de remover o conteúdo atual (removal adiado: "não apague ainda").

## 0. Conflito a decidir antes de tudo

O documento aprovado diz, na seção 7, que **Estadual e Municipal ficam fora desta fase**. O pedido mais recente pede os três. A proposta abaixo já **modela as três esferas desde o começo** (custa quase nada), mas **entrega conteúdo por fases**. Rhoney decide a ordem.

## 1. Modelo de dados (schema `mental`, migrations novas)

- `bancas` — id, nome, perfil (texto), `review_status`.
- `concursos` — id, `esfera` (federal | estadual | municipal), `uf` e `municipio` (nulos no federal), órgão, banca, `status` (encerrado | em_andamento | em_analise), `edital_url`, `fonte_url`, datas, `review_status`.
- `concurso_dicas` — id, concurso (ou banca), texto, `review_status`.
- `concurso_revisoes` — id, matéria, título, conteúdo, concurso opcional, `review_status`.
- `challenges.concurso_id` (coluna opcional) — liga cada questão original a um concurso/banca. Sem ela, a questão vale para a matéria toda.

**Regra de publicação:** só `review_status = approved` é servido ao app (mesmo padrão já usado nas sugestões do Mental Lingo). Nada vai ao ar sem a revisão de Rhoney.

## 2. Como aparece no app (sem um APK novo a cada concurso)

- **Matérias continuam territórios fixos** (Português, Raciocínio Lógico, Direito Constitucional, Direito Administrativo, Informática, Atualidades…): poucos, estáveis, já suportados pelo app.
- **Catálogo de concursos é dinâmico**, vindo do backend (`GET /concursos?esfera=&status=`), então adicionar um concurso ou mudar seu status **não exige nova versão do app**.
- Ficha do concurso (`GET /concursos/{id}`): status, banca, dicas, revisão e botão "Praticar" que abre os Desafios daquele concurso/matéria.

## 3. Revisão adaptativa (sem lógica paralela)

Reaproveita as estatísticas de desempenho por território que o My_Mental_AI já calcula (taxa de acerto, tentativas): a revisão sugerida é a da matéria com pior taxa, com dados reais. O usuário continua podendo abrir qualquer revisão livremente.

## 4. Monitoramento (DOU e Gov.br)

- Custo zero: leitura de páginas públicas, sem API paga.
- **Nunca publica sozinho.** Um job mensal (no `scheduler` que o backend já tem) gera um **lote de mudanças candidatas** (ex.: "edital novo do órgão X", "concurso Y mudou para Encerrado") em arquivo/relatório para Rhoney aprovar. Só depois entra no banco como `approved`.
- Risco a declarar: os sites podem mudar de formato ou bloquear leitura automática; por isso a extração é **assistida** (candidatos + link da fonte), não decisiva.
- "Em análise" depende de notícia oficial; só entra com fonte oficial citada. Sem fonte, não entra.

## 5. Conteúdo

- Questões **originais**, escritas do zero, nunca cópia de prova (regra do documento). Tags: matéria, banca (estilo), nível.
- Entrega em **lotes revisáveis** (por matéria ou por concurso), com o mesmo pipeline de conteúdo que já usamos (JSON → validador → carga).
- **Veracidade:** dados de edital (vagas, prazos, requisitos, status) só com fonte oficial; nada de "estimado". Perfil de banca só com o que é público e verificável.

## 6. Conteúdo atual (3 territórios `concursos_*`)

Em produção há Desafios, Relâmpago e Pausas com tentativas e XP registrados. Proposta de remoção **sem quebrar o APK dos testadores**: manter os 3 territórios (viram matérias), apagar as perguntas antigas **só no momento em que o novo lote estiver pronto para carga**, evitando território vazio com erro. O XP total já ganho não é revertido. **Aguardando o "pode apagar" de Rhoney.**

## 7. Ordem de execução sugerida

1. Migration do modelo + endpoints de leitura (catálogo/ficha) + testes.
2. Telas do app (lista por status/esfera, ficha) + APK.
3. Primeiro lote de conteúdo: **Federal — Encerrados** (mais estável), por matéria.
4. Job mensal de candidatos (DOU/Gov.br) + formato do relatório para aprovação.
5. Estadual e Municipal (por UF/município escolhidos por Rhoney).
