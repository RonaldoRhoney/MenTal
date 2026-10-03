# MENTAL — Personagem/Mascote Oficial da Marca

**Status:** APROVADO. Novo personagem central de identidade visual do MENTAL — substitui o splash atual ("M com sinapse") e se torna a representação visual do MENTAL LINGO. Produção de arte/animação via Canva (já conectado ao ambiente, conforme MAPA_TRAJETORIA_MUNDOS_V1.md), com investigação técnica adicional para a camada de animação.

---

## 1. Nome do personagem — não é um mascote separado, é o próprio MENTAL personificado

**O personagem se chama "Mental", o mesmo nome do app — decisão explícita de Rhoney.** Isso é uma diferença conceitual importante em relação a mascotes de outros apps (como "Duo" no Duolingo, que é um personagem com nome e identidade própria, separados do nome do produto): o Mental **não tem um nome separado do app**, porque ele **é o próprio app personificado**, não um bichinho ou assistente que mora dentro dele.

Implicações práticas dessa decisão:
- Em nenhum texto, tela ou comunicação do app o personagem deve ser apresentado com um nome diferente de "Mental" — nunca criar um apelido ou nome próprio alternativo para ele.
- Falas, textos de apresentação, ou qualquer menção ao personagem em primeira pessoa (ex.: numa eventual tela de boas-vindas, ou em respostas do MENTAL LINGO) devem soar como "o Mental falando", reforçando que app e personagem são a mesma entidade — não um mascote que representa o app, e sim o app com um rosto.
- Essa decisão reforça ainda mais a integração do personagem com o MENTAL LINGO (seção 3.2): quando o usuário interage com o LINGO, ele está, na prática, conversando com "o Mental" em pessoa, não com uma funcionalidade separada dentro do app.

## 2. Conceito visual

Personagem original do MENTAL — um **pequeno robô companheiro com "miolo" de cérebro** (não uma cópia do mascote de nenhum outro app, incluindo a coruja do Duolingo). Combina duas camadas de identidade:
- **Corpo de robô**: remete a tecnologia/IA, coerente com o MENTAL LINGO (assistente por voz) e com a linguagem visual já usada no app.
- **"Miolo" de cérebro/sinapse na cabeça**: remete ao nome do próprio app ("Mental") e preserva uma linha de continuidade com o logo anterior ("M com sinapse") — não é uma ruptura total da identidade visual já trabalhada, e sim uma evolução dela, incorporada como detalhe do novo personagem.
- Paleta de cores alinhada à identidade já estabelecida do MENTAL (dourado/teal/violeta sobre fundo escuro).

Protótipo de conceito já validado com Rhoney (ver histórico desta conversa) — a arte final de produção deve elevar esse conceito ao nível de acabamento profissional via Canva, não permanecer no nível de esboço simples usado para validação da ideia.

## 3. Onde o personagem aparece

### 3.1 Splash de abertura do app (substitui o design atual)
O splash atual ("M com sinapse") é **substituído** pelo personagem animado. Esta é uma decisão de identidade visual explícita de Rhoney — o personagem vivo na abertura do app é mais memorável e estabelece a "cara" do MENTAL desde o primeiro segundo de uso, reforçando a ideia de companheiro, não apenas um logotipo estático.

### 3.2 Representação visual do MENTAL LINGO
O personagem passa a ser a **cara visual do MENTAL LINGO**, substituindo o ícone genérico de microfone usado hoje. Isso une dois propósitos num único elemento de design: mascote geral do app E rosto do assistente de voz — decisão explícita de Rhoney. Como o personagem é literalmente "o Mental" (seção 1), essa integração reforça que conversar com o LINGO é conversar com o próprio app personificado.

### 3.3 Demais pontos de interação (orientação original do pedido)
Conforme descrito por Rhoney: apresentação, dicas, orientações, carregamento, e qualquer outro "diversos momentos" de interação com o usuário ao longo do app — o personagem deve aparecer de forma consistente, cumprindo o papel de guia/companheiro em toda a experiência, não apenas em pontos isolados.

## 4. Expressões e gestos — interação compreensível

O personagem deve ser animado e interagir de forma **inteligível** com o usuário, com expressões e gestos claros:

