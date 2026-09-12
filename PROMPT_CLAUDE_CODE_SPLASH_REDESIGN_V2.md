PROJETO: MENTAL
MÓDULO: SPLASH / OPENING EXPERIENCE
OBJETIVO: EVOLUIR A EXPERIÊNCIA DE ABERTURA DO APLICATIVO

STATUS:
APROVADO PARA ANÁLISE, PROPOSTA E IMPLEMENTAÇÃO DO REDESIGN DO SPLASH,
RESPEITANDO INTEGRALMENTE A ARQUITETURA E AS REGRAS EXISTENTES DO MENTAL.

VERSÃO 2 — ajustada para eliminar ambiguidades de identidade antes de
qualquer investigação do Claude Code (ver Seção 0).

============================================================
0. AJUSTES DE IDENTIDADE REAL DO MENTAL (LER ANTES DE TUDO)
============================================================

Esta seção resolve, de antemão, três pontos que ficariam em aberto
e gerariam ida-e-volta desnecessária com o Claude Code.

0.1 TAGLINE OFICIAL — SEM AMBIGUIDADE

O MENTAL já possui uma tagline oficial, em uso na Home:

"MENTAL É QUEM CONQUISTA COM A MENTE."

Esta é a frase a ser usada no Splash, se uma frase de apoio ao logo for
exibida como texto na tela. Não introduzir a frase alternativa "MINHA
MENTE ESTÁ EM MOVIMENTO" como texto literal em tela — essa frase pode
seguir existindo apenas como CONCEITO INTERNO norteador da animação
(a sensação de "mente em movimento" que a motion design deve transmitir),
nunca como texto escrito substituindo a tagline oficial.

Contexto relevante: numa reorganização recente da Home, o wordmark
"MENTAL" e a tagline saíram de destaque e viraram uma marca d'água
discreta no fundo da tela (opacidade baixa, sem competir com o
conteúdo). Isso significa que o Splash passa a ser, muito provavelmente,
o único lugar do app onde a marca aparece em destaque total e sem
concorrência visual. Tratar esse fato como argumento a favor de dar
ao logo e à tagline oficial o papel central e protagonista no Splash,
reforçando a Seção 6 do documento original.

0.2 PALETA DE CORES REAL — NÃO PARTIR DO ZERO

O MENTAL já tem paleta cromática estabelecida e em uso consistente em
Home, Ranking, Movimento e demais telas principais:

- Dourado/âmbar de conquista — cor de destaque, vitória, XP, streak.
- Teal/verde-água elétrico — cor de dado regular, energia, progresso.
- Violeta — cor de apoio, usada em gradientes e transições.
- Fundo escuro (tons de preto/roxo muito escuro) como base de toda a UI.

O Claude Code deve confirmar os valores exatos (hex) direto no design
system/tema já existente no código, mas não deve tratar a etapa de
"identificar cores" (Seção 21, Etapa 1) como uma descoberta do zero —
a paleta já é conhecida em termos conceituais; a etapa de inspeção deve
apenas extrair os valores exatos já codificados, não escolher cores novas.

0.3 ÍCONE OFICIAL "M" — PONTO DE PARTIDA DA ANIMAÇÃO

O MENTAL já possui um ícone oficial: um "M" estilizado com padrão de
sinapses/rede neural, hoje usado como ícone do app e em notificações.
A sequência de convergência descrita na Seção 5 (Estados 3 e 4:
"Conexão" e "Concentração") deve, sempre que tecnicamente viável,
convergir visualmente em direção a esse ícone já existente — não criar
um símbolo de convergência novo e desconectado do ícone que o usuário
já reconhece na tela inicial do celular. Reaproveitar o asset visual
já existente, adaptando-o para animação, é preferível a desenhar um
novo símbolo do zero.

0.4 DURAÇÃO-ALVO CONCRETA

Para tornar a exigência de performance da Seção 12 mensurável, fica
definida uma duração-alvo para a Opening Experience completa (excluindo
o tempo do System Splash nativo do Android, que segue suas próprias
regras de sistema):

ENTRE 1,2 E 2,5 SEGUNDOS, do início da animação até a entrega da Home.

