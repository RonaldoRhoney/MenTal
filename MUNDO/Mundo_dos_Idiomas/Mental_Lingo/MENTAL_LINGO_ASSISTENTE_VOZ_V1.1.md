# MENTAL LINGO — Assistente de Idiomas por Voz

**Especificação v1.1 — revisão de Claude sobre o rascunho original de Rhoney (v1.0, 23/09/2026), incorporando 6 pontos de contribuição técnica. Aguardando aprovação explícita de Rhoney antes de qualquer implementação, conforme o próprio Fluxo obrigatório deste documento.**

---

## Nota sobre a interface (print de referência)

Rhoney confirmou: a interface do MENTAL LINGO mostrada no print de referência (banner "Converse por voz com a IA", botão "Toque para falar", estados visuais) deve ser mantida **exatamente como está, ou melhorada** — nunca simplificada ou reduzida em relação ao que já foi mostrado. Qualquer ajuste de implementação deve preservar ou elevar esse padrão visual, nunca regredir.

## Visão

MENTAL LINGO é um assistente de conversação por voz dentro do Mundo dos Idiomas. O jogador toca no microfone, faz uma pergunta falada e recebe resposta contextualizada em texto e áudio.

## Jornada

1. Entrar no MENTAL LINGO e tocar no microfone.
2. Mostrar estado Ouvindo; permitir cancelar a captura.
3. Converter fala em texto e exibir transcrição quando útil.
4. Gerar resposta adequada ao nível do jogador.
5. Mostrar resposta escrita e permitir ouvir por TTS, repetir ou interromper.
6. Permitir nova pergunta; nunca manter escuta contínua em segundo plano.

## Casos de uso

- "Como se escreve borracha em inglês?"
- Tradução contextual, vocabulário, gramática e tempos verbais.
- Construção e correção explicada de frases.
- Explicações e exemplos adaptados ao nível.

## Base de conhecimento

- Organizar conteúdo aprovado do Mundo dos Idiomas em base pesquisável.
- Usar RAG ou mecanismo equivalente para recuperar contexto relevante.
- Não presumir que o modelo conhece ou memoriza o banco do app.
- Priorizar materiais aprovados; explicitar limites ou pedir esclarecimento quando necessário.

## Personalização

- Personalizar com contexto e perfil de aprendizagem controlado; não retreinar automaticamente a cada conversa.
- Guardar apenas sinais necessários e transparentes, como nível estimado e competências praticadas.
- Isolar dados por usuário e prever controles de histórico, personalização e exclusão.
- Não inferir atributos sensíveis nem apresentar estimativa como certificação formal.

## Arquitetura a avaliar

- Interface de voz e estados: Pronto, Ouvindo, Processando, Respondendo, Falha.
- **Tempo de escuta proporcional à fala do usuário, nunca um teto fixo determinado pelo app (ajuste de 25/09/2026, substitui o timeout curto da v1.1 original):** Rhoney determinou explicitamente que a escuta não deve ser cortada por um tempo pré-definido arbitrário pelo app — o tempo disponível para o usuário terminar sua pergunta deve caber, por exemplo, os 30 segundos que ele levar para perguntar, incluindo pausas naturais de respiração no meio da fala. Na prática, isso é implementado por **detecção de silêncio sustentado**, não por duração total cronometrada desde o início: o app continua no estado Ouvindo enquanto detecta fala (tolerando pausas curtas, como as de respiração), e só encerra a captura quando identifica um período de silêncio contínuo significativamente mais longo que uma pausa normal de fala — sinal de que o usuário de fato terminou. Não existe, portanto, um número fixo de segundos de escuta total; o que existe é um limiar de silêncio contínuo (a calibrar tecnicamente) que marca o fim da pergunta. Um teto de segurança de duração máxima **muito alto** (ex.: poucos minutos) pode ser mantido apenas como proteção técnica contra captura travada por bug (microfone preso ligado indefinidamente), nunca como um limite que interfira no uso normal de uma pergunta falada.
- Speech-to-Text com permissões e fallback.
- Backend autenticado para quotas, recuperação de contexto e chamada ao modelo.
- Camada de validação de conteúdo e segurança.
- Resposta em texto e TTS local para áudio.
- Perfil mínimo, consentimento/transparência e isolamento por usuário.

## Opções de Speech-to-Text a avaliar no diagnóstico (adição v1.1)

Mesma lógica de "avaliar opção gratuita de qualidade primeiro" já aplicada à escolha do `flutter_edge_tts` para o Mundo dos Idiomas:
- **Android SpeechRecognizer nativo**: gratuito, roda no próprio aparelho, já disponível por padrão no Android — deve ser a primeira opção avaliada antes de qualquer serviço pago de nuvem.
- Serviços de nuvem (ex.: Google Cloud Speech-to-Text) como alternativa apenas se a qualidade do reconhecimento nativo se mostrar insuficiente durante o piloto, com custo/cota explicitamente comparado ao ganho de qualidade.

## Escopo em relação a Libras (adição v1.1)

Libras não possui componente sonoro (língua visual-espacial, conforme já estabelecido em MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md). O diagnóstico técnico deve esclarecer explicitamente: o MENTAL LINGO atende apenas aos idiomas falados (Inglês, Espanhol, Francês), ou também responde perguntas sobre Libras de forma adaptada (ex.: resposta apenas em texto, sem tentativa de síntese de voz para conteúdo de sinais)? O banner do MENTAL LINGO aparece hoje no topo de toda a tela do Mundo dos Idiomas, incluindo a seção de Libras — essa decisão de escopo deve ficar clara antes da implementação.

