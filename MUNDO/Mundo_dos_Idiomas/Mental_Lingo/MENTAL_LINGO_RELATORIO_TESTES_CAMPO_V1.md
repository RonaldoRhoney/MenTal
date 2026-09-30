# MENTAL LINGO — Relatório Consolidado de Testes de Campo (Rhoney, 27-28/09/2026)

**Status:** Relatório de ocorrências reais, coletadas por Rhoney via captura de tela em uso real do app (ambientes variados: ônibus com ruído, sala fechada silenciosa). Complementa MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md com evidência empírica concreta. A ser entregue ao Claude Code **depois** que Rhoney implementar o conteúdo de expressões idiomáticas já formalizado (MUNDO_IDIOMAS_INGLES_EXPRESSOES_IDIOMATICAS_V1.md) — não é para execução imediata.

---

## 1. Resumo executivo

Foram analisados 11 casos de teste reais, cobrindo tradução de frases e comportamento de captura de voz em três modos distintos (apertar-e-segurar, toque único com dois toques manuais, toque único com detecção automática de fim). Dois problemas distintos e independentes foram identificados:

1. **Qualidade de tradução**: a versão atual do LINGO usa tradução automática local do aparelho (não o modelo de linguagem já especificado como arquitetura-alvo), com taxa de erro relevante em frases que exigem entendimento de contexto/estrutura, mesmo com transcrição de voz sempre correta.
2. **Captura de voz no modo de detecção automática**: confirmado, em teste real, o comportamento problemático já hipotetizado — em ambiente ruidoso (ônibus), a escuta se estendeu por 1 minuto e 20 segundos para uma frase curta, continuando a captar som ambiente após o usuário terminar de falar.

## 1.1 Atualização de decisão — resolução dos dois pontos em aberto (29/09/2026)

Claude Code corrigiu o bug de vazamento de moldura de instrução (seção 2.2, item 4) de forma independente de decisão de produto — **já implementado e testado, 34/34 testes do LINGO passando**. Os outros dois pontos deste relatório exigiam decisão explícita de Rhoney antes de qualquer implementação, pelos motivos abaixo. Ambas as decisões seguem registradas aqui.

### Motor de tradução — decisão: híbrido sempre gratuito, nunca pago

Claude Code identificou uma contradição real entre este relatório e decisões já registradas e em produção no código (`mental_lingo.py`): em 23/09, foi fixada a regra "V1 100% custo zero — nenhuma IA generativa, nenhuma API paga, nenhum RAG", e em 26/09 a tradução de frase inteira passou a ser feita via **Google ML Kit no aparelho** (grátis, offline), por decisão explícita de custo zero. Os erros de tradução deste relatório (feira/fair, "dinner soup", "deu sinal"/"signed") são, portanto, **limitações conhecidas de tradução automática on-device**, não um motor implementado por engano — a arquitetura de "modelo de linguagem + RAG" descrita na seção 5 original deste relatório e em MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md **não é mais a orientação vigente** nesses termos.

**Decisão final de Rhoney: o motor de tradução deve seguir uma abordagem híbrida, sempre gratuita, sem exceção.** Isto é:
- Tentar tradução via um provedor de modelo de linguagem com **tier gratuito real** (ex.: a mesma chave de API do Gemini já configurada no projeto para geração de imagens, que também oferece tradução de texto dentro de sua cota gratuita).
- Monitorar o consumo dessa cota gratuita continuamente.
- **Fallback automático e obrigatório para o Google ML Kit local** assim que a cota gratuita se esgotar, ficar indisponível, ou o serviço falhar por qualquer motivo — nunca partir para uma chamada paga, em nenhuma circunstância, mesmo que isso signifique voltar à qualidade de tradução mais limitada do ML Kit em determinados momentos.
- O critério de custo zero continua sendo **inegociável e estrutural** para este projeto — a melhoria de qualidade via LLM gratuito é um ganho oportunista dentro da cota disponível, nunca uma dependência que exija orçamento.

