# MENTAL — Kickoff Oficial (v2, repositório novo)

Este documento substitui qualquer versão anterior do projeto. O repositório
anterior foi descartado — comece do zero seguindo exatamente este processo.

## 1. Estrutura de decisão do projeto

- **Rhoney** — dono do produto. Decide visão, prioridade e aprova tudo antes
  da implementação. Único ponto de contato direto com você (Claude Code).
- **Claude (arquitetura)** — revisa e aprova tecnicamente toda decisão de
  stack, banco, segurança e modelagem antes de virar instrução para você.
  Qualquer documento em `docs/` chega até você já revisado.
- **Você (Claude Code)** — implementa. Não toma decisão arquitetural sozinha:
  se encontrar ambiguidade, documenta e pergunta via Rhoney, não assume.
- ChatGPT não faz mais parte do fluxo de decisão deste projeto.

## 2. Stack — já decidida, não reabrir esta discussão sem ADR

- **Banco/Auth**: Supabase. Auth compartilhada com o projeto central de
  identidade da RhoneyInc ("Uma conta, todos os softwares"), mas **schema de
  dados de jogo (XP, progresso, tentativas, territórios) é próprio do MENTAL**,
  ligado ao usuário apenas via `user_id`. MENTAL não lê nem escreve em nenhum
  schema de outro produto RhoneyInc.
- **Backend de lógica de negócio**: FastAPI (Python), separado do Supabase.
  Supabase é banco + auth; toda regra de scoring, XP, progressão, dificuldade
  adaptativa e hint engine vive no FastAPI. O cliente Android **nunca** calcula
  score ou XP — apenas envia a resposta e exibe o que o backend retorna.
- **Cliente**: Flutter. Um único codebase para Android agora e Web depois
  (Web é complementar, prevista na arquitetura, não implementada no V1).
- **Deploy backend**: a definir entre Render/Railway free tier (Claude Code
  deve propor com justificativa de custo e limites antes de decidir).

## 3. Identidade de marca — importante para nomes de pacotes e estrutura

Ler e seguir integralmente `BRAND.md` (anexo). Resumo crítico:
- MENTAL é uma **marca-filha** da RhoneyInc: consumer entertainment
  gamificado, com identidade visual e posicionamento próprios — não é
  listado ou estilizado como os produtos B2B/utilitários da RhoneyInc
  (MenuFlex, VendeFlex etc).
- O nome é uma escolha deliberada de ressignificação semântica — nunca deve
  aparecer sozinho, sem o slogan oficial por perto, em nenhum primeiro
  contato com o usuário (splash, ícone, listing da loja, cards de
  compartilhamento).
- Slogan oficial: **"Mental é quem conquista com a mente."**
- Splash screen segue sequência obrigatória definida no `BRAND.md` (nome →
  slogan → transição direta, sem telas extras).
- Nome do pacote Android (`com.rhoneyinc.mental`, mas sem elementos visuais
  do design system B2B da RhoneyInc dentro do app).

## 4. Modelo de negócio — freemium com paywall de progressão

Ler e seguir integralmente `MONETIZATION.md` (anexo). Resumo crítico:
- MENTAL nasce gratuito e joga bem. Não é app pago desde o início.
- Territórios iniciais e limite diário de desafios são free; territórios
  avançados e desafios ilimitados exigem assinatura mensal (Google Play
  Billing — nenhum meio de pagamento externo).
- O backend é a única autoridade sobre o que está desbloqueado — o cliente
  Flutter nunca decide isso, mesma regra já aplicada a Score/XP.
- Parental gate obrigatório antes de qualquer fluxo de compra, por exigência
  de política do Google Play para apps de público misto.
- O modelo de dados (status de assinatura, mapeamento território↔plano) deve
  nascer pronto desde a Foundation, mesmo que a integração real com Google
  Play Billing entre em uma etapa posterior à do Vertical Slice 01.

## 5. Compliance obrigatória desde o V1

Ler e seguir integralmente `FAMILY_SAFETY.md` (anexo). Resumo crítico:
- Público misto (criança a idoso) → tela de idade neutra obrigatória no
  onboarding, antes de qualquer coleta de dado não essencial.
- "child_safe_mode" é uma flag de sessão que nasce no V1, mesmo sem anúncios
  ainda implementados — não é feature futura, é arquitetura de dados desde o
  primeiro commit.
- Nenhum identificador de publicidade (AAID, telefone) é transmitido antes da
  confirmação de que o usuário é adulto.

## 6. Compartilhamento social (growth loop)

O MENTAL deve permitir que o jogador compartilhe seu desempenho e o próprio
app nas redes sociais — isso é parte da estratégia de aquisição orgânica de
usuários (Free-First: crescimento sem mídia paga).

Dois fluxos distintos, não confundir:

1. **Compartilhar conquista/desempenho** — ao completar um território, subir
   de nível, ou bater streak relevante, o jogador pode gerar uma **imagem/card
   visual** (não apenas texto) com sua conquista, pronta para compartilhar.
   Isso é o que efetivamente viraliza em rede social.
2. **Compartilhar o app (convite)** — ação simples e sempre acessível (ex: no
   perfil) para convidar alguém a baixar o MENTAL.