## Custos e gratuidade

- TTS local pode evitar custo de síntese; reconhecimento de fala e geração por IA podem ter custos, limites ou cotas.
- Plano gratuito de fornecedor não garante uso ilimitado ou permanente.
- Começar com piloto, medir latência, qualidade, consumo e custo por sessão.
- **Teto de custo explícito antes do piloto (adição v1.1):** definir um valor-limite de custo aceitável por usuário ativo/mês para esta funcionalidade, antes de iniciar o piloto — sem esse número, a métrica de "custo por sessão" fica sem critério objetivo de decisão sobre expandir, limitar ou pausar a funcionalidade.
- Aplicar quotas e rate limits; prever fallback para rede/cota/provedor indisponível.
- Nunca embutir chaves privadas no APK; chamadas a modelos devem passar por backend seguro.
- Não prometer gratuidade ilimitada mundialmente sem estimativa de escala.

## Privacidade e segurança

- Solicitar microfone apenas durante ação explícita e explicar finalidade.
- Não armazenar áudio bruto por padrão; definir retenção mínima se indispensável.
- Informar envio a terceiros de áudio/transcrição e sua finalidade.
- Validar entradas/saídas, autenticar, limitar uso e impedir acesso a dados de outros usuários.
- Informar que a IA pode errar e permitir feedback sobre respostas inadequadas.

## Qualidade pedagógica

- Tom claro, acolhedor e ajustado ao nível.
- Quando útil, apresentar tradução, explicação breve e exemplo natural.
- Distinguir regras de variantes regionais e preferências estilísticas.
- Não constranger por erros; não conceder XP/ranking nesta fase.
- **Governança futura de XP (adição v1.1):** se uma fase futura decidir conceder XP/MentalCoins pelo uso do MENTAL LINGO, essa mudança deve ser formalizada como revisão da Regra Oficial de Gamificação (REGRA_OFICIAL_GAMIFICACAO_MENTAL.md), nunca implementada de forma silenciosa fora daquele documento de governança já estabelecido.

## Testes e aceite

- Captura manual, cancelamento, transcrição, resposta textual e áudio reproduzível/interrompível.
- Testar perguntas curtas, longas, ambíguas, ruído ambiente e idiomas suportados.
- Validar recuperação do conteúdo aprovado e qualidade pedagógica.
- Testar falhas de microfone, rede, modelo, TTS, quotas e fallback.
- Verificar segurança, privacidade, custos e ausência de chaves no APK.
- Confirmar ausência de alteração de XP, ranking e gameplay.
- **Teste de tempo de escuta proporcional (atualizado 25/09/2026):** confirmar que perguntas de diferentes durações (curtas e longas, ex.: até 30+ segundos) são capturadas por completo, incluindo pausas naturais de respiração no meio da fala, sem corte prematuro por parte do app. Confirmar também que o teto de segurança de duração máxima (proteção contra captura travada) é alto o suficiente para nunca interferir no uso normal.

## Fluxo obrigatório

1. Inspecionar app, backend, conteúdo, TTS e permissões.
2. Apresentar opções de STT (incluindo a comparação nativo-gratuito vs. nuvem-paga, ver seção específica acima), modelo, hospedagem, custos (incluindo teto de custo proposto), privacidade, riscos e arquivos afetados.
3. Esclarecer escopo de atendimento a Libras antes de prosseguir.
4. Aguardar aprovação explícita antes de implementar.
5. Após aprovação, construir piloto limitado/feature flag, testar e reportar métricas e limitações.

## Prompt Claude Code (atualizado v1.1)

Analise o Android MENTAL e avalie o MENTAL LINGO, assistente por voz no Mundo dos Idiomas. O jogador toca no microfone, fala, vê a transcrição e recebe resposta contextualizada em texto e áudio via TTS. Investigue recuperação do conteúdo aprovado; não presuma que o modelo conhece o banco. Compare opções de Speech-to-Text (priorizando avaliar o Android SpeechRecognizer nativo, gratuito, antes de qualquer opção paga de nuvem), modelo, backend, quotas, custos (propondo um teto de custo aceitável por usuário/mês antes do piloto), privacidade, personalização controlada e fallback. Esclareça o escopo de atendimento a Libras (apenas idiomas falados, ou também Libras em modo texto). O tempo de escuta deve ser proporcional à fala real do usuário, implementado por detecção de silêncio sustentado (tolerando pausas naturais de respiração), nunca por um timeout fixo curto — mantenha apenas um teto de segurança de duração máxima bem alto, só como proteção contra captura travada por bug. Não embuta chaves, não mantenha microfone ativo em segundo plano e não altere XP/ranking/gameplay — qualquer mudança futura de XP para esta funcionalidade deve passar pela governança formal da Regra Oficial de Gamificação. A interface deve seguir exatamente o padrão visual já validado (banner de destaque, botão "Toque para falar", estados visuais claros) ou superá-lo, nunca simplificá-lo. Primeiro entregue diagnóstico e proposta técnica; aguarde aprovação. Depois implemente piloto limitado, teste e reporte.

## Fora do escopo

- Escuta contínua em segundo plano.
- Retreinamento automático com áudio/conversas.
- Promessa de IA gratuita ilimitada.
- Recompensas por uso ou substituição do leitor manual.
