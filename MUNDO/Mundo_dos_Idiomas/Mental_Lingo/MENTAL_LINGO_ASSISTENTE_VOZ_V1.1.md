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
- Priorizar materiais aprovados; explicitar limites ou pedir esclarecimento quando necessário.
- **Uso do conhecimento geral de idioma do modelo como complemento ao banco curado (adição 27/09/2026, substitui a restrição original "não presumir que o modelo conhece ou memoriza o banco"):** Rhoney identificou, em uso real, que perguntas envolvendo vocabulário fora do banco curado (ex.: "frase com água quente") ficavam sem resposta, mesmo sendo vocabulário simples que o próprio modelo já domina por treinamento geral de idioma. A restrição original visava impedir que o LINGO inventasse conteúdo específico do app que não existe (ex.: alegar que uma palavra está classificada num nível que não está) — não visava impedir o uso do conhecimento geral de inglês do próprio modelo. Novo comportamento: quando uma palavra/frase solicitada pelo usuário não está no banco curado do MENTAL, o LINGO deve responder usando seu **conhecimento geral de idioma** (treinamento próprio do modelo), deixando implícito ou explícito que essa resposta não veio do banco curado do app quando isso for relevante para a experiência.
- **Registro automático de lacunas de vocabulário (adição 27/09/2026):** toda vez que o LINGO responder usando conhecimento geral por não encontrar a palavra/frase no banco curado, essa ocorrência deve ser **registrada automaticamente** (palavra/frase solicitada, idioma, contexto da pergunta). Este registro alimenta a fila de sugestões para a próxima rodada de expansão do banco de vocabulário oficial (mesmo formato de lote e aprovação já usado em MUNDO_IDIOMAS_BANCO_VOCABULARIO_1000_V1.md e frentes correlatas) — nunca é incorporado automaticamente ao banco oficial sem essa aprovação em lote, preservando o princípio de revisão humana obrigatória.
- **Link de referência opcional (adição 27/09/2026):** quando o LINGO tiver menor grau de confiança sobre uma resposta fora do banco curado, pode oferecer, como complemento à resposta, um link para uma fonte de referência confiável (ex.: dicionário reconhecido) — nunca como substituto da resposta direta, e nunca como mecanismo de "aprendizagem automática" a partir do conteúdo daquele link (o LINGO não deve incorporar automaticamente ao seu conhecimento o que encontrar seguindo esse link).
- Não inventar conteúdo específico do app que não existe (ex.: afirmar que algo está classificado em determinado nível do MENTAL quando não está) — essa é a restrição que permanece do comportamento original.

## Personalização

- Personalizar com contexto e perfil de aprendizagem controlado; não retreinar automaticamente a cada conversa.
- Guardar apenas sinais necessários e transparentes, como nível estimado e competências praticadas.
- Isolar dados por usuário e prever controles de histórico, personalização e exclusão.
- Não inferir atributos sensíveis nem apresentar estimativa como certificação formal.

## Arquitetura a avaliar

- Interface de voz e estados: Pronto, Ouvindo, Processando, Respondendo, Falha.
- **Captura por apertar-e-segurar, substituindo a detecção de silêncio (ajuste de 27/09/2026 — correção de bug real relatado por Rhoney):** em testes reais, a abordagem anterior de detecção de silêncio sustentado causou um problema concreto: o app processava e respondia com base em apenas parte da pergunta, interpretando uma pausa natural no meio da fala do usuário (para respirar, pensar ou reformular) como se a pergunta tivesse terminado. Para eliminar esse gap por completo, a captura de voz passa a funcionar por **apertar e segurar o botão do microfone**: o app captura áudio continuamente enquanto o usuário mantém o botão pressionado, sem nenhuma tentativa de interpretar pausas como fim de fala. O processamento da pergunta só é iniciado quando o usuário **solta o botão**, momento em que a captura é considerada completa e fiel à duração real da pergunta, incluindo qualquer pausa ou hesitação no meio dela. Esta abordagem segue o mesmo padrão já validado e amplamente reconhecido de mensagens de voz (ex.: WhatsApp) e comunicação tipo walkie-talkie, dispensando qualquer explicação ao usuário sobre como usar.
- **Gesto de cancelamento:** deslizar o dedo para fora da área do botão antes de soltá-lo cancela a captura sem iniciar processamento — mesmo padrão já consolidado em apps de mensagem de voz, evitando processamento (e custo associado) de perguntas incompletas ou toques acidentais.
- **Alternativa de acessibilidade:** para usuários com dificuldade de manter pressão contínua no botão, prever um modo alternativo configurável de "tocar para iniciar / tocar novamente para parar", sem exigir pressão contínua — disponível como opção, não como comportamento padrão.
- Teto de segurança de duração máxima ainda pode existir (ex.: poucos minutos), apenas como proteção técnica contra o botão ficar preso pressionado por falha de software, nunca como um limite que interfira no uso normal.
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
- **Teste de captura por apertar-e-segurar (atualizado 27/09/2026, substitui o teste de escuta proporcional por silêncio):** confirmar que a captura dura exatamente o tempo em que o botão é mantido pressionado, incluindo perguntas longas com pausas naturais no meio (30+ segundos), sem processamento prematuro de pergunta incompleta. Testar o gesto de cancelamento (deslizar para fora antes de soltar) e confirmar que nenhum processamento ocorre nesse caso. Testar o modo alternativo de acessibilidade (tocar para iniciar/parar).

- **Teste de fallback para conhecimento geral (adição 27/09/2026):** confirmar que perguntas com vocabulário fora do banco curado (ex.: "frase com água quente") recebem resposta via conhecimento geral do modelo, que essa ocorrência é registrada corretamente na fila de sugestões de expansão do banco, e que nenhum conteúdo é incorporado ao banco oficial sem passar pela aprovação em lote já estabelecida.