Esse intervalo pode ser ajustado durante a Etapa de Proposta Visual
(Seção 21, Etapa 3), mas deve ser proposto com um número concreto,
não apenas qualificado como "rápido" ou "curto".

============================================================
1. VISÃO DO PRODUTO
============================================================

O MENTAL não deve ser tratado visualmente como um simples aplicativo
de perguntas e respostas.

MENTAL é uma experiência de evolução através do conhecimento.

O produto combina:

- conhecimento;
- raciocínio;
- memória;
- desafios;
- aprendizagem;
- descoberta;
- progressão;
- XP;
- níveis;
- ranking;
- territórios;
- competição;
- desafios individuais;
- interação social gamificada;
- Movement;
- Inglês;
- Libras;
- conhecimentos gerais;
- matemática;
- filosofia;
- futebol;
- lógica;
- outros mundos e conteúdos que possam ser incorporados ao ecossistema.

A identidade do Mental deve transmitir a ideia central de mente em
movimento (ver Seção 0.1 sobre como essa ideia se relaciona com a
tagline oficial já em uso).

O usuário não entra simplesmente para responder perguntas.

Ele entra para:

APRENDER.
PENSAR.
DESCOBRIR.
EVOLUIR.
COMPETIR.
SUPERAR-SE.

O Splash deve ser a primeira manifestação visual dessa filosofia.

============================================================
2. MISSÃO DESTE REDESIGN
============================================================

Redesenhar a experiência de abertura do Mental para que ela seja:

- mais fluida;
- mais bonita;
- mais sofisticada;
- mais moderna;
- mais memorável;
- mais dinâmica;
- mais emocional;
- mais coerente com a identidade do Mental;
- mais tecnológica sem parecer excessivamente futurista;
- mais elegante;
- rápida (ver duração-alvo na Seção 0.4);
- leve;
- nativa Android;
- visualmente consistente com o restante do aplicativo.

O objetivo não é simplesmente "colocar uma animação".

O objetivo é criar uma pequena experiência de entrada que comunique
o DNA do Mental.

O usuário deve olhar para o Splash e perceber:

"Este aplicativo é sobre evolução mental."

============================================================
3. REGRA FUNDAMENTAL
============================================================

NÃO alterar a identidade visual geral do Mental sem necessidade.

Preservar a paleta (Seção 0.2), tipografia e elementos de identidade
já existentes no aplicativo sempre que possível.

O Splash deve parecer uma evolução natural do Mental atual,
e não um aplicativo diferente.

Não criar uma nova identidade visual desconectada do produto.

Antes de qualquer alteração:

1. analisar a implementação atual;
2. identificar os assets existentes (incluindo o ícone "M" da Seção 0.3);
3. confirmar os valores exatos da paleta já usada (Seção 0.2);
4. identificar tipografia;
5. identificar logo;
6. identificar animações existentes;
7. identificar componentes reutilizáveis;
8. identificar limitações da implementação atual;
9. identificar o fluxo real de inicialização;
10. identificar o tempo real de carregamento.

Não assumir.

Não inventar.

Não substituir elementos existentes sem justificativa técnica e visual.

============================================================
4. CONCEITO CRIATIVO
============================================================

O conceito central do Splash deve ser:

MENTE EM MOVIMENTO.

A animação deve sugerir que pensamentos, conhecimento, ideias,
informações e possibilidades estão se conectando.

A experiência pode utilizar de maneira extremamente sutil:

- partículas;
- pontos;
- conexões;
- linhas;
- símbolos;
- números;
- letras;
- palavras;
- pequenos elementos geométricos;
- sinais visuais relacionados a conhecimento;
- movimento;
- expansão;
- conexão;
- progressão.

IMPORTANTE:

Esses elementos NÃO devem transformar a tela em uma colagem.

Devem funcionar como uma linguagem visual abstrata.

O usuário deve perceber primeiro a identidade do Mental,
e apenas depois perceber os detalhes.

============================================================
5. IDEIA DE NARRATIVA VISUAL
============================================================

Explorar uma sequência curta semelhante a:

ESTADO 1 — POTENCIAL