Os 11 casos de teste deste relatório (seções 2.1 e 2.2) continuam válidos como conjunto de regressão: devem ser usados para validar que, **quando a tradução ocorrer via o provedor de LLM gratuito**, os 5 casos de erro (seção 2.2) passam a ser traduzidos corretamente, e que o fallback para ML Kit (quando a cota se esgotar) continua produzindo, no mínimo, os mesmos resultados já documentados na seção 2.1.

### Modo 3 (detecção automática) — decisão: reintroduzir, com UI de 3 modos e correções

Hoje existem apenas 2 modos de captura em produção (apertar-e-segurar e toque duplo manual) — o Modo 3 foi removido de propósito em 27/09 por causa do bug de 1:20 de escuta documentado na seção 3.2. Rhoney decidiu **reintroduzir o Modo 3 como terceira opção**, com o seguinte desenho e correções:

- **Interface**: substituir o indicador binário atual ("Modo: toque único (trocar para apertar e segurar)") por um **seletor de 3 opções** (ex.: chips ou radio buttons) — "Apertar e segurar" / "Toque duplo" / "Detecção automática" — com o modo ativo sempre visível na tela, mesmo padrão de clareza já usado hoje.
- **Teto de tempo revisado**: reduzir drasticamente o teto que permitiu 1:20 de escuta — orientação de Claude: algo na faixa de **15 a 20 segundos de silêncio contínuo** (não duração total da fala) antes de encerrar automaticamente, valor final a ajustar por Claude Code com base em teste real.
- **Indicador visual de "ainda ouvindo"**: implementar um sinal visual claro de que a escuta automática continua ativa, permitindo ao usuário intervir manualmente (ex.: tocando) para forçar o encerramento a qualquer momento, mesmo estando no Modo 3.
- **Investigação técnica adicional recomendada**: avaliar melhoria no algoritmo de detecção de fim de fala para diferenciar melhor ruído de fundo constante (motor de ônibus, etc.) de fala ativa do usuário, não apenas reduzir o teto de tempo como única correção.

## 2. Casos de teste — Qualidade de tradução

### 2.1 Traduções corretas (baseline de sucesso, para comparação futura)

| # | Pergunta (PT) | Resposta do LINGO (EN) | Avaliação |
|---|---|---|---|
| 1 | "O ônibus está cheio" | "The bus is full" | Correto e natural |
| 2 | "depois do trabalho eu vou para casa de ônibus" | "After work I go home by bus" | Correto e natural |
| 3 | "O ônibus está lotado" | "The bus is crowded" | Correto e natural |
| 4 | "Marcelo é um bom companheiro" (ambiente silencioso) | "Marcelo is a good companion" | Correto ("companion" é levemente mais formal que "friend", mas válido) |
| 5 | "agora estou indo para casa depois de um dia cansativo de trabalho" | "Now I'm going home after a tiring day of work" | Correto e natural |
| 6 | "Tenha uma excelente noite" | "Have a great night" | Correto e natural |

**Observação sobre o baseline**: frases mais diretas, com estrutura gramatical próxima entre português e inglês, traduzem corretamente mesmo com o motor de tradução automático atual. O padrão de falha (seção 2.2) concentra-se em frases com maior distância estrutural ou dependência de contexto.

### 2.2 Erros e imprecisões confirmados

