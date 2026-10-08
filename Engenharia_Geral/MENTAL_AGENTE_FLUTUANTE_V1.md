# MENTAL — Agente Flutuante "Mental" (orientações em todo o app, exceto Mundo dos Idiomas)

**Status:** FORMALIZADO em 07/10/2026 a pedido de Rhoney ("formalize, caso tenha alguma dúvida me avise"), consolidando as conversas de 05 a 07/10/2026. Cada decisão abaixo está marcada como **Decidido** (dita por Rhoney), **Proposta** (sugerida por Claude e não contestada, a confirmar) ou **Em aberto** (precisa de resposta). Nada de implementação sem o fluxo obrigatório da seção 14.

---

## 1. Conceito

Um **único agente, o personagem "Mental"**, que flutua nas telas do app e, ao ser tocado, abre dicas, sugestões e orientações do contexto em que o usuário está. Ele é a própria personificação do app (ver MENTAL_PERSONAGEM_MASCOTE_V1.md, seção 1: o personagem se chama "Mental", nunca outro nome).

- **Decidido:** na Home **não existe card**. O próprio personagem flutuante ocupa esse lugar.
- **Decidido:** o Mental flutuante **substitui banners e cards anteriores** que cumpram a mesma função, para evitar conteúdo duplicado e deixar o app simples, elegante, dinâmico e visualmente profissional.
- **Decidido:** **sempre grátis, até Rhoney propor mudança.** Nenhum serviço pago nem modelo de linguagem por enquanto.

## 2. Onde aparece e onde não aparece

| Área | Mental flutuante | Observação |
|---|---|---|
| Home | Sim, como o personagem (sem card) | Decidido |
| Demais telas do app | Sim | Decidido |
| **Mundo dos Idiomas** | **Não** | **Decidido: nada muda ali.** A tela, o banner do MENTAL LINGO, o LINGO e os desafios continuam exatamente como hoje |
| Dentro de desafios e relâmpagos (fora dos Idiomas) | Discreto ou recolhido | Proposta: oculto durante a pergunta, visível entre telas (ver seção 6) |
| Sobre outros aplicativos | **Não** | Proposta: flutuante só dentro do MENTAL; sem permissão de sobreposição do Android |

## 3. Comportamento

- **Toque:** abre um painel de orientações do contexto (Decidido).
- **Home:** o personagem vivo e animado, que pode mostrar um balão curto de orientação, no máximo uma vez por sessão (Proposta).
- **Primeira abertura:** saudação curta para o usuário descobrir que o personagem é tocável (Decidido: "4 ok").
- **Posição:** arrastável, sem cobrir botões de ação nem alternativas (Proposta).
- **Desligar:** quem desligar o Mental o vê **apagado em todas as telas** onde ele aparece, e **dois toques o religam em qualquer tela** (Decidido).
- **Como desligar a primeira vez:** **Em aberto** (ver seção 12).
- **Acessibilidade:** o estado apagado precisa de descrição falada ("Mental desativado, toque duas vezes para ativar") e de uma dica discreta ao desligar sobre como religar (Proposta).

## 4. Conteúdo das orientações

- **Categorias** (Proposta): por onde começar, continuar de onde parou, como funciona cada modo (Desafio, Relâmpago, Batalha), sequência diária, mapa de trajetória, recompensas e MentalCoins, e novidades de conteúdo.
- **Origem do conteúdo** (Decidido: sempre grátis): **textos escritos e regras** que leem o progresso do usuário (sequência, último Mundo jogado, próxima etapa desbloqueada). Sem IA generativa e sem API paga.
- **Sem sistema paralelo:** as novidades e avisos já existem na Central de Notificações (CENTRAL_DE_NOTIFICACOES_HOME_V1.md e NOTIFICACAO_CONTEUDO_ATUALIZADO_V1.md). O Mental pode mostrar a mesma informação, mas não cria uma segunda fila (Proposta).
- **Tom:** positivo, sem humilhar, na voz do "Mental" em primeira pessoa; mesmo princípio de erro suave do resto do app.
- **Revisão humana:** os textos das orientações são aprovados por Rhoney em lote antes de irem ao ar.
- **Recompensas:** o Mental não gera XP nem MentalCoins. Qualquer recompensa futura exige revisão formal da Regra Oficial (REGRA_OFICIAL_GAMIFICACAO_MENTAL.md).

## 5. Substituição de banners e cards

- Claude Code **lista todos os banners e cards** que o Mental flutuante substituiria nas telas fora do Mundo dos Idiomas, com a função de cada um.
- **Nada é removido sem a aprovação explícita de Rhoney**, item por item (Proposta, não contestada).
- **Mundo dos Idiomas fica fora dessa lista** (Decidido).

## 6. Regras de não-interferência

- **Dentro de um desafio ou relâmpago, o Mental nunca dá dica da resposta.** Já existe o "Pedir uma dica", com penalidade de XP; o Mental só orienta sobre o app (Proposta).
- Não cobrir o botão de confirmar resposta, as alternativas, o cronômetro do Relâmpago nem a barra de navegação.
- Não abrir sozinho: no máximo um sinal discreto, para não virar notificação em excesso.
- Não interromper o usuário no meio de uma questão.

## 7. Relação com o MENTAL LINGO

