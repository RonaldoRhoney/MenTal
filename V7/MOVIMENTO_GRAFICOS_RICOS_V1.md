# MENTAL — Movimento: Gráficos Dinâmicos e Ricos por Período (Dia/Semana/Mês/Ano)

**Status:** Aprovado para implementação imediata.
**Referência visual:** movimento_rico.html (protótipo estático HTML/CSS — reproduzir estrutura, hierarquia, cores, proporções e o nível de detalhe/estilização exatamente como demonstrado). O protótipo detalha a visão "Dia" por completo e a visão "Semana" como exemplo de gráfico de barras — as visões "Mês" e "Ano" devem seguir o mesmo padrão de estilo e riqueza de detalhe, adaptando apenas a granularidade dos dados.

---

## 1. Objetivo

A tela Movimento atual está simples demais e não entrega valor percebido ao usuário — apenas números soltos, sem contexto, sem riqueza visual, sem fazer a pessoa perceber o significado do próprio progresso. Esta especificação exige uma reformulação completa: gráficos dinâmicos, estilizados e ricos em detalhe para cada período (Dia, Semana, Mês, Ano), sempre acompanhados de legendas explicativas e de totais acumulados destacados.

## 2. Estrutura geral da tela

### 2.1 Seletor de período
- Abas fixas no topo da tela: **Dia / Semana / Mês / Ano**.
- Trocar de aba atualiza tanto o card de total acumulado quanto o gráfico principal abaixo, sem sair da tela Movimento.

### 2.2 Card de total acumulado (sempre visível, para qualquer período selecionado)
- Fica no topo, logo abaixo do seletor de período.
- Exibe o total de passos acumulado **do período selecionado** (ex.: total do dia, total da semana, total do mês, total do ano), em destaque tipográfico grande.
- Abaixo do número principal, uma linha de dados complementares: XP ganho naquele período, percentual da meta atingido, e streak atual — nunca um número isolado sem contexto ao redor.
- Visual: card com leve gradiente (tons dourado/âmbar, coerentes com a paleta de conquista já estabelecida em Home e Movimento), não um card neutro/cinza.

## 3. Gráfico do período "Dia" — o mais detalhado de todos

### 3.1 Divisão em 6 sessões de 4 horas
O dia deve ser dividido em exatamente 6 sessões de 4 horas cada, cobrindo as 24 horas:
1. Madrugada — 00h às 04h
2. Início da manhã — 04h às 08h
3. Fim da manhã — 08h às 12h
4. Início da tarde — 12h às 16h
5. Fim da tarde — 16h às 20h
6. Noite — 20h às 00h

### 3.2 Gráfico visual
- Gráfico de linha/área cobrindo as 24 horas, com curva suave conectando os valores de cada sessão.
- Preenchimento em gradiente sob a linha (tom âmbar/laranja, com opacidade decrescente).
- Marcador visual destacando o ponto de pico do dia (maior valor de passos entre as 6 sessões), com uma pequena etiqueta indicando o valor daquele pico diretamente sobre o gráfico.

### 3.3 Legenda de sessões — obrigatória, abaixo do gráfico
Para cada uma das 6 sessões, exibir um bloco de legenda contendo:
- **Nome da sessão** (ex.: "Fim da manhã"), com um emoji/ícone associado ao período do dia.
- **Faixa de horário** (ex.: "08h–12h").
- **Valor de passos** daquela sessão específica.
- **Uma frase curta e descritiva** sobre o que aquele valor representa (ex.: "Pico do dia — maior atividade registrada", "Praticamente parado, período de sono", "Ritmo ainda forte após o almoço"). Essas frases devem ser geradas dinamicamente com base no padrão de dados do próprio usuário (ex.: identificar automaticamente qual sessão teve o maior valor e rotulá-la como pico; identificar a sessão de menor valor e descrevê-la de forma correspondente), não frases fixas e genéricas sem relação com o dado real.
- A sessão de maior valor (pico) deve ter destaque visual diferenciado das demais (cor de borda/fundo diferente, remetendo à paleta de conquista/vitória).
- As 6 legendas devem ser organizadas em grade (grid), não em lista vertical simples — visual mais compacto e rico, como demonstrado no protótipo.

## 4. Gráfico do período "Semana"

- Gráfico de barras, uma barra por dia dos últimos 7 dias.
- Cada barra estilizada com gradiente de cor (tom teal/verde-água para dias regulares).
- A barra do dia atual deve ter destaque visual diferenciado (cor dourada/âmbar), diferenciando-a claramente dos demais dias.
- Exibir, no cabeçalho do card do gráfico, a média de passos da semana.

## 5. Gráfico do período "Mês"