| # | Pergunta (PT) | Resposta do LINGO (EN) | Problema | Severidade |
|---|---|---|---|---|
| 1 | "eu fui à feira comprar carne e frango" | "...to the **fair**..." | "Feira" (mercado) traduzido como "fair" (feira-evento/parque), quando o correto é **"market"** | Erro de sentido |
| 2 | "hoje eu vou jantar sopa" | "Today I'm going to have **dinner soup**" | Estrutura mal formada — soa como um tipo de sopa chamado "dinner soup". Correto: **"I'm having soup for dinner"** | Erro de sentido |
| 3 | "cheguei em casa" | "I arrived **at** home" | Preposição desnecessária — nativo diria **"I arrived home"** ou **"I got home"**. Compreensível, mas não natural | Imprecisão (menor) |
| 4 | "**como eu diria** está chovendo muito e eu estou no ônibus lotado" | "**As I would say** it's raining a lot..." | A moldura da pergunta ("como eu diria") vazou para dentro da tradução, sendo tratada como parte do conteúdo a traduzir, em vez de ser reconhecida como instrução sobre a pergunta (igual a "como se diz") | Bug estrutural |
| 5 | "o passageiro **deu sinal** no ônibus" | "The passenger **signed** on the bus" | Erro grave de sentido — "deu sinal" (sinalizou parada) virou "signed" (assinou). Correto: **"signaled"** ou, mais natural, **"rang the bell"** | Erro de sentido (mais severo) |

### 2.3 Diagnóstico consolidado de tradução

- Em **todos** os 11 casos, a **transcrição de voz** (o que o usuário disse em português) saiu correta — nenhum erro foi causado por falha de reconhecimento de fala, mesmo em ambiente ruidoso (ônibus com buzina/motor). Os erros são inteiramente do **motor de tradução**.
- Todos os prints confirmam o aviso "Tradução automática feita no seu aparelho — pode ter imprecisões", indicando que esta versão ainda usa o **tradutor automático local do dispositivo**, não a arquitetura de modelo de linguagem + RAG já especificada como alvo em MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md.
- O padrão de erro é consistente com a limitação esperada de tradutores automáticos locais: falham em (a) ambiguidade lexical dependente de contexto (fair/market), (b) expressões que exigem reestruturação gramatical entre os dois idiomas (jantar sopa → soup for dinner), (c) reconhecimento de moldura de instrução vs. conteúdo a traduzir ("como eu diria" vazando), e (d) verbos com múltiplos sentidos conforme uso idiomático ("dar sinal").
- **Recomendação**: os 5 casos de erro/imprecisão da seção 2.2, mais os 6 casos de sucesso da seção 2.1, devem ser usados como **conjunto de regressão** ao validar a migração do LINGO para a arquitetura de modelo de linguagem já especificada — confirmando que os 6 casos corretos continuam corretos, e que os 5 casos de erro passam a ser traduzidos corretamente.

## 3. Casos de teste — Captura de voz (três modos)

### 3.1 Modos confirmados em teste real, todos devem coexistir como opção do usuário

Rhoney confirmou explicitamente que os três modos abaixo devem coexistir, com o usuário escolhendo qual usar:

1. **Apertar e segurar** — já especificado em MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md, funciona por controle manual direto (captura enquanto pressionado, processa ao soltar).
2. **Toque único, dois toques (iniciar/finalizar manual)** — usuário toca para começar, toca novamente para sinalizar que terminou. **Testado com sucesso em ambiente ruidoso (ônibus)** — caso "Tenha uma excelente noite" (seção 2.1, item 6) — captura funcionou corretamente com esse modo mesmo em ônibus.
3. **Toque único, detecção automática de fim** — usuário toca para começar, e o app tenta detectar sozinho, pela fala, quando a pergunta terminou, sem exigir um segundo toque.

### 3.2 Falha confirmada no Modo 3 (detecção automática)

**Caso de teste**: "agora estou indo para casa depois de um dia cansativo de trabalho", realizado no ônibus, modo de toque único.

**Sintoma relatado por Rhoney**: tempo de escuta de **1 minuto e 20 segundos** para uma frase que, falada normalmente, dura poucos segundos. Observação direta de Rhoney: "o App estava buscando captar outros sons, mesmo quando eu terminei de fazer a pergunta."

