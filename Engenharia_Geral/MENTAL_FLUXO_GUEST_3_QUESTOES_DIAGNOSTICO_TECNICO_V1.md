# MENTAL — Diagnóstico Técnico: Fluxo Guest de 3 Questões Antes do Login

Escopo desta entrega: só a seção 3 de `MENTAL_ESPECIFICACAO_FLUXO_PROGRESSAO_MAPA_RANKING_FEEDBACK_V1.1.md` (fluxo de 3 questões antes do login, resultado parcial, XP provisório, migração pra conta). As demais seções do documento (4 a 9 — progressão sequencial, mapa, ranking, sons) continuam fora de escopo por decisão explícita de Rhoney em 07/10/2026.

## 1. Estado atual (INSPECIONAR, confirmado por leitura real do código)

- **Não existe modo guest hoje.** `client/lib/main.dart` (`_buildBody`, `_currentStageKey`) manda direto pra `LoginScreen` assim que termina o tutorial local — login é a primeira barreira antes de qualquer desafio, mais restritivo até do que a regra antiga (completar 1 desafio inteiro).
- `ApiClient` (`client/lib/api/api_client.dart`) exige `accessToken` no construtor — estruturalmente impossível hoje ter uma instância sem sessão Supabase.
- `GET /challenges/next` e `POST /challenges/{id}/answer` (`backend/app/routers/challenges.py`) dependem de `require_age_confirmed_user_id` — sempre autenticado e com idade confirmada. Não existe nenhum endpoint público de desafio hoje.
- Cadastro é 100% client-side via SDK Supabase (`login_screen.dart`, `auth.signUp`). Não há hook de "pós-cadastro" explícito — o ponto mais próximo é `services.get_or_create_profile`, chamado lazily na primeira requisição autenticada (ex.: dentro de `GET /challenges/next`).
- XP é calculado e aplicado só dentro de `POST /challenges/{id}/answer`, via `economy.apply_answer_xp`, que respeita um teto diário (`config.DAILY_ANSWER_XP_CAP`) e trava a linha do profile (`for_update=True`) contra condição de corrida. **Esse teto diário é o mecanismo central anti-fraude hoje** — qualquer XP provisório de guest precisa passar por esse mesmo fluxo na hora de virar XP real, nunca ser somado direto.
- Padrão já estabelecido no app pra estado local sem conta: `SharedPreferences` simples (`onboarding_tutorial_service.dart`, `theme_mode_service.dart`, `world_celebration_service.dart`) — sem camada de abstração extra.

## 2. Risco identificado que muda o desenho

O enunciado completo do desafio (pergunta, opções, e principalmente `correct_answer`) **não pode** ser decidido só no cliente — senão qualquer pessoa inspeciona o APK/tráfego e descobre a resposta certa antes de responder, sem precisar de conta. Mesmo em modo guest, a correção precisa continuar vindo do backend. Então "sem login" não pode significar "sem backend" — significa "sem exigir token de usuário autenticado" nesses 2 endpoints específicos.

## 3. Proposta de arquitetura

### 3.1 Backend — 2 endpoints novos, sem autenticação

- **`GET /guest/worlds`**: lista pública de Mundos (id, nome, ícone) + o id do primeiro território de cada um (ex.: `ingles_basico` pro Mundo dos Idiomas → bloco Inglês). Sem estado de usuário, sem progresso — só metadado estático dos Mundos, já existente em `TERRITORIES`/`WORLDS` no backend.
- **`GET /guest/challenges/next?territory_id=X`**: devolve um desafio do território pedido, **sem** `correct_answer` no payload (igual já faz `/challenges/next` hoje pra usuário comum). Restrito a territórios que são "primeira etapa" de algum Mundo (reaproveita a mesma lista de `is_territory_sequentially_reachable` pra validar que `territory_id` é mesmo um ponto de entrada válido — rejeita qualquer outro território, pra ninguém usar essa rota pra pular a trava sequencial em territórios avançados).
- **`POST /guest/challenges/{challenge_id}/answer`**: recebe a resposta, grava **nada** no banco (nenhuma linha de `Attempt`), só calcula e devolve `is_correct`, `correct_answer`, `explanation`, e um `xp_preview` (mesma fórmula de `scoring.xp_base_for`, só pra exibição, nunca persistido). Rate limit básico por IP pra evitar abuso (reaproveitar o que já existe de rate limit no projeto, se houver — a investigar na implementação).

### 3.2 Backend — 1 endpoint novo, autenticado, pra migração