A tela inicia limpa.

Poucos elementos.

Sensação de espaço e expectativa.

ESTADO 2 — ATIVAÇÃO

Pequenos pontos ou elementos começam a aparecer.

Eles se movimentam suavemente.

Alguns começam a se conectar.

ESTADO 3 — CONEXÃO

As conexões formam uma composição visual relacionada à ideia de
mente, conhecimento e evolução, convergindo em direção ao ícone "M"
já existente (Seção 0.3).

Não necessariamente utilizar literalmente um cérebro.

Preferir uma representação mais sofisticada e abstrata.

ESTADO 4 — CONCENTRAÇÃO

Os elementos convergem para o centro, formando o ícone "M" oficial.

A identidade do Mental começa a surgir.

ESTADO 5 — IDENTIDADE

O logotipo:

MENTAL

surge de maneira limpa e forte, ao lado ou abaixo do ícone "M".

Se houver espaço/tempo para exibir a tagline, usar exclusivamente
a frase oficial definida na Seção 0.1.

ESTADO 6 — ATIVAÇÃO FINAL

O logotipo recebe um pequeno movimento/pulso de energia.

Muito sutil.

Nada exagerado.

ESTADO 7 — TRANSIÇÃO

O Splash desaparece naturalmente e entrega o usuário à Home.

A transição não deve parecer um corte seco.

============================================================
6. O LOGOTIPO É O PROTAGONISTA
============================================================

O logo MENTAL (e o ícone "M" oficial, Seção 0.3) devem ser o elemento
principal.

Não criar uma animação tão complexa que o logo se torne secundário.

A sequência deve conduzir visualmente o usuário até:

MENTAL

O nome deve permanecer legível.

Não utilizar distorções excessivas.

Não utilizar efeitos exagerados.

Não utilizar partículas sobre o texto a ponto de prejudicar a leitura.

============================================================
7. SENSAÇÃO DE MOVIMENTO
============================================================

A animação deve possuir movimento contínuo e natural.

Evitar:

- movimentos bruscos;
- entradas instantâneas;
- elementos pulando sem contexto;
- excesso de escalas;
- excesso de rotação;
- animações infantis;
- efeitos de "game antigo";
- efeitos genéricos de loading;
- excesso de brilho;
- excesso de partículas.

Preferir:

- easing suave;
- aceleração e desaceleração naturais;
- microinterações;
- movimento orgânico;
- profundidade;
- transições contínuas.

A sensação desejada é:

"algo está despertando".

============================================================
8. IDENTIDADE COGNITIVA
============================================================

O Splash deve comunicar que o Mental possui muitos universos de
conhecimento.

Entretanto, NÃO apresentar uma lista de mundos durante o Splash.

Em vez disso, utilizar uma linguagem abstrata que possa representar:

MATEMÁTICA
ENGLISH
LIBRAS
FILOSOFIA
CONHECIMENTO
LÓGICA
MEMÓRIA
MOVEMENT
FUTEBOL
CIÊNCIA
e outros conteúdos.

Exemplo conceitual:

números → letras → símbolos → conexões → convergência → ícone "M" → MENTAL.

Tudo deve acontecer rapidamente e de maneira elegante, dentro da
duração-alvo definida na Seção 0.4.

============================================================
9. MENTAL COMO ECOSSISTEMA
============================================================

O Splash também deve ser preparado conceitualmente para representar
a evolução futura do Mental.

O aplicativo possui potencial para:

- desafios individuais;
- rankings;
- competição;
- batalhas 1x1;
- batalhas em equipes;
- Mental Arena em sala de aula;
- evolução por conhecimento;
- interação social através de incentivos visuais;
- Movement;
- experiências educacionais.

O Splash não deve representar apenas o estado atual do aplicativo.

Deve representar a marca Mental como um ecossistema em evolução.

============================================================
10. EXPERIÊNCIA EMOCIONAL
============================================================

O usuário deve sentir, em poucos segundos:

CURIOSIDADE
+
ENERGIA
+
INTELIGÊNCIA
+
EVOLUÇÃO
+
VONTADE DE JOGAR