Implementação técnica:
- Usar o **share sheet nativo do Android/Flutter** (`Share Intent` / plugin
  `share_plus` ou equivalente), que já abre WhatsApp, Instagram, Facebook,
  Twitter/X, LinkedIn — sem integrar SDK de cada rede separadamente. Mantém
  Free-First e evita aprovação de API de terceiros.
- Considerar **deep link de convite** com identificador de origem, para
  rastrear quem trouxe quem. Não implementar sistema de recompensa por
  indicação no V1 — apenas capturar o dado, para viabilizar isso em V2.
- Geração do card de conquista pode ser server-side (backend gera a imagem)
  ou client-side (Flutter renderiza e exporta) — Claude Code deve propor a
  abordagem mais simples e de menor custo de manutenção antes de implementar.
- Compartilhamento é sempre uma ação opcional e explícita do jogador. Nunca
  automático, nunca obrigatório para progredir.

## 7. Princípio de Clareza Imediata (UX)

Diretriz de design vinculante para toda tela do MENTAL, incluindo Web quando
existir:

> Toda tela deve comunicar sua função em menos de 2 segundos de olhar, sem
> depender de leitura de texto. Um elemento tem prioridade visual clara por
> vez (tamanho, cor, posição). Identidade visual forte não significa muitos
> elementos — significa poucos elementos muito bem executados (tipografia,
> cor, espaço).

Implicações práticas para o Claude Code:
- Não empilhar feature visual só porque "cabe na tela". Cada elemento
  adicionado precisa justificar sua presença contra este princípio.
- Preferir uma ação primária clara por tela (ex: "Novo desafio") em vez de
  múltiplos CTAs competindo.
- Simplicidade não é ausência de personalidade — a identidade visual do
  MENTAL (definida em `BRAND.md`, a produzir na Foundation) deve ser forte
  mesmo com poucos elementos na tela.
- Este princípio é critério de aceite de qualquer tela entregue — não é
  sugestão estética, é requisito de produto.

## 8. Regra de processo — não pular etapas

```
DISCOVERY → FOUNDATION → IMPLEMENTATION PLAN → INFRAESTRUTURA
→ VERTICAL SLICE 01 → TESTES → AUDITORIA → VALIDAÇÃO → PRÓXIMA ETAPA
```

Não implemente a V1 inteira de uma vez. Não avance de etapa sem apresentar
resultado e aguardar autorização de Rhoney.

## 9. Primeira tarefa

1. Inspecionar o repositório vazio, confirmar que não há resíduo do projeto
   anterior.
2. Criar a estrutura `docs/00_DISCOVERY/`, `docs/01_FOUNDATION/`,
   `docs/02_IMPLEMENTATION/`.
3. Produzir a documentação de Discovery com base neste kickoff, no
   `FAMILY_SAFETY.md`, `MONETIZATION.md` e `BRAND.md` anexos — cobrindo os
   mesmos temas do pacote original (VISION, PRODUCT_PRINCIPLES, CORE_LOOP,
   GAMEPLAY, TERRITORIES, GAMIFICATION, RANKING, HINT_ENGINE,
   ADAPTIVE_DIFFICULTY, etc). `BRAND.md` já está formalizado — não
   reescrever nome ou slogan, apenas expandir identidade visual (cores,
   tipografia, tom de voz) em cima dele.
4. Na Foundation, formalizar `ARCHITECTURE.md` com o diagrama:
   Auth central (Supabase) → MENTAL (banco próprio) isolado dos demais
   produtos RhoneyInc.
5. Formalizar `API_CONTRACT.md` com idempotência (cada tentativa de resposta
   carrega um `attempt_id` único gerado pelo cliente; o backend rejeita ou
   ignora duplicatas), com os endpoints de assinatura/monetização descritos
   em `MONETIZATION.md`, e com o suporte a deep link de convite descrito na
   Seção 6.
6. Formalizar `DATA_MODEL.md` já incluindo status de assinatura, mapeamento
   território↔plano (free/pago), e captura de origem de convite (deep link).
7. Apresentar riscos, decisões pendentes e a arquitetura proposta.
8. **Aguardar aprovação de Rhoney (com validação técnica de Claude) antes de
   escrever qualquer código de implementação.**

## 10. Escopo do Vertical Slice 01 (quando chegar a hora)

Apenas 4 tipos de desafio: palavras, números, lógica, conhecimentos gerais.
Fluxo completo: abrir app → autenticar → home → iniciar desafio → responder →
backend valida → calcula score/XP → registra tentativa → exibe resultado e
explicação → atualiza progresso → próximo desafio.

Não implementar ainda: IA, batalha em tempo real, Web, moeda virtual, chat,
disputa territorial, geração automática de conteúdo, integração real com
Google Play Billing, sistema de recompensa por indicação, funcionalidades de
V2/V3. O modelo de dados de assinatura e de origem de convite nasce pronto,
mas o paywall funcional e a recompensa por indicação podem ser etapas
dedicadas após o Vertical Slice 01. O compartilhamento de conquista (card
visual) pode entrar no V1 de forma simples — é parte do core loop de
crescimento, não uma feature avançada.

## 11. Princípio final

Não queremos construir um aplicativo grande rapidamente. Queremos construir o
MENTAL corretamente, uma camada de cada vez — e sem comprometer a segurança
de menores em nenhuma etapa.