- Seguir o mesmo padrão visual e nível de riqueza dos gráficos de Dia e Semana (não pode ser mais simples ou menos estilizado que os anteriores).
- Granularidade sugerida: uma barra ou ponto por dia do mês (ou, alternativamente, agrupado por semana dentro do mês, a critério de legibilidade em tela pequena — Claude Code deve avaliar qual das duas abordagens mantém a leitura clara sem poluir visualmente).
- Destacar visualmente o dia (ou semana) de melhor desempenho dentro do mês, com a mesma lógica de destaque de pico já usada no gráfico do Dia.
- Exibir média mensal e total do mês no cabeçalho do card.

## 6. Gráfico do período "Ano"

- Mesmo padrão visual e nível de riqueza dos demais.
- Granularidade sugerida: uma barra por mês do ano.
- Destacar visualmente o mês de melhor desempenho.
- Exibir média mensal do ano e total anual no cabeçalho do card.

## 7. Histórico completo dia a dia (nova seção, abaixo dos gráficos)

- Lista cronológica (mais recente primeiro) de todos os dias em que o usuário usou o app, desde o primeiro dia de uso.
- Cada linha do histórico deve exibir:
  - Numeração sequencial do dia de uso (ex.: "Dia 1", "Dia 2", ... "Dia 11"), não apenas a data — o usuário deve conseguir perceber facilmente há quantos dias está usando o app.
  - Data correspondente (ex.: "03 de setembro").
  - Passos daquele dia específico.
  - XP ganho naquele dia específico.
  - **Total acumulado de passos até aquele dia** (soma de todos os dias anteriores, incluindo o próprio) — este é o requisito central desta seção: o usuário deve conseguir ver a progressão acumulada crescendo dia após dia, não apenas o valor isolado de cada dia.
- Dias em que a meta diária foi atingida devem ter um indicador visual diferenciado (ex.: cor de destaque no marcador daquela linha) em relação aos dias em que não foi atingida.
- Esta lista deve ser paginada ou carregada sob demanda (scroll infinito ou "carregar mais") se o histórico for extenso, para não prejudicar performance.

## 8. Padrão visual geral (vale para todos os gráficos e cards desta tela)

- Paleta de conquista já estabelecida (dourado/âmbar para destaque e vitória, teal/verde-água para dados regulares/energia), consistente com o restante do app.
- Tipografia: números em destaque usando fonte monoespaçada/geométrica (mesmo padrão já usado em outros cards de dado do app), textos descritivos em fonte regular.
- Cantos arredondados, cards com leve gradiente de fundo (não cor sólida chapada), bordas sutis.
- Nenhum gráfico deve ser "gráfico jogado ali sem explicação" — todo gráfico desta tela deve vir acompanhado de pelo menos um elemento de contexto textual (legenda, média, destaque de pico) que ajude o usuário a interpretar o que está vendo, não apenas visualizar a linha/barra sozinha.
- Fica expressamente vedado entregar uma versão simplificada deste requisito — os gráficos devem refletir o mesmo nível de riqueza, estilização e detalhe demonstrado no protótipo `movimento_rico.html`, para todos os 4 períodos.

## 9. Escopo técnico (alto nível — arquitetura detalhada a propor por Claude Code)

- Agregação de dados por sessão de 4h já deve reaproveitar os checkpoints existentes no backend (mencionados em documentos anteriores de Movimento) — Claude Code deve confirmar se a granularidade de captura atual já suporta 6 sessões de 4h com precisão, ou se precisa de ajuste na frequência de checkpoint.
- Geração das frases descritivas de cada sessão (seção 3.3) deve ser lógica no backend ou no cliente, calculada dinamicamente a partir do dado real do usuário — nunca texto estático hardcoded que não reflita o padrão daquele dia específico.
- Cálculo de total acumulado (seção 7) deve ser eficiente mesmo com muitos dias de histórico — considerar armazenar o acumulado já calculado por dia (em vez de recalcular a soma de todos os dias anteriores a cada carregamento de tela), atualizando esse valor apenas quando um novo dia é fechado.
- Autoridade de todos os cálculos (passos, XP, acumulados, percentuais) permanece 100% no backend — o cliente apenas renderiza o que a API retorna.

## 10. Critério de aceite

- As 4 abas de período (Dia/Semana/Mês/Ano) funcionam e cada uma exibe um gráfico com o mesmo nível de riqueza visual demonstrado no protótipo.
- O gráfico do Dia exibe as 6 sessões de 4h corretamente, com legenda individual por sessão incluindo horário, valor e frase descritiva dinâmica.
- A sessão/dia/mês de maior desempenho tem destaque visual diferenciado em qualquer período selecionado.
- O card de total acumulado do período selecionado está sempre visível e nunca aparece como número isolado, sempre com XP/meta/streak como contexto adicional.
- A seção de histórico completo exibe corretamente a numeração sequencial de dias de uso, a data, os dados daquele dia, e o total acumulado até aquele ponto.
- Nenhum gráfico desta tela é entregue em versão visualmente mais simples do que o demonstrado no protótipo `movimento_rico.html`.