O Splash não deve transmitir:

- pressão;
- ansiedade;
- competição agressiva;
- excesso de informação;
- sensação de prova escolar;
- sensação de aplicativo corporativo.

A sensação deve ser:

"Vamos ver até onde minha mente consegue chegar."

============================================================
11. ÁUDIO
============================================================

Se a arquitetura atual do Mental permitir áudio no Splash,
avaliar uma assinatura sonora extremamente curta.

O áudio deve ser:

- discreto;
- moderno;
- memorável;
- positivo;
- tecnológico;
- não invasivo.

Pode haver uma pequena evolução sonora acompanhando
o surgimento do logo.

NUNCA utilizar:

- som alto;
- som assustador;
- efeito agressivo;
- áudio longo;
- áudio obrigatório.

O Splash deve funcionar perfeitamente sem áudio.

Respeitar as configurações de áudio do usuário.

Se o usuário tiver efeitos sonoros desativados,
o Splash não deve forçar reprodução.

============================================================
12. PERFORMANCE
============================================================

Performance é requisito obrigatório.

O Splash NÃO pode deixar o aplicativo mais lento.

A duração-alvo está definida na Seção 0.4 (entre 1,2 e 2,5 segundos
para a Opening Experience completa).

Avaliar:

- tempo real de inicialização;
- cold start;
- warm start;
- consumo de memória;
- GPU;
- CPU;
- carregamento de assets;
- tamanho dos arquivos;
- uso de animações;
- frame rate;
- possíveis jank/frame drops.

A animação deve ser fluida inclusive em dispositivos Android
de menor capacidade.

Não criar efeitos que dependam de processamento excessivo.

============================================================
13. ANDROID
============================================================

Inspecionar a implementação atual de Splash.

Verificar compatibilidade com o mecanismo nativo de Splash Screen
adequado à versão Android suportada pelo Mental.

IMPORTANTE:

Diferenciar:

A) SYSTEM SPLASH

da

B) OPENING EXPERIENCE / TRANSITION

Caso existam limitações impostas pelo Android para a Splash Screen,
não tentar contorná-las de maneira inadequada.

Se necessário, utilizar:

SYSTEM SPLASH
+
microtransição nativa dentro do aplicativo.

O resultado visual final deve parecer uma única experiência contínua.

============================================================
14. EVITAR SPLASH ARTIFICIALMENTE LONGO
============================================================

NÃO adicionar atraso artificial apenas para permitir que a animação
termine.

O aplicativo deve abrir assim que estiver pronto.

Se a inicialização terminar antes da animação:

→ encerrar elegantemente a animação.

Se a inicialização demorar:

→ utilizar o tempo real de carregamento de maneira natural,
sem criar uma tela de espera artificial.

O Splash não pode prejudicar UX.

============================================================
15. ADAPTAÇÃO AO ESTADO REAL DO APP
============================================================

O Splash deve respeitar:

- login;
- sessão existente;
- usuário novo;
- usuário recorrente;
- carregamento inicial;
- ausência de conexão;
- conexão lenta;
- erro de inicialização.

Não criar comportamento que bloqueie o fluxo.

O Splash deve funcionar tanto para:

NOVO USUÁRIO

quanto para:

USUÁRIO RECORRENTE.

============================================================
16. ACESSIBILIDADE
============================================================

A experiência não pode depender exclusivamente de:

- cor;
- som;
- movimento.

O usuário deve conseguir utilizar o Mental normalmente
independentemente dessas características.

Evitar efeitos de movimento excessivos.

Respeitar preferências de acessibilidade do sistema quando aplicável
(ex.: configuração de "reduzir movimento" do Android, se o usuário
tiver essa opção ativada no sistema).

============================================================
17. DESIGN SYSTEM
============================================================

Antes de criar novos elementos:

verificar se já existem no Mental:

- componentes;
- ícones (incluindo o "M" oficial, Seção 0.3);
- assets;
- animações;
- fontes;
- tokens;
- cores (paleta já conhecida, Seção 0.2);
- dimensões;
- padrões de motion.

Reutilizar o que fizer sentido.

Evitar duplicação.

