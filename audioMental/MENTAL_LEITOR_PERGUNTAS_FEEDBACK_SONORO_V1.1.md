# MENTAL — Leitor de Perguntas e Feedback Sonoro

**Especificação v1.1 — revisão de Claude sobre o rascunho original de Rhoney (v1.0, 23/09/2026), incorporando pontos de contribuição técnica. Escopo esclarecido por Rhoney em 23/09/2026. Aguardando aprovação explícita de Rhoney, conforme o próprio Fluxo obrigatório deste documento.**

---

## Escopo — todos os Mundos, exceto o Mundo dos Idiomas

Este documento cobre a leitura de perguntas em **todos os Mundos do MENTAL, com exceção do Mundo dos Idiomas**, que já possui sua própria implementação de áudio, formalizada separadamente em MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md (motor `flutter_edge_tts`, online, com qualidade de voz elevada, justificada pela criticidade de pronúncia correta no aprendizado de idiomas).

Com esse escopo, "reutilizar a implementação, estados, controles e preferências de Idiomas" refere-se apenas ao **padrão de UI/UX já validado** (botão de reprodução, os três controles de velocidade Normal/Rápido/Acelerado, estados visuais de reprodução) — não ao motor de TTS em si, que é legitimamente diferente aqui (nativo/local do Android), já que este leitor atende a um contexto de uso diferente (leitura de enunciados em geral, não aprendizado fino de pronúncia de idioma).

## Objetivo

Expandir a todos os Mundos, exceto Idiomas, um leitor manual de perguntas, reaproveitando o padrão de UI/UX já validado em Idiomas, narrando somente o enunciado, com o motor de TTS nativo/local do Android — e adicionar sinais sonoros de acerto e erro.

## Requisitos funcionais

- Leitura exclusivamente manual, iniciada pelo jogador; sem autoplay.
- Narrar apenas o enunciado, nunca alternativas, respostas ou explicações nesta fase.
- Reutilizar o padrão de UI/UX (estados, controles, preferências) já validado em Idiomas — o motor de TTS é o nativo/local do Android, próprio deste leitor.
- Disponibilizar Normal, Rápido e Acelerado, usando os valores já adotados no app.
- Permitir parar e, se suportado atualmente, pausar/retomar.
- Não solicitar microfone; usar TTS nativo/local do Android.
- Não alterar XP, pontos, ranking, nível, dificuldade, recompensas ou regras do jogo.
- **Cobertura explícita de Desafios e Relâmpagos (adição v1.1):** o documento original menciona "demais mundos" de forma genérica — esclarecer que esta expansão cobre tanto o modo Desafio quanto o modo Relâmpago em cada Mundo, não apenas um dos dois, para evitar ambiguidade de escopo durante a implementação.

## Vozes

- Selecionar automaticamente voz compatível com o idioma do enunciado e priorizar compreensão.
- Alternar entre vozes masculinas e femininas somente quando disponíveis e adequadas.
- O jogador não escolhe voz ou gênero.
- Se não houver duas vozes adequadas, usar a melhor disponível; não comprometer inteligibilidade pela alternância.

## Feedback sonoro

- Acerto: confirmação breve, positiva, tipo OK.
- Erro: sinal breve, suave e neutro, sem punição ou constrangimento.
- Evitar sons sobrepostos à fala, duplicados ou excessivamente altos.
- Fornecer equivalente visual; áudio não pode ser o único sinal.
- Usar áudio original ou licenciado para distribuição e uso comercial global.
- **Fonte sugerida para os efeitos sonoros (adição v1.1):** seguindo o mesmo princípio já aplicado ao Ouvido Afiado (licença verificada individualmente por item, ex.: CC0/CC BY/CC BY-SA/domínio público via Wikimedia Commons), avaliar bancos de efeitos sonoros gratuitos com licença clara para uso comercial (ex.: Freesound.org filtrando por licença CC0, ou bibliotecas de SFX royalty-free já auditadas) como ponto de partida, em vez de produzir do zero sem necessidade.
- **Respeitar configurações de volume/silêncio do sistema (adição v1.1):** os sons de acerto/erro devem respeitar o volume de mídia e o modo silencioso/não perturbe do próprio aparelho — não devem tocar em volume forçado ou ignorar quando o usuário colocou o telefone em silêncio. Este ponto deve ser incluído explicitamente na fase de testes.

## Implementação e resiliência

- Inspecionar o serviço TTS atual, lifecycle, preferências, locales, erros e testes.
- Mapear telas de perguntas por mundo (exceto Idiomas) e identificar componentes compartilháveis.
- Enviar somente o campo do enunciado ao TTS.
- Tratar números, fórmulas, siglas, pontuação e termos estrangeiros.
- Falhas de áudio não podem bloquear resposta, avanço ou saída; funcionar offline conforme TTS instalado.

## Testes e aceite

- Validar manualidade, ausência de autoplay e leitura exclusiva do enunciado.
- Testar as três velocidades, persistência, alternância e fallback de voz.
- Testar textos longos, números, fórmulas, idiomas mistos e pontuação.
- Testar interrupções, navegação, foco de áudio, duplicação e ausência de rede.
- Confirmar feedback sonoro/visual e regressão do leitor em Idiomas (garantindo que esta expansão não interfere na implementação já existente lá).
- **Testar respeito ao volume/modo silencioso do sistema (adição v1.1).**
- **Confirmar cobertura tanto de Desafios quanto de Relâmpagos em pelo menos um Mundo de teste antes de generalizar (adição v1.1).**

## Fluxo de trabalho obrigatório

1. Fase 1: inspecionar repositório, leitor atual de Idiomas (para reaproveitar o padrão de UI/UX), telas dos demais Mundos e arquitetura.
2. Fase 2: apresentar diagnóstico, arquivos afetados, proposta e plano de testes.
3. Parar e aguardar aprovação explícita; não editar antes dela.
4. Após aprovação: implementar apenas o escopo autorizado, testar, revisar diff e reportar.

## Prompt Claude Code (atualizado v1.1)

Analise o Android MENTAL sem implementar imediatamente. Localize o leitor TTS de Idiomas (que usa `flutter_edge_tts`, motor online, específico daquele Mundo) e mapeie sua expansão, em termos de padrão de UI/UX (não de motor de TTS), a todos os demais Mundos do app — leitura manual somente do enunciado, com Normal/Rápido/Acelerado, cobrindo tanto Desafios quanto Relâmpagos, usando TTS nativo/local do Android (não o mesmo motor de Idiomas). Avalie seleção/alternância automática de vozes masculinas e femininas disponíveis e adequadas, com fallback, além de sons breves de acerto e suaves/neutros de erro, sem sobreposição, com feedback visual, respeitando o volume/modo silencioso do sistema, e com licença de áudio verificada para uso comercial (sugestão: Freesound.org com filtro de licença CC0). Não altere gameplay, XP, pontos ou ranking, e não modifique a implementação já existente em Idiomas. Entregue diagnóstico, arquivos afetados, proposta e testes; aguarde aprovação explícita. Só depois implemente, teste, faça regressão e reporte.

## Fora do escopo

- Mundo dos Idiomas (já possui implementação própria, tratada em documento separado).
- Leitura automática, alternativas, respostas e explicações.
- Assistente conversacional por voz.
- Alterações de gameplay ou progressão.