| Expressão/gesto | Quando usa |
|---|---|
| Feliz/neutro | Estado padrão, navegação comum |
| Apontando | Chamando atenção para um elemento específico (dica, botão novo, orientação) |
| OK/positivo | Resposta correta, confirmação |
| Negativo/balançando "não" | Resposta incorreta — **tom suave, nunca zombeteiro ou humilhante**, seguindo o mesmo princípio já estabelecido em MENTAL_ESPECIFICACAO_FLUXO_PROGRESSAO_MAPA_RANKING_FEEDBACK_V1.1.md ("erro nunca é tratado de forma agressiva ou humilhante") |
| Pensando | Carregamento, processamento (ex.: enquanto o MENTAL LINGO processa uma pergunta por voz) |
| Comemorando | Conquista de Desafio, Relâmpago, ou Mundo inteiro — reutilizando a lógica de celebração já especificada na seção 5.1 daquele mesmo documento |
| Acenando | Boas-vindas, primeiro acesso ao app |
| Dormindo/parado | App ocioso por tempo prolongado, ou tela de carregamento mais longa |

Esta lista é a base inicial aprovada por Rhoney — pode ser expandida no futuro conforme necessidade identificada em uso real.

## 5. Evolução do personagem — Fase 1 (atual, custo zero) e Fase 2 (futura, pós-monetização)

Rhoney definiu explicitamente uma evolução em duas fases, respeitando a disciplina de custo zero já praticada em todo o projeto:

### 5.1 Fase 1 — Evolução visual por marcos de gamificação (implementar agora)
O personagem muda de aparência conforme o progresso real do usuário no app — por exemplo, pequenas variações visuais (cores, acessórios, destaques) atreladas a marcos já existentes na Regra Oficial de Gamificação (REGRA_OFICIAL_GAMIFICACAO_MENTAL.md): streak de 7/15/30/100 dias, conquista de Mundo inteiro, nível alcançado, etc. Não envolve nenhum processamento de IA nem custo de API — é lógica de exibição condicional sobre dados que o app já possui.

### 5.2 Fase 2 — Personalidade adaptativa e aprendizado real (futuro, após monetização sustentável)
Rhoney sinalizou explicitamente que etapas mais avançadas de evolução do personagem — adaptação de tom/comportamento ao padrão de uso de cada usuário, ou aprendizado mais sofisticado — ficam reservadas para **depois que o MENTAL já se sustentar financeiramente**, não implementadas nesta fase. Isso é coerente com a decisão já registrada de que anúncios/monetização só serão tratados após a conclusão da fase de produção atual. **Não implementar nenhum elemento de Fase 2 nesta entrega.**

## 6. Escopo técnico (a propor em detalhe por Claude Code)

### 6.1 Produção de arte
- Seguir o mesmo processo já estabelecido para o Mapa de Trajetória: uso do Canva (já conectado via MCP) para a produção da arte final do personagem, elevando o conceito validado a acabamento profissional.
- Produzir a arte em todas as expressões/gestos listados na seção 4, mantendo consistência visual entre elas (mesmo estilo, mesma paleta, mesma "personalidade" de traço).

### 6.2 Camada de animação — investigação técnica necessária
Animação de verdade (não apenas imagem estática) é um salto de complexidade sobre a produção de imagem já praticada no projeto. Claude Code deve investigar e propor a ferramenta adequada antes de implementar, priorizando opções gratuitas, consistentes com a disciplina de custo zero já estabelecida — por exemplo, formatos de animação vetorial leve (como Rive ou Lottie, ambos com camadas gratuitas de uso) adequados para app Flutter. Apresentar a comparação de opções, custo (se houver) e esforço de integração antes de iniciar a implementação.

### 6.3 Integração nos pontos de uso
- Substituir o splash atual pelo personagem animado.
- Substituir o ícone de microfone do MENTAL LINGO pelo personagem (em sua expressão apropriada a cada estado da interface de voz já especificada em MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md — Pronto, Ouvindo, Processando, Respondendo, Falha).
- Integrar o personagem aos demais pontos de interação (dicas, orientações, celebrações de progresso) de forma consistente em todo o app.
- Implementar a lógica de variação visual por marcos de gamificação (Fase 1, seção 5.1).
- Garantir que nenhum texto/fala do personagem use nome diferente de "Mental" (seção 1).

## 8. Status de implementação (03/10/2026)

**Arte produzida e aprovada; personagem integrado nos principais pontos de uso do app (§6.3), como imagem estática com crossfade — não com rig animado no Rive (decisão de escopo abaixo). Testado no aparelho real pelo próprio Rhoney, com 2 rodadas de ajuste.**

**§6.2 (investigação de ferramenta de animação) — concluída, mas a execução foi reescopada.** A recomendação original (Rive, por causa das state machines nativas pra alternância de estado) continua tecnicamente correta, mas **o rig em si (importar a arte no editor do Rive, animar bones/meshes, montar a state machine) é trabalho manual num editor visual — não dá pra fazer por código/CLI nesta sessão.** Decisão de escopo de Rhoney (03/10/2026): integrar agora como **imagem estática por expressão com crossfade suave** (`MentalCharacter`, `client/lib/widgets/mental_character.dart`, `AnimatedSwitcher` entre as 8 PNGs), e deixar o rig de verdade no Rive pra quando esse trabalho manual acontecer — a troca de abordagem depois é só trocar a implementação interna do widget, a API (`MentalCharacterExpression`) já fica pronta pra isso.