Não criar um "mini design system" separado apenas para o Splash.

============================================================
18. QUALIDADE VISUAL
============================================================

O resultado final deve parecer produto profissional.

Referência de qualidade:

- aplicativo moderno;
- produto educacional premium;
- game moderno;
- experiência de marca;
- movimento cinematográfico sutil.

Mas sem copiar qualquer aplicativo específico.

Não copiar:

- logos;
- animações;
- personagens;
- identidade visual;
- assets;
- interfaces de terceiros.

Criar uma solução própria para o Mental.

============================================================
19. MICROINTERAÇÃO
============================================================

Avaliar pequenas microinterações.

Exemplos conceituais:

- ponto de luz;
- conexão;
- pulso;
- expansão;
- convergência;
- pequeno deslocamento;
- surgimento progressivo do logo.

Esses elementos devem funcionar como uma assinatura visual.

Menos é mais.

============================================================
20. FUTURO DO MENTAL
============================================================

O conceito criado agora deve permitir que no futuro o Mental evolua
sem precisar redesenhar completamente sua identidade.

O mesmo conceito visual de:

CONEXÃO
→ MOVIMENTO
→ EVOLUÇÃO
→ MENTAL

poderá futuramente ser utilizado em:

- Battle;
- Arena;
- eventos;
- temporadas;
- conquistas;
- grandes desafios;
- abertura de novos mundos;
- momentos especiais.

O Splash deve, portanto, funcionar como uma pequena "assinatura
cinética" da marca.

============================================================
21. PROCESSO OBRIGATÓRIO DO CLAUDE CODE
============================================================

ANTES DE ALTERAR QUALQUER CÓDIGO:

ETAPA 1 — INSPEÇÃO

Mapear:

- Splash atual;
- arquivos;
- classes;
- composables/views;
- assets (incluindo confirmar o ícone "M" oficial);
- tema;
- cores (confirmar valores hex exatos da paleta da Seção 0.2);
- tipografia;
- logo;
- animações;
- navigation;
- inicialização;
- dependências;
- versões Android;
- Splash API utilizada.

ETAPA 2 — DIAGNÓSTICO

Explicar:

- como funciona atualmente;
- por que o resultado atual pode ser melhorado;
- quais limitações existem;
- quais componentes podem ser reaproveitados;
- quais mudanças são necessárias.

ETAPA 3 — PROPOSTA VISUAL

Criar uma proposta objetiva contendo:

- conceito;
- sequência da animação;
- duração aproximada (número concreto, dentro ou justificando desvio
  da faixa de 1,2 a 2,5s definida na Seção 0.4);
- elementos;
- transições;
- comportamento;
- tratamento do logo e do ícone "M";
- tratamento da tagline oficial (Seção 0.1), se exibida;
- transição para Home;
- tratamento de áudio, se aplicável.

ETAPA 4 — PROPOSTA TÉCNICA

Informar:

- arquivos que serão modificados;
- arquivos novos;
- componentes novos;
- dependências;
- impacto na inicialização;
- impacto de performance;
- estratégia de compatibilidade Android.

ETAPA 5 — VALIDAÇÃO

Antes de implementar alterações que mudem significativamente
a identidade visual, apresentar a proposta e aguardar aprovação.

NÃO implementar uma direção visual completamente diferente
por iniciativa própria.

============================================================
22. IMPLEMENTAÇÃO
============================================================

Após aprovação da proposta:

Implementar o Splash seguindo a arquitetura existente.

Priorizar:

- código limpo;
- baixo acoplamento;
- reutilização;
- manutenção;
- performance;
- estabilidade;
- compatibilidade;
- testes.

Não alterar funcionalidades não relacionadas.

Não modificar:

- regras de XP;
- ranking;
- progressão;
- conteúdo;
- banco de dados;
- autenticação;
- Movement;
- Libras;
- English;
- Battle;
- qualquer outra funcionalidade,

a menos que seja tecnicamente indispensável ao fluxo do Splash.

Caso seja indispensável:

PARAR.

DOCUMENTAR.

SOLICITAR APROVAÇÃO.

============================================================
23. TESTES
============================================================