- **Decidido:** o nome **LINGO continua** e a tela de conversa fica como está, **somente dentro do Mundo dos Idiomas**.
- **Decidido:** o atalho "Falar com o LINGO" a partir de outras telas **não entra** nesta fase (pode ser reavaliado depois, por decisão de Rhoney).

## 8. Visual e animação

- O personagem, suas expressões e a animação seguem MENTAL_PERSONAGEM_MASCOTE_V1.md. A arte final e a animação ainda não existem; este documento define o **comportamento**, que não depende da arte.
- **Em aberto:** usar um ícone provisório até o personagem ficar pronto (ver seção 12).
- Aparência sóbria, jovem-adulta, coerente com o público 18+ e sem estética infantil.
- Acabamento profissional, animação leve (sem pesar no desempenho nem na bateria) e redução de movimento respeitada.

## 9. Integração com outras especificações

- **Fluxo de primeiro acesso (3 questões antes do login):** **Em aberto** se o Mental aparece para quem ainda não tem conta (ver seção 12).
- **Mapa de Trajetória, progresso dentro do Mundo e progressão sequencial:** o Mental pode orientar sobre eles, sem alterar nada.
- **Mundo dos Idiomas e MENTAL LINGO:** nada muda.

## 10. Fora do escopo

- Qualquer alteração no Mundo dos Idiomas.
- Atalho "Falar com o LINGO" fora dos Idiomas.
- Conversa livre com modelo de linguagem (só se Rhoney propuser, mantendo "sempre grátis" ou nova decisão de custo).
- Personalidade adaptativa e aprendizado individual do personagem (Fase 2 do mascote, após monetização sustentável).
- Sobreposição sobre outros aplicativos.
- Recompensas novas, publicidade e monetização.

## 11. Escopo técnico (a propor em detalhe por Claude Code)

- Componente do personagem no nível raiz da navegação do app, com regra por rota para ligá-lo ou desligá-lo (fora do Mundo dos Idiomas).
- Painel de orientações contextuais alimentado por textos e regras locais.
- Estado persistido (ligado, desligado e posição), com os gestos de religar.
- Auditoria das telas e lista de banners e cards a substituir, com aprovação.
- Instrumentação simples e sem dados pessoais: toques, painéis abertos e desativações, para saber se ajuda ou incomoda.
- Revisão de desempenho em aparelhos modestos e de acessibilidade (TalkBack).

## 12. Dúvidas em aberto (respostas de Rhoney necessárias)

| # | Dúvida | Recomendação de Claude |
|---|---|---|
| 1 | Como o usuário **desliga** o Mental pela primeira vez? | Opção em Ajustes, mais um gesto (por exemplo, pressionar e segurar o personagem) |
| 2 | Até a arte final existir, usar um **ícone provisório** com o mesmo comportamento? | Sim, e trocar depois sem refazer a lógica |
| 3 | Dentro de **desafios e relâmpagos** (fora dos Idiomas), o Mental fica visível ou oculto? | Oculto durante a pergunta e visível nas telas de entrada e resultado |
| 4 | No **primeiro acesso** (3 questões sem conta), o Mental aparece? | Só na Home, com saudação; não dentro das 3 questões |
| 5 | "Mundo dos Idiomas" inclui **os desafios e relâmpagos dentro dele**, todos sem o Mental? | Sim, tudo da seção Idiomas intacto |
| 6 | Alguma tela fora dos Idiomas em que o Mental **não deva** aparecer (login, configurações sensíveis)? | Ocultar em login/cadastro e telas de erro |

## 13. Critérios de aceite

- O Mental flutuante aparece nas telas definidas e **não aparece em nenhuma tela do Mundo dos Idiomas**, que permanece idêntica a hoje, com o banner do LINGO.
- Na Home, não há card: o personagem ocupa o lugar.
- Ao tocar, abre orientações relevantes ao contexto, geradas por textos e regras locais, sem custo.
- Nenhuma dica de resposta é dada dentro de desafios.
- Desligado, aparece apagado em todas as telas, e dois toques o religam em qualquer uma delas, inclusive com leitor de tela.
- Nenhum banner ou card é removido sem aprovação item por item.
- Nenhuma sobreposição sobre outros apps e nenhum dado pessoal coletado pelo agente.
- Nenhuma alteração de XP, ranking, progressão ou regras de jogo.

## 14. Fluxo obrigatório do Claude Code e prompt

INSPECIONAR → DIAGNOSTICAR → PROPOR → AGUARDAR APROVAÇÃO → IMPLEMENTAR → TESTAR → REGRESSÃO → REVISAR → REPORTAR.

**Prompt:** Analise o app MENTAL e proponha a implementação do agente flutuante "Mental" conforme MENTAL_AGENTE_FLUTUANTE_V1.md. Não toque no Mundo dos Idiomas. Liste as telas e os banners/cards que seriam substituídos, e proponha o componente, o painel de orientações por textos e regras (sempre grátis), o estado desligado/apagado com religação por dois toques e as respostas às dúvidas da seção 12, com recomendação. Não dê dica de resposta dentro de desafios, não crie sobreposição sobre outros apps e não altere XP, ranking ou progressão. Entregue diagnóstico e proposta, e aguarde aprovação antes de implementar.
