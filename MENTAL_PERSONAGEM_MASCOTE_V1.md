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

**Arte conceitual aprovada por Rhoney; ferramenta de animação escolhida; integração ainda não iniciada.**

**§6.2 (investigação de ferramenta de animação) — concluída.** Recomendação: **Rive**, não Lottie — o personagem precisa reagir a múltiplos estados vindos do app (feliz, apontando, positivo, negativo, pensando, comemorando, acenando, dormindo), e Rive foi feito pra exatamente isso (state machines nativas, arquivo 10-15x menor que Lottie equivalente, 120 FPS), enquanto Lottie é melhor pra animação pré-renderizada linear sem alternância de estado. Pacote Flutter (`rive`, pub.dev) é open-source, sem custo de runtime. Canva continua sendo usado pra arte estática de cada expressão; o Rive entra depois, pra montar o personagem com estado interativo a partir dessas artes.

**§6.1 (produção de arte) — as 8 expressões da §4 produzidas e aprovadas**, geradas via Canva, estilo robô com "miolo" de cérebro/sinapse (glossy 3D), paleta final definida com Rhoney em iteração direta: corpo em lavanda clara, visor/detalhes em azul-marinho escuro, pés e detalhes em roxo, com pequenos acabamentos nas cores da marca (dourado `#E2BE6E` e teal `#3FA796`, tirados direto de `app_theme.dart`) no brilho do cérebro e nas bordas do corpo. Links das 8 expressões aprovadas: ver mensagem da sessão de 03/10/2026 (a incluir nos assets finais do projeto quando a produção para Rive começar).

**Pendente, não iniciado nesta rodada:**
- Rigging das 8 expressões em um único personagem Rive com state machine (§6.2 cobre só a escolha da ferramenta, não a execução do rig).
- §6.3: substituição do splash atual, substituição do ícone do MENTAL LINGO (5 estados: Pronto/Ouvindo/Processando/Respondendo/Falha), integração em dicas/orientações/celebrações ao longo do app.
- §5.1: lógica de variação visual por marco de gamificação (streak 7/15/30/100, Mundo completo, nível) — depende da integração básica (§6.3) estar pronta primeiro.
- Nenhum elemento de Fase 2 (§5.2) foi tocado, como determinado.

## 7. Critério de aceite

- Personagem se apresenta e é referenciado, em qualquer parte do app, sempre como "Mental" — nunca com nome próprio alternativo.
- Personagem substitui completamente o splash "M com sinapse" atual, mantendo elemento de continuidade visual (a sinapse/luz incorporada ao design do novo personagem).
- Personagem usado como rosto visual do MENTAL LINGO, substituindo o ícone de microfone genérico.
- Todas as expressões/gestos da seção 4 produzidas e integradas nos momentos de uso correspondentes.
- Erro/resposta incorreta tratado com expressão suave, nunca agressiva ou humilhante.
- Variação visual por marcos de gamificação (Fase 1) implementada, sem nenhum custo de API ou processamento de IA.
- Nenhum elemento de Fase 2 (personalidade adaptativa/aprendizado) implementado nesta entrega.
- Ferramenta de animação escolhida e justificada por Claude Code antes da implementação, priorizando opção gratuita.
