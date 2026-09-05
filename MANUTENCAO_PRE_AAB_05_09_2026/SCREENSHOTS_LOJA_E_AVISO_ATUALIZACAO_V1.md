# MENTAL — Screenshots Atualizados na Loja + Aviso Gentil de Nova Versão

**Status:** Aprovado para implementação.
**Tipo:** Checklist de processo de release (não é bug, é rotina a partir de agora).

---

## 1. Screenshots da ficha na Google Play

### 1.1 Problema
As imagens exibidas hoje na ficha do MENTAL na Google Play mostram telas antigas do app, desatualizadas em relação ao visual atual (Home, Ranking, Movimento, MentalCoins já passaram por redesenho desde que essas capturas foram feitas).

### 1.2 O que fazer
- Capturar novas screenshots das melhores telas do app no estado visual atual, priorizando:
  - **Home** (com o card de identidade e o grid de atalhos atual).
  - **Ranking** (versão enriquecida, com badges de conquista por jogador).
  - **Movimento** — capturar os 4 períodos separadamente: **Hoje, Semana, Mês e Ano**, já que cada um tem gráfico e apresentação visual distinta.
  - **MentalCoins** (tela de saldo/resgate).
- Substituir as imagens atuais na ficha da Google Play por essas novas capturas, escolhendo as que melhor representam a experiência real e mais rica do app hoje.
- Este processo deve ser repetido **sempre que uma mudança visual relevante** for lançada (ex.: redesenho de tela, nova mecânica visualmente significativa) — não é uma tarefa única, é rotina a partir de agora, junto do checklist de release.

### 1.3 Observação técnica
- A captura em si (tirar print das telas) precisa ser feita manualmente por Rhoney (ou testador humano) em um dispositivo Android real, navegando pelo app já publicado ou em teste — o Claude Code não tem como gerar essas capturas sozinho, mas pode preparar o app/dados de teste num estado visualmente "bonito" para facilitar a captura (ex.: garantir que a conta de teste usada para printar tenha XP, streak, MentalCoins e histórico de Movimento com dados reais e não vazios/zerados).

## 2. Aviso gentil de nova versão disponível

### 2.1 Problema que isso resolve
Quando uma nova versão é publicada, usuários que ainda estão com uma versão antiga instalada podem encontrar comportamento inconsistente (ex.: uma tela que já foi corrigida no backend mas ainda roda com lógica antiga no cliente desatualizado) e confundir isso com um bug real do app, ao invés de simplesmente precisar atualizar — o que pode levar à desistência do usuário por um motivo evitável.

### 2.2 Comportamento esperado
- Toda vez que o usuário abrir o app e uma versão mais nova estiver disponível na Google Play, o app deve exibir um aviso gentil convidando à atualização.
- O aviso deve ser **não-bloqueante** por padrão (o usuário pode adiar e continuar usando a versão atual), a menos que a nova versão corrija algo crítico de segurança ou integridade — nesse caso específico, avaliar exigir atualização obrigatória antes de continuar.
- Texto do aviso deve ser claro e não alarmante — algo como "Uma nova versão do MENTAL está disponível, com melhorias e correções. Deseja atualizar agora?", com opções de "Atualizar" e "Mais tarde".
- Ao tocar em "Atualizar", direcionar o usuário à ficha do app na Google Play (ou, se suportado, iniciar a atualização via API de atualização in-app do Google Play).

### 2.3 Escopo técnico (alto nível — arquitetura detalhada a propor por Claude Code)
- Avaliar o uso da **Google Play In-App Update API**, que permite verificar se há versão mais nova disponível e oferecer atualização flexível (não-bloqueante) ou imediata (bloqueante), diretamente dentro do fluxo do app, sem depender de comparação manual de versão feita pelo próprio MENTAL.
- Se a In-App Update API não for adotada nesta entrega, alternativa: o backend expõe a versão mínima recomendada e a versão mais recente disponível; o cliente compara com sua própria versão instalada ao abrir o app, exibindo o aviso quando desatualizado.
- Definir, junto com Rhoney, quais tipos de atualização justificariam exigir obrigatoriedade (ex.: correções de segurança como as do documento de auditoria pré-AAB) versus quais podem ficar como sugestão opcional (ex.: apenas melhorias visuais).

### 2.4 Animação de apresentação do aviso
- O aviso de atualização deve ser acompanhado de uma animação de entrada suave (ex.: modal surgindo com fade e leve movimento de escala/deslizamento, na mesma linguagem visual de transição já usada em outras telas do app, como a animação em cascata da Home), em vez de aparecer de forma abrupta.
- A animação deve reforçar a identidade visual do MENTAL (paleta de conquista já estabelecida — dourado/âmbar, teal), tornando o convite à atualização consistente com o restante da experiência, não um alerta de sistema genérico.
- **Critério de conformidade com o Google Play:** qualquer animação/modal customizado deve continuar respeitando os padrões de acessibilidade e usabilidade já exigidos pela Play — não pode bloquear a leitura do conteúdo por tempo excessivo, deve ser dispensável a qualquer momento pelo usuário (nunca travar a tela sem saída, exceto no caso já previsto de atualização obrigatória por segurança crítica, e mesmo nesse caso a ação de "atualizar agora" deve estar sempre clara e acessível). Se a In-App Update API do Google for adotada (seção 2.3), suas telas/fluxos nativos já vêm com a animação e a conformidade padrão do próprio Google — nesse caso, a personalização visual descrita aqui vale para qualquer aviso complementar construído pelo MENTAL antes de acionar a API, não para a tela nativa do Google em si.

## 3. Critério de aceite

- Novas screenshots (Home, Ranking, Movimento nos 4 períodos, MentalCoins) substituem as imagens desatualizadas na ficha da Google Play.
- Processo de atualização de screenshots documentado como parte da rotina de release, não como tarefa isolada.
- Usuário com versão desatualizada recebe aviso gentil e claro ao abrir o app, com opção de atualizar ou adiar (exceto em caso de atualização crítica, a ser definida caso a caso).
- Aviso nunca é confundido com erro/bug — linguagem e visual devem deixar claro que é uma sugestão de atualização, não uma falha do app.