- **`POST /guest/migrate-progress`**: autenticado (chamado automaticamente pelo cliente logo após o primeiro login bem-sucedido, antes de mostrar a Home). Recebe a lista das 3 respostas que o guest deu (`challenge_id`, `submitted_answer`, `response_time_ms`, `timed_out`) guardada localmente. O backend **reprocessa cada uma de verdade** pelo mesmo caminho interno que `POST /challenges/{id}/answer` usa hoje (valida a resposta nos dados reais do desafio, ignora qualquer `is_correct` que o cliente mande, cria os `Attempt`s de verdade, aplica XP através de `economy.apply_answer_xp` com o teto diário normal). Isso garante que o XP provisório vira real só quando passa pelo mesmo controle de todo mundo — fecha a brecha de alguém forjar XP provisório alto no cliente.
- Idempotência: se o perfil já tiver um `Attempt` pra algum desses `challenge_id` (ex.: usuário chamou a rota 2x por retry de rede), pula esse item sem duplicar.

### 3.3 Cliente — novo serviço de estado local

- `GuestChallengeService` (SharedPreferences, mesmo padrão de `OnboardingTutorialService`): guarda `territory_id` escolhido e a lista das respostas dadas (até 3), cada uma com `challenge_id`, `submitted_answer`, `response_time_ms`, `timed_out`, `is_correct` (só pra exibir ao usuário, nunca enviado como verdade pro backend na migração). Limpa depois que a migração é confirmada com sucesso.

### 3.4 Cliente — novas telas / fluxo

- Novo estágio em `main.dart`, inserido **antes** de `login`: se não há sessão e o guest ainda não completou as 3 questões, mostra um **seletor de Mundo** (reaproveita visual já existente da Home, só com Mundos — sem progresso, já que não há conta) → ao escolher, abre `ChallengeScreen` apontando pros endpoints `/guest/*` (a tela já aceita `client`/dados prefetched; precisa de um modo "guest" que troque a chamada de API).
- Botão sempre visível "Já tenho conta" pra pular direto pro login, sem forçar ninguém a passar pelas 3 perguntas.
- Depois da 3ª resposta: nova tela `PartialResultScreen` — acertos (X de 3), XP provisório (rotulado como provisório), **sem** ranking, CTA "Criar conta ou entrar" com texto explicando que o progresso é preservado.
- Depois do login bem-sucedido: se existir estado guest pendente no `GuestChallengeService`, chama `POST /guest/migrate-progress` automaticamente (tela de loading curta) antes de ir pra Home; limpa o estado local ao final.

## 4. Fora de escopo nesta entrega (confirmado por Rhoney)

- Seção 4 (progressão sequencial visível) — já implementada em outra frente, não mexe aqui.
- Seção 5/5.1 (mapa externo e progresso interno do Mundo), seção 6 (ranking), seção 7 (sons) — ficam pendentes, tratadas depois.
- Medição de funil (seção 3.4 do doc original) — fica pra uma iteração futura, não bloqueia esta entrega.
- Mecânicas que não são perguntas (Caça-palavras, Ouvido Afiado) tendo um "equivalente de 3 questões" (seção 3.3.4) — fora de escopo agora; o seletor de Mundo guest, nesta primeira entrega, oferece só territórios de desafio padrão (MCQ), não esses formatos especiais.

## 5. Perguntas pra Rhoney aprovar antes de eu implementar

1. **Confirma a arquitetura dos 3 endpoints novos** (`GET /guest/worlds`, `GET /guest/challenges/next`, `POST /guest/challenges/{id}/answer`, sem auth, sem persistência) e do endpoint de migração autenticado (`POST /guest/migrate-progress`, que reprocessa de verdade em vez de confiar no XP provisório do cliente)?
2. **Rate limiting dos endpoints guest**: tudo bem eu usar um limite simples por IP (ex.: X requisições/minuto) pra evitar abuso, mesmo sem ter hoje uma camada de rate limit genérica no projeto — ou prefere que eu primeiro verifique/implemente algo mais robusto antes?
3. **Territórios elegíveis pro guest**: só a primeira etapa (Desafio Básico) de cada Mundo, nunca Relâmpago nem etapas avançadas — confirma?
4. Se o usuário fechar o app no meio das 3 perguntas e reabrir depois (sem internet, sem terminar), o progresso guest local continua valendo de onde parou (via SharedPreferences) — tudo bem, sem prazo de expiração nesta primeira entrega?