Testar obrigatoriamente:

1. cold start;
2. warm start;
3. primeiro acesso;
4. usuário logado;
5. usuário deslogado;
6. conexão rápida;
7. conexão lenta;
8. sem conexão;
9. dispositivo de baixo desempenho;
10. diferentes tamanhos de tela;
11. diferentes densidades;
12. modo claro/escuro, se suportado;
13. áudio habilitado;
14. áudio desabilitado;
15. interrupção do aplicativo;
16. retorno do background;
17. rotação, caso aplicável;
18. frame drops;
19. consumo de memória;
20. transição para Home;
21. tempo total medido contra a duração-alvo da Seção 0.4.

============================================================
24. CRITÉRIOS DE ACEITAÇÃO
============================================================

O redesign será considerado aprovado somente se:

[ ] O Splash estiver visualmente mais sofisticado.
[ ] O Splash estiver mais fluido.
[ ] O logo MENTAL e o ícone "M" oficial forem protagonistas.
[ ] A identidade do aplicativo estiver claramente presente.
[ ] A tagline oficial ("Mental é quem conquista com a mente") for a
    única frase usada, caso alguma frase seja exibida.
[ ] A paleta de cores real do app for respeitada, sem cor nova
    introduzida sem justificativa.
[ ] A experiência transmitir conhecimento e evolução.
[ ] A animação não parecer genérica.
[ ] A animação não parecer infantil.
[ ] Não houver excesso de elementos.
[ ] Não houver atraso artificial perceptível.
[ ] A duração total estiver dentro da faixa definida (Seção 0.4) ou
    o desvio estiver justificado e aprovado.
[ ] A abertura não prejudicar o tempo de inicialização.
[ ] A experiência funcionar em dispositivos modestos.
[ ] A transição para Home for natural.
[ ] A identidade visual existente for respeitada.
[ ] Não houver regressões.
[ ] O aplicativo continuar funcionando com áudio desativado.
[ ] Nenhum recurso externo desnecessário for introduzido.
[ ] Nenhuma funcionalidade fora do escopo for alterada.

============================================================
25. PRINCÍPIO CRIATIVO FINAL
============================================================

O Splash do Mental deve responder visualmente a uma pergunta:

"O que é o Mental?"

A resposta não deve ser escrita em um parágrafo.

Ela deve ser SENTIDA.

MENTAL É:

CONHECIMENTO EM MOVIMENTO.

MENTE EM EVOLUÇÃO.

DESAFIO QUE GERA APRENDIZADO.

APRENDIZADO QUE GERA EVOLUÇÃO.

EVOLUÇÃO QUE GERA COMPETIÇÃO.

COMPETIÇÃO QUE MOTIVA A CONTINUAR.

O Splash deve representar exatamente essa ideia — e, quando houver
texto em tela, reforçá-la através da tagline oficial já estabelecida
(Seção 0.1), não de uma frase nova concorrente.

Não criar simplesmente uma abertura bonita.

Criar uma abertura que faça o usuário reconhecer:

"ESTOU ENTRANDO NO MENTAL."

============================================================
26. ENTREGA FINAL DO CLAUDE CODE
============================================================

Ao finalizar, apresentar:

1. diagnóstico do Splash anterior;
2. conceito visual escolhido;
3. justificativa da direção;
4. storyboard da animação;
5. arquivos modificados;
6. arquivos criados;
7. dependências adicionadas;
8. impacto de performance;
9. testes executados;
10. resultado dos testes (incluindo duração medida vs. Seção 0.4);
11. eventuais limitações;
12. screenshots ou evidências quando disponíveis;
13. confirmação de que nenhuma funcionalidade fora do escopo
    foi modificada.

IMPORTANTE:

Não declarar sucesso apenas porque o código compilou.

O objetivo é:

QUALIDADE VISUAL
+
IDENTIDADE
+
FLUIDEZ
+
PERFORMANCE
+
ESTABILIDADE
+
EXPERIÊNCIA.

O MENTAL DEVE ABRIR COMO UMA EXPERIÊNCIA,
NÃO COMO UMA TELA DE CARREGAMENTO.
