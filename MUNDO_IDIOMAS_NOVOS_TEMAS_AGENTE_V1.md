# MENTAL — Mundo dos Idiomas: Novos Desafios de Vocabulário Prático via Agente de Curadoria

**Status:** APROVADO. Lista de temas validada por Rhoney (19/09/2026, ver seção 2) — próximo passo é formalizar o agente de curadoria (§6) e iniciar a produção de conteúdo em lotes revisáveis. Ainda não iniciado (fila após o piloto de ilustração via Canva em andamento). Primeiro caso de uso real do agente autônomo de curadoria de conteúdo (retomada do Motor B / Agente de Consistência de Conteúdo, já discutido com Rhoney). A etapa de aprovação humana de Rhoney é obrigatória e não-negociável em qualquer fluxo derivado deste documento.

---

## 1. Objetivo

Ampliar o Mundo dos Idiomas com novos Desafios de **vocabulário prático do cotidiano** — palavras de uso comum em português que, tipicamente, não são ensinadas em cursos/materiais tradicionais de idioma (que costumam focar em cumprimentos, números, cores básicas), mas que aparecem constantemente na vida real. Exemplo dado por Rhoney: como se escreve "escorredor de macarrão" em inglês (colander/pasta strainer) — vocabulário útil, cotidiano, e frequentemente desconhecido mesmo por quem já tem algum domínio do idioma.

## 2. Temas — validados por Rhoney (19/09/2026)

Rhoney forneceu 5 temas iniciais: Cores, Casa, Cotidiano, Trabalho, Viagens. Claude propôs 10 temas adicionais e Rhoney aprovou a lista completa (sem ajustes) via AskUserQuestion — lista final de 15 temas pra curadoria: **Cores, Casa, Cotidiano, Trabalho, Viagens, Cozinha/Utensílios, Compras/Mercado, Corpo Humano, Roupas/Vestuário, Transporte, Tecnologia do dia a dia, Saúde/Farmácia, Clima/Estações, Emoções/Sentimentos, Escritório/Estudo.** Lista não é fechada — o agente pode propor temas adicionais no mesmo espírito em rodadas futuras.

## 3. Escopo — todos os idiomas do Mundo dos Idiomas

Esta expansão de conteúdo aplica-se a **todos os idiomas já existentes** no Mundo dos Idiomas (Inglês, Espanhol, Francês, e demais futuros), seguindo a mesma estrutura genérica por idioma já estabelecida nos demais documentos desta frente de trabalho.

## 4. Delegação explícita ao agente de curadoria — não é tarefa manual de Claude no chat

Diferente da curadoria de conteúdo já realizada manualmente por Claude para outros Mundos do MENTAL (Internet, Esportes), Rhoney determinou explicitamente que **esta expansão do Mundo dos Idiomas deve ser conduzida pelo agente autônomo de curadoria de conteúdo** (pesquisa, redação, verificação de fontes), e não por curadoria manual linha a linha no chat.

- Se o **Agente de Consistência de Conteúdo** (já mencionado em AUDITORIA_GLOBAL_CONTEUDO_V1.md como pendente de formalização) ainda não existir como agente formalizado e operante, esta tarefa deve ser tratada como **gatilho adicional** para sua formalização — de forma equivalente ao que já foi registrado naquele documento para a auditoria de conteúdo.
- O agente deve: (a) propor a lista de temas a cobrir (além dos 5 exemplos), (b) pesquisar vocabulário e traduções corretas em fontes confiáveis (dicionários, fontes linguísticas verificáveis), (c) redigir os Desafios completos (perguntas, alternativas, e integração com as mecânicas já formalizadas — Imersão Progressiva por nível, Constelação de Palavras ao final, Reconhecimento Visual no nível Média), (d) entregar o material para revisão humana antes de qualquer publicação.

## 5. Princípio inegociável — revisão humana sempre prevalece

Conforme já reafirmado por Rhoney em conversa anterior deste projeto: **a etapa de revisão humana é a essência do MENTAL e deve sempre prevalecer**, inclusive nesta automação. Isso significa, especificamente para este documento:
- O agente **propõe e elabora**, mas **nunca publica** Desafios diretamente em produção sem aprovação explícita de Rhoney.
- O material entregue pelo agente deve ser apresentado a Rhoney em lotes revisáveis (por tema, ou por idioma, a critério de organização do fluxo), não como uma publicação massiva de uma vez sem checkpoint de revisão.
- Rhoney pode aprovar, rejeitar ou solicitar ajuste de qualquer item proposto pelo agente, exatamente como acontece hoje com os documentos formalizados por Claude neste chat.

## 6. Escopo técnico (a propor em detalhe por Claude Code)

- Formalizar (se ainda não existir) o Agente de Consistência de Conteúdo / agente de curadoria, com escopo documentado de forma equivalente aos demais agentes já existentes no MENTAL (mental-security, mental-testing, MentalFeedAI, Agente de Saúde de Infraestrutura, Agente de Moderação).
- Definir o fluxo técnico de fila de aprovação: como o material proposto pelo agente chega até Rhoney para revisão (ex.: relatório/lote gerado, interface de revisão, ou outro mecanismo a propor).
- Garantir que o agente, ao gerar os Desafios, já aplique as mecânicas e regras já formalizadas nesta frente de trabalho (TTS com áudio vinculado a elemento específico, Imersão Progressiva por nível de dificuldade, Constelação de Palavras como etapa complementar, Reconhecimento Visual via Canva no nível Média).
- Reportar a Rhoney a lista de temas propostos pelo agente antes de iniciar a produção de conteúdo em massa, para validação da lista antes do esforço de curadoria propriamente dito.

## 7. Critério de aceite

- Agente de curadoria formalizado e operante, com escopo documentado.
- Lista de temas (além dos 5 exemplos originais) proposta pelo agente e validada por Rhoney antes da produção de conteúdo.
- Desafios gerados pelo agente cobrem vocabulário prático coerente com o princípio desta expansão, em todos os idiomas do Mundo dos Idiomas.
- Nenhum Desafio publicado em produção sem passar por aprovação explícita de Rhoney.
- Desafios gerados já nascem compatíveis com as mecânicas já formalizadas (Imersão Progressiva, Constelação de Palavras, Reconhecimento Visual).