**§6.1 (produção de arte) — as 8 expressões da §4 produzidas, aprovadas e com fundo transparente.** Geradas via Canva (`generate-image` + `remove-background`), estilo robô com "miolo" de cérebro/sinapse (glossy 3D), paleta final definida com Rhoney em iteração direta: corpo em lavanda clara, visor/detalhes em azul-marinho escuro, pés e detalhes em roxo, com pequenos acabamentos nas cores da marca (dourado `#E2BE6E` e teal `#3FA796`, tirados direto de `app_theme.dart`) no brilho do cérebro e nas bordas do corpo. Assets em `client/assets/character/*.png` (800×800, upscale de thumbnail 200×200 — ver nota de qualidade abaixo).

**§6.3 (integração nos pontos de uso) — concluída nos pontos principais:**
- **Splash**: personagem (acenando) substitui o antigo `_MentalMarkPainter` ("M com sinapse" desenhado stroke-by-stroke, removido). Duração do splash esticada de 2400ms pra 3600ms e curva de entrada trocada (easeInOut em vez de easeOutCubic + easeOutBack) depois do achado real de Rhoney testando ("ficou muito rápido"/"deve ir surgindo suavemente").
- **Transição entre estágios do app** (splash→tutorial→login→age gate→onboarding→Home): achado real de Rhoney testando ("a Home simplesmente pula") — cada estágio era um `return` condicional direto em `main.dart`, sem nenhuma animação. Corrigido com um `AnimatedSwitcher` (crossfade de 420ms) envolvendo todo o corpo de `build()`, chaveado por `_currentStageKey()` — cobre todas as trocas de estágio de uma vez, não só splash→Home.
- **MENTAL LINGO**: personagem substitui `_GlowingMic` (ícone genérico, removido) no banner da Home, e reage aos 5 estados da conversa (Pronto/Ouvindo/Processando/Respondendo/Falha → felizNeutro/acenando/pensando/okPositivo/negativoSuave).
- **Resultado do Desafio**: personagem mostra `okPositivo` no acerto comum, `negativoSuave` no erro (sem pulso, mesmo princípio de "Erro: nenhuma celebração"), e `comemorando` (maior, com pulso) em marcos grandes (nível/território/mundo/badge). Tamanho ajustado de 84/110px pra 140/180px depois do achado real de Rhoney ("muito pequeno").
- **Dicas**: personagem `apontando`, pequeno, ao lado de cada dica mostrada.

**Pendente, não iniciado:**
- Rig de verdade no Rive (trabalho manual no editor deles — ver nota de reescopo acima).
- §5.1: lógica de variação visual por marco de gamificação (streak 7/15/30/100, Mundo completo, nível) — ainda não implementada.
- Integração em pontos de orientação adicionais não cobertos acima (outras telas fora do núcleo Desafio/LINGO/splash).
- Nenhum elemento de Fase 2 (§5.2) foi tocado, como determinado.

**Nota de qualidade de imagem**: os 8 PNGs são upscale (Lanczos) de thumbnails 200×200 retornados pela API de geração — não a resolução nativa. Ficam bons em tamanho de ícone/banner; podem ficar levemente suaves em usos muito grandes. Se isso incomodar, a correção é baixar manualmente versões em resolução nativa mais alta pelos links do Canva e substituir os arquivos em `client/assets/character/`.

## 7. Critério de aceite

- Personagem se apresenta e é referenciado, em qualquer parte do app, sempre como "Mental" — nunca com nome próprio alternativo.
- Personagem substitui completamente o splash "M com sinapse" atual, mantendo elemento de continuidade visual (a sinapse/luz incorporada ao design do novo personagem).
- Personagem usado como rosto visual do MENTAL LINGO, substituindo o ícone de microfone genérico.
- Todas as expressões/gestos da seção 4 produzidas e integradas nos momentos de uso correspondentes.
- Erro/resposta incorreta tratado com expressão suave, nunca agressiva ou humilhante.
- Variação visual por marcos de gamificação (Fase 1) implementada, sem nenhum custo de API ou processamento de IA.
- Nenhum elemento de Fase 2 (personalidade adaptativa/aprendizado) implementado nesta entrega.
- Ferramenta de animação escolhida e justificada por Claude Code antes da implementação, priorizando opção gratuita.
