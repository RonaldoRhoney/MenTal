# MENTAL — Arquitetura de SubMundos: Internet dentro de Tecnologia

**Status:** APROVADO. Decisão de produto tomada por Rhoney — Claude Code deve implementar conforme especificado abaixo, não reabrir a decisão para debate.

---

## 1. Decisão

O "Mundo da Internet" deixa de ser um Mundo de primeiro nível na Home e passa a ser um **SubMundo dentro do Mundo da Tecnologia**. Justificativa: Internet é, taxonomicamente, um subconjunto de Tecnologia, não um domínio paralelo a ela — a estrutura do app deve refletir essa relação real entre os temas, em vez de tratá-los como categorias equivalentes e desconectadas.

Esta decisão estabelece, a partir de agora, um **novo padrão estrutural permanente** do MENTAL: Mundos temáticos amplos podem conter SubMundos mais específicos dentro de si, evitando que a Home fique sobrecarregada com Mundos cada vez mais numerosos e granulares conforme o app cresce. Esse padrão deve ser aplicado a qualquer cluster temático futuro com a mesma relação de continência (ex.: um futuro "Mundo da Ciência" poderia conter SubMundos como Física, Química e Biologia).

## 2. O que muda estruturalmente

- Nova hierarquia de dados: **Mundo → SubMundo → Bloco/Território → Desafio**, adicionando um nível entre Mundo e Bloco que não existe hoje na estrutura do app.
- O "Mundo da Internet" (5 blocos, 25 desafios, conteúdo já produzido e entregue) passa a existir como SubMundo dentro do "Mundo da Tecnologia", preservando integralmente toda a estrutura interna de blocos/desafios/níveis de dificuldade já definida.
- Nenhum conteúdo já produzido (perguntas, cápsulas, "Saiba mais") precisa ser reescrito ou descartado — a mudança é de categorização estrutural, não de conteúdo.

## 3. Navegação e UX

- Na Home, o usuário vê o "Mundo da Tecnologia" como Mundo de primeiro nível, não o "Mundo da Internet" separadamente.
- Ao entrar no Mundo da Tecnologia, o usuário encontra os SubMundos disponíveis (ex.: Internet, e outros que venham a ser criados dentro do mesmo Mundo), navegando até eles como uma etapa intermediária antes de chegar aos blocos/desafios.
- Essa navegação em etapa extra não deve aumentar a contagem de toques necessários de forma desproporcional — Claude Code deve propor uma solução de UI que mantenha a navegação fluida (ex.: SubMundos exibidos como abas ou cards dentro da própria tela do Mundo pai, não como uma tela completamente nova e isolada).

## 4. Escopo técnico (a propor em detalhe por Claude Code)

- Modelar a nova entidade "SubMundo" na estrutura de dados/banco, com relação de pertencimento a um Mundo pai.
- Migrar o conteúdo já existente do "Mundo da Internet" para essa nova estrutura, associando-o como SubMundo do "Mundo da Tecnologia".
- Atualizar toda referência de UI/navegação (Home, Admin Dashboard, Ranking, e qualquer outro ponto que hoje trate "Mundo da Internet" como Mundo de primeiro nível) para refletir a nova hierarquia.
- Confirmar que essa mudança de schema é tecnicamente viável dentro da arquitetura atual do banco e do client, reportando qualquer impacto relevante antes de implementar — mas a decisão de fazer a mudança em si já está tomada e não deve ser reaberta para debate.

## 5. Critério de aceite

- "Mundo da Internet" aparece corretamente como SubMundo dentro do "Mundo da Tecnologia" em toda a navegação do app.
- Nenhum conteúdo (pergunta, cápsula, Saiba mais) foi perdido ou alterado na migração.
- A nova estrutura de dados suporta a criação de futuros SubMundos dentro de qualquer Mundo, não apenas para este caso específico.
- Navegação até um SubMundo não aumenta desproporcionalmente o número de toques necessários, comparado ao padrão de navegação já estabelecido em outros Mundos.