## Fluxo obrigatório

1. Inspecionar app, backend, conteúdo, TTS e permissões.
2. Apresentar opções de STT (incluindo a comparação nativo-gratuito vs. nuvem-paga, ver seção específica acima), modelo, hospedagem, custos (incluindo teto de custo proposto), privacidade, riscos e arquivos afetados.
3. Esclarecer escopo de atendimento a Libras antes de prosseguir.
4. Aguardar aprovação explícita antes de implementar.
5. Após aprovação, construir piloto limitado/feature flag, testar e reportar métricas e limitações.

## Prompt Claude Code (atualizado v1.1)

Analise o Android MENTAL e avalie o MENTAL LINGO, assistente por voz no Mundo dos Idiomas. O jogador toca no microfone, fala, vê a transcrição e recebe resposta contextualizada em texto e áudio via TTS. Investigue recuperação do conteúdo aprovado; quando a palavra/frase solicitada não estiver no banco curado, o LINGO deve responder usando o conhecimento geral de idioma do próprio modelo (não deixar sem resposta), registrando automaticamente essa lacuna para uma fila de sugestões de expansão do banco oficial, sujeita à mesma aprovação em lote já usada nas demais frentes de conteúdo — nunca incorporando a palavra automaticamente sem essa aprovação. O LINGO não deve inventar conteúdo específico do app que não existe (ex.: classificação de nível dentro do MENTAL). Compare opções de Speech-to-Text (priorizando avaliar o Android SpeechRecognizer nativo, gratuito, antes de qualquer opção paga de nuvem), modelo, backend, quotas, custos (propondo um teto de custo aceitável por usuário/mês antes do piloto), privacidade, personalização controlada e fallback. Esclareça o escopo de atendimento a Libras (apenas idiomas falados, ou também Libras em modo texto). A captura de voz deve funcionar por apertar-e-segurar o botão do microfone (não por detecção automática de silêncio, que causou bug real de processamento prematuro de perguntas incompletas em teste): captura contínua enquanto pressionado, processamento só ao soltar, com gesto de deslizar-para-cancelar e um modo alternativo de acessibilidade (tocar para iniciar/parar) sem exigir pressão contínua. Mantenha apenas um teto de segurança de duração máxima bem alto, só como proteção contra botão travado por bug de software. Não embuta chaves, não mantenha microfone ativo em segundo plano e não altere XP/ranking/gameplay — qualquer mudança futura de XP para esta funcionalidade deve passar pela governança formal da Regra Oficial de Gamificação. A interface deve seguir exatamente o padrão visual já validado (banner de destaque, botão "Toque para falar", estados visuais claros) ou superá-lo, nunca simplificá-lo. Primeiro entregue diagnóstico e proposta técnica; aguarde aprovação. Depois implemente piloto limitado, teste e reporte.

## Fora do escopo

- Escuta contínua em segundo plano.
- Retreinamento automático com áudio/conversas.
- Promessa de IA gratuita ilimitada.
- Recompensas por uso ou substituição do leitor manual.

## Status de implementação (28/09/2026)

**Diagnóstico entregue e aprovado por Rhoney ("aprovado. Implemente").** Investigação
prévia confirmou que boa parte da arquitetura já existia e estava correta:

- **STT**: já era `speech_to_text` (SpeechRecognizer nativo do Android via pacote
  Flutter) — gratuito, on-device, áudio nunca sai do aparelho. Nenhuma mudança
  necessária, já era a opção recomendada pelo documento.
- **Fallback de conhecimento geral**: já existia, mas via **Wikcionário** (fonte
  aberta/gratuita, não um modelo de IA generativa) — usado no caminho de tradução
  direta de palavra única. O gap real estava no caminho de **frase-exemplo**
  ("frase com água quente" ficava sem resposta porque só buscava na tabela curada
  de 3000 exemplos, nunca caía no fallback). Corrigido: `_example_fallback` em
  `app/mental_lingo.py` agora tenta o significado via Wikcionário palavra a
  palavra quando não há frase curada — nunca inventa frase, só mostra o
  significado, com a lacuna registrada na mesma fila de sugestões já existente.
- **Libras**: já tinha resposta clara ("Lingo por voz ainda não cobre Libras").
  Decisão: o banner continua aparecendo no topo do Mundo dos Idiomas como um todo
  (é um elemento de página, não por bloco) — não bloqueado dentro da seção de
  Libras especificamente.

**Implementado nesta rodada:**

- **Captura por apertar-e-segurar**, substituindo a detecção de silêncio
  (`client/lib/services/mental_lingo_service.dart`, `client/lib/screens/
  mental_lingo_screen.dart`): `GestureDetector` com `onLongPressStart/
  MoveUpdate/End/Cancel`; soltar dentro do botão envia a pergunta, arrastar pra
  fora antes de soltar cancela (feedback visual: ícone e cor mudam pra indicar
  "solte fora pra cancelar"). Transcrição parcial exibida ao vivo durante a
  captura (`partialResults` habilitado só quando há callback de preview).
  Modo de acessibilidade "tocar pra começar/tocar pra parar" disponível via
  botão de alternância, persistido em `SharedPreferences`.
- Teto de segurança de 3 minutos mantido (`_kSafetyCap`), só como proteção
  contra o reconhecedor travado por bug — nunca interfere no uso normal.

**Ainda não implementado nesta rodada** (fora do escopo do pedido de 28/09/2026,
não bloqueante): personalização controlada, quotas/rate limits formais, teto de
custo explícito por usuário/mês (hoje o custo é zero, então a métrica não é
urgente), feedback estruturado sobre respostas inadequadas além do voto
já existente em sugestões do Wikcionário.
