# MENTAL — BUGS: Tela Movimento não converte passos em XP e gráficos não populam

**Status:** Prioridade alta — testado em campo, com evidência reproduzível abaixo. Corrigir todos os itens antes de considerar a tela Movimento pronta.
**Contexto:** Rhoney fez um teste real: caminhou uma volta no quarteirão inteira, com o celular destravado, tela ligada o tempo todo, dentro do bolso, sem travar em nenhum momento. Capturou print no início e no fim da caminhada. O sensor de passos está funcionando corretamente (contagem subiu de forma real), mas três outras partes da tela não acompanharam.

## Evidência do teste (dois prints, mesma sessão, ~5 minutos de intervalo)

**Print 1 (início da caminhada, 22:39):**
- Passos: 261
- % da meta (15k selecionada): 2%
- XP conquistado: 0
- MentalCoins: 0
- Gráfico "Últimos 7 dias": vazio, sem nenhuma barra
- Gráfico "Hoje, hora a hora": não aparece — só mensagem "Ainda sem dados de oscilação hoje — ande um pouco pra ver o pico e o vale aparecerem."
- Meta selecionada: 15k (intenso)
- Botão "Ir" (confirmar meta): desabilitado/cinza

**Print 2 (fim da caminhada, 22:44, ~5 min depois):**
- Passos: 788 (subiu corretamente, prova que o sensor está lendo o movimento real)
- % da meta: 5% (subiu proporcionalmente, também correto)
- XP conquistado: **ainda 0** — não mudou nada, apesar de 788 passos já deverem gerar XP pela regra "100 passos = +2 XP" (documentada e exibida na própria tela)
- MentalCoins: ainda 0
- Gráfico "Últimos 7 dias": continua vazio, nenhuma barra apareceu
- Gráfico "Hoje, hora a hora": continua ausente, mesma mensagem de estado vazio de antes
- Botão "Ir": continua desabilitado

## Bugs a investigar e corrigir

### 1. XP não é creditado a partir dos passos (bug principal)
Passos passaram de 261 para 788 (+527 passos), o que pela regra documentada na própria tela ("100 passos = +2 XP") deveria ter gerado pelo menos +10 XP nesse intervalo. O valor de XP exibido permaneceu 0 nos dois prints.
- Investigar se o cálculo de XP por passo está de fato implementado no backend, ou se ainda é um valor mockado/placeholder que nunca é atualizado.
- Investigar se existe alguma condição (ex: só credita XP no fechamento do ciclo, não em tempo real) que explique isso — se for esse o caso, a interface precisa deixar isso claro (hoje ela mostra "XP conquistado" como se fosse um contador ao vivo, criando expectativa de que atualiza junto com os passos).
- Se o cálculo existir mas não estiver sendo persistido/exibido corretamente, corrigir o fluxo de ponta a ponta (cálculo no backend → API → exibição no cliente).

### 2. Gráfico "Últimos 7 dias" não renderiza nenhuma barra
Mesmo com histórico de dias anteriores possivelmente existente (o app já está em uso há mais de 7 dias, conforme streak de 6 dias mostrado no topo), nenhuma barra aparece — nem para os dias passados, nem para o dia atual em andamento.
- Verificar se o endpoint que fornece a série de 7 dias está retornando dados.
- Se não houver dado histórico real ainda (ex: essa agregação diária nunca foi implementada/persistida antes desta tela), meu pedido é para que isso seja implementado de fato, não simulado.
- Se houver dado mas o gráfico não estiver consumindo/renderizando corretamente, corrigir o binding entre API e o componente de gráfico.

### 3. Gráfico "Hoje, hora a hora" nunca aparece, mesmo com passos reais registrados
A tela mostra "ainda sem dados de oscilação hoje" mesmo após uma caminhada real que gerou passos reais e checkpoints deveriam existir.
- Verificar a frequência real de geração dos checkpoints de 6 em 6 horas mencionados na especificação original (MOVIMENTO_REDESIGN_V1.md) — se a lógica exige o dia inteiro completo (ou um número mínimo de checkpoints) antes de exibir qualquer coisa, isso está tornando o gráfico inutilizável na prática (o usuário pode nunca ver picos/vales do próprio dia atual até o dia já ter terminado).
- Ajustar para que o gráfico comece a desenhar a partir do primeiro checkpoint disponível, mesmo que incompleto (ex: mostrar a linha parcial do que já foi registrado, em vez de esconder tudo até ter o dia inteiro).
- Reportar exatamente qual é a regra atual de quando o checkpoint é criado/consultado (frequência real, não a documentada) — pode haver divergência entre o que foi especificado e o que foi implementado.

### 4. Botão "Ir" (confirmar meta) permanece desabilitado mesmo com uma meta selecionada
Nos dois prints, "15k" aparece visualmente selecionado (destacado), mas o botão "Ir" está cinza/inativo em ambos.
- Testar e reportar: o botão ativa ao selecionar uma meta diferente da atualmente salva (ex: trocar de 15k para 5k)? Se sim, o comportamento nos prints pode ser correto (15k já era a meta ativa, não há mudança a confirmar) — mas nesse caso, a interface deveria deixar isso visualmente claro (ex: o botão nem aparecer, ou mostrar "meta atual" em vez de um botão "Ir" cinza, que parece quebrado).
- Se o botão não ativa em nenhum cenário (bug real de estado do componente), corrigir a lógica de habilitação do botão.

## O que já está confirmado funcionando (não mexer)

- Sensor de passos: leitura em tempo real correta e precisa (confirmado pelo salto real de 261 → 788 passos numa caminhada real).
- Percentual da meta: calculado corretamente e proporcional aos passos (2% → 5%, condizente com a meta de 15k selecionada).
- Chip de ciclo pendente: exibindo corretamente.
- Streak: exibindo corretamente (🔥 6).

## Investigação adicional pedida

Por favor, ao investigar o item 1 (XP), verifique também se existe algum erro silencioso (exception engolida, chamada de API falhando sem tratamento) no fluxo de crédito de XP por passo — mesmo padrão de problema que já apareceu antes no bug de "desafio não avança após resposta". Se for o caso, aplicar o mesmo cuidado de não deixar erros silenciosos nesse fluxo.

## Critério de aceite

- Repetir um teste real de caminhada (mesmo cenário: sensor ativo, tela ligada, alguns minutos de caminhada) e confirmar que XP sobe de forma visível e proporcional aos passos, sem precisar fechar/reabrir o app.
- Gráfico "Últimos 7 dias" exibe pelo menos o dia atual com alguma barra proporcional aos passos já dados, mesmo que os dias anteriores estejam zerados por falta de histórico.
- Gráfico "Hoje, hora a hora" começa a desenhar a partir do primeiro checkpoint disponível, sem exigir o dia inteiro completo.
- Botão "Ir" reflete um estado claro e correto (habilitado quando há mudança de meta a confirmar, ou removido/substituído por indicação de "meta atual" quando não há mudança).
- Testes automatizados cobrindo especificamente o fluxo "passos → XP creditado", para evitar regressão futura.