**Diagnóstico**: o Modo 3 depende de identificar quando o usuário parou de falar através de análise de padrão sonoro (silêncio sustentado ou equivalente). Em ambiente com ruído de fundo constante (motor do ônibus, buzina, vozes de outros passageiros), o app aparentemente nunca identifica um "silêncio" claro o suficiente para concluir que o usuário terminou, mantendo a escuta ativa até algum teto de segurança distante (1:20 é claramente excessivo para uso normal).

**Contraste direto com o Modo 2**: no mesmo ambiente ruidoso (ônibus), o Modo 2 (dois toques manuais) funcionou perfeitamente (seção 2.1, item 6) — confirmando que o problema não é o ambiente em si, e sim especificamente a lógica de detecção automática do Modo 3, que não tem essa fragilidade quando a confirmação é manual.

## 4. Diretriz para o Modo 3 — não eliminar, mas proteger

Rhoney determinou que o Modo 3 deve continuar existindo como opção (não ser removido), mas precisa de correção antes de ir a produção:

- **Teto de tempo revisado e sensato**: o teto atual (que permitiu 1:20 de escuta) está claramente alto demais para uso normal — deve ser reduzido para um valor que ainda acomode perguntas longas legítimas (ver already estabelecido em MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md, faixa de 30+ segundos de fala real), sem permitir captura indefinida de ruído ambiente.
- **Indicador visual de "ainda ouvindo"**: o usuário precisa conseguir perceber, visualmente, que o app continua em modo de escuta além do esperado — permitindo que ele intervenha manualmente (ex.: tocando novamente) para forçar o encerramento, mesmo estando no modo automático.
- **Investigação técnica adicional recomendada**: avaliar se o algoritmo de detecção de fim de fala do Modo 3 pode ser aprimorado para diferenciar melhor "ruído de fundo constante" de "fala ativa do usuário" (ex.: técnicas de redução de ruído ou detecção de atividade de voz mais robusta a ruído constante e de baixa variação, diferente de silêncio real) — não apenas reduzir o teto de tempo como única correção.

## 5. Escopo técnico consolidado (a propor em detalhe por Claude Code)

- Migrar o motor de tradução do LINGO da tradução automática local do dispositivo para a arquitetura de modelo de linguagem + RAG já especificada em MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md, usando os 11 casos deste relatório (seções 2.1 e 2.2) como conjunto de teste de regressão obrigatório antes de considerar a migração concluída.
- Corrigir especificamente o bug de "vazamento de moldura de instrução" (seção 2.2, item 4) — garantir que frases introdutórias do tipo "como se diz", "como eu diria", "como eu digo" sejam sempre tratadas como instrução sobre a pergunta, nunca como conteúdo a traduzir, independentemente de variação de fraseado.
- Implementar os três modos de captura de voz (seção 3.1) como opções configuráveis pelo usuário, mantendo Apertar-e-segurar e Toque único (dois toques) como já especificados, e corrigindo o Modo 3 conforme a seção 4 deste documento antes de habilitá-lo em produção.
- Reportar a Rhoney o teto de tempo final escolhido para o Modo 3, com justificativa, antes de finalizar a implementação.

## 6. Critério de aceite

- Os 6 casos de tradução corretos (seção 2.1) permanecem corretos após a migração de motor de tradução.
- Os 5 casos de erro/imprecisão (seção 2.2) passam a ser traduzidos corretamente após a migração.
- Bug de vazamento de moldura de instrução ("como eu diria" etc.) eliminado, testado com múltiplas variações de fraseado introdutório.
- Modo 3 (detecção automática) testado especificamente em ambiente ruidoso (idealmente reproduzindo condição de ônibus/ruído de motor constante), confirmando que não mais se estende a durações excessivas como a observada (1:20).
- Indicador visual de "ainda ouvindo" implementado e funcional no Modo 3.
- Os três modos de captura coexistem e são selecionáveis pelo usuário.
