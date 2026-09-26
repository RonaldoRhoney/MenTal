# MENTAL — Mundo dos Concursos: Arquitetura Inicial (Esfera Federal)

**Status:** APROVADO. Escopo inicial deliberadamente restrito à esfera **Federal**, para manter o trabalho enxuto — Estadual e Municipal ficam para fases posteriores, após a Federal estar estável e validada. Conteúdo deve ser produzido pelo agente autônomo de curadoria, com aprovação humana obrigatória antes de qualquer publicação, seguindo o mesmo princípio já reafirmado em todo o projeto.

---

## 1. Objetivo

Criar um novo Mundo no MENTAL dedicado a concursos públicos, cobrindo, nesta primeira fase, exclusivamente a esfera **Federal**: questões de estudo originais, revisão de conteúdo, dicas, informações sobre bancas organizadoras, e acompanhamento de status de concursos (Encerrados, Em andamento, Em análise).

## 2. Estrutura de conteúdo

### 2.1 Categorização por status do concurso
- **Encerrados**: concursos já finalizados (resultado publicado). Conteúdo de estudo baseado neles é o mais estável e seguro de manter no app por longo prazo.
- **Em andamento**: concurso com edital publicado e processo seletivo em curso (inscrições abertas, provas agendadas, ou fases em avaliação).
- **Em análise**: concurso ainda não confirmado oficialmente, mas com movimentação relevante (ex.: autorização de vagas publicada, edital aguardado, ou notícias oficiais indicando abertura iminente).

### 2.2 Componentes de conteúdo por concurso/órgão
- **Desafios**: questões de estudo — sempre **originais, nunca reproduzidas literalmente** de uma prova real, mesmo quando a fonte de referência é uma prova/gabarito oficialmente publicado pela banca. Exceção única: conteúdo comprovadamente em domínio público ou explicitamente livre de direitos autorais.
- **Revisão**: material de estudo do conteúdo programático do edital. Dupla forma de acesso: (a) o agente seleciona e prioriza conteúdo de revisão adaptado ao desempenho do usuário (pontos fracos identificados), e (b) o usuário pode acessar livremente qualquer conteúdo de revisão disponível, independentemente da sugestão do agente.
- **Dicas**: orientações de estudo e de prova (estratégia de resolução, gestão de tempo, pegadinhas comuns daquela banca, etc.) — termo mantido como está, sem conflito com a mecânica de "dica" (penalidade de XP) já existente nos Desafios comuns do app, por serem contextos suficientemente distintos.
- **Banca**: perfil informativo sobre cada banca organizadora (estilo de prova, histórico, particularidades conhecidas de formulação de questões).

## 3. Fontes de referência (a serem usadas para aprendizado do agente, nunca para cópia)

### 3.1 Fontes oficiais primárias (dados de edital — vagas, prazos, requisitos)
- **Diário Oficial da União (DOU)** — `in.gov.br`, mantido pela Imprensa Nacional. Publicação obrigatória de todo edital federal — fonte de verdade para dados formais do concurso.
- **Gov.br – Concursos** — portal do governo federal.

### 3.2 Sites das bancas organizadoras
Cada banca (Cebraspe, FGV, FCC, Vunesp, entre outras atuantes em concursos federais) publica provas e gabaritos de concursos já realizados em suas próprias páginas — usar como referência de estilo, nível de exigência e formato de questão da banca, nunca como texto a reproduzir.

### 3.3 Bancos de questões gratuitos (referência de estilo/cobertura de conteúdo)
- **OpenConcursos**, **Fonte Concursos**, **PCI Concursos** (este último também útil como agregador para descoberta de novos editais/status de concursos).

### 3.4 Regra de direitos autorais — reafirmada
Mesmo quando uma prova/gabarito está publicamente disponível no site da própria banca (transparência do processo), a questão em si é considerada criação intelectual protegida — **não é um "ato oficial de governo" livre de direitos autorais**. O agente deve estudar essas fontes para aprender padrão, estilo e conteúdo programático, e **sempre redigir questões originais e próprias do zero**, nunca reproduzir enunciados ou alternativas de uma questão real.

## 4. Monitoramento contínuo — agente 24h, cadência mensal

- Um agente dedicado deve monitorar continuamente (24 horas) as fontes da seção 3.1 (DOU e Gov.br) em busca de mudanças de status de concursos já cadastrados no app (ex.: concurso que estava "Em análise" teve edital publicado e vira "Em andamento"; concurso "Em andamento" teve resultado divulgado e vira "Encerrado").
- **Cadência de atualização definida: mensal.** O agente não precisa (nem deve) atualizar o conteúdo do app em tempo real a cada mudança individual — consolida as mudanças identificadas ao longo do mês e as aplica em um ciclo de atualização mensal, reportando a Rhoney antes de publicar.

## 5. Delegação ao agente de curadoria — mesmo princípio já estabelecido

- Este Mundo, assim como a expansão de vocabulário do Mundo dos Idiomas (MUNDO_IDIOMAS_NOVOS_TEMAS_AGENTE_V1.md), deve ser populado pelo **agente autônomo de curadoria de conteúdo**, não por curadoria manual linha a linha.
- **Revisão humana de Rhoney continua obrigatória e não-negociável** antes de qualquer conteúdo (Desafio, Revisão, Dica, ficha de Banca, ou mudança de status de concurso) ir ao ar.
- Material deve ser entregue em lotes revisáveis (ex.: por órgão, por concurso, ou por ciclo mensal de atualização), nunca como publicação massiva sem checkpoint de aprovação.

## 6. Escopo técnico (a propor em detalhe por Claude Code)

- Modelar a estrutura de dados do Mundo dos Concursos: Órgão/Concurso → Status (Encerrado/Em andamento/Em análise) → Banca → conjunto de Desafios, Revisões e Dicas associados.
- Definir o mecanismo técnico de monitoramento contínuo das fontes da seção 3.1, com consolidação mensal das mudanças identificadas.
- Integrar a lógica de Revisão adaptativa (seleção por desempenho do usuário) com o sistema de acompanhamento de desempenho já existente no restante do MENTAL, reaproveitando o que for aplicável em vez de criar uma lógica paralela divergente.
- Propor o formato do lote de revisão mensal a ser entregue a Rhoney para aprovação.

## 7. Fora de escopo nesta fase

- Esferas Estadual e Municipal — ficam para fases futuras, após a esfera Federal estar estável e validada em produção.

## 8. Critério de aceite

- Mundo dos Concursos (Federal) estruturado com as três categorias de status (Encerrado/Em andamento/Em análise).
- Cada concurso/órgão conta com Desafios (questões originais), Revisão (adaptativa + livre acesso), Dicas e ficha de Banca.
- Nenhuma questão reproduzida literalmente de fonte real, exceto conteúdo comprovadamente livre de direitos autorais.
- Monitoramento de status operante, com ciclo de atualização mensal e aprovação de Rhoney antes de qualquer publicação.
- Nenhum conteúdo publicado sem passar pela revisão humana obrigatória.
