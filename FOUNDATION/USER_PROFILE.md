# MENTAL — Perfil do Usuário (campos obrigatórios vs opcionais)

**Status:** Aprovado. **Revisado em 28/08/2026** — ver nota abaixo (mais recente primeiro).
**Documentos relacionados:** FAMILY_SAFETY.md, V2_KICKOFF.md (item 12 — Amigos), DESIGN_SYSTEM.md, MENTAL-DIR-001

---

## Revisão 28/08/2026 — cadastro mínimo obrigatório: foto entra, gênero sai; novas faixas etárias

Decisão de Rhoney: o cadastro mínimo obrigatório (fechado em 26/08/2026
como nome, país, cidade, gênero e faixa etária) muda de composição:

- **Foto de perfil passa a ser obrigatória** — antes era opcional
  (upload liberado desde a revisão de 27/08, mas nunca exigido pra
  completar o cadastro). Onboarding só marca `onboarding_completed_at`
  quando o usuário também já tiver feito upload de uma foto.
- **Gênero passa a ser OPCIONAL** — sai da lista de campos que bloqueiam
  a conclusão do onboarding, mas o campo em si continua existindo
  (quem quiser preencher, preenche; `PUT /profile` aceita normalmente).
- **Faixas etárias mudam de 5 para 4**: eram `18-25/26-30/31-45/46-50/
  51+`, passam a ser `18-25/26-35/36-45/46+`.

Cadastro mínimo obrigatório atual: **nome, país, cidade, faixa etária e
foto de perfil** (5 campos, nova composição). `MandatoryOnboardingScreen`
(client) e `routers/profile.py::update_profile` (backend, autoridade
final sobre `onboarding_completed_at`) foram atualizados juntos.

---

## Revisão 27/08/2026 — avatar removido; foto real + nome real agora públicos

Decisão de Rhoney: o sistema de **avatares emoji foi retirado** do app.
No lugar, todo usuário pode subir uma **foto de perfil real**, e o
**nome real passa a ser exibido publicamente** ao lado dela — em
Ranking, Amigos e Batalhas. Isso **reverte duas regras da seção 3**
abaixo (avatar como identidade pública padrão; nome real nunca
público), registradas quando o MENTAL ainda tinha público misto
incluindo menores. Com a MENTAL-DIR-001 (app exclusivo 18+), o
risco original que motivava as duas regras deixou de se aplicar: não
há mais `child_safe_mode` nem usuário não-adulto na base.

Continua valendo, sem alteração, o princípio de **moderação
fail-closed** da seção 3.1: toda foto nova nasce em estado `pending` e
só fica visível para outros usuários depois de aprovada. A diferença é
o **estágio de implementação atual**: hoje só existe a camada manual
(um admin aprova/rejeita via `/admin/profile-photos`) — as camadas
automatizadas "Claude" e "Mentora_AI" descritas originalmente na seção
3.1 **não estão implementadas**; ficam registradas aqui como parcela
pendente do processo de 3 camadas, não como algo já em produção.

A condição de elegibilidade "só 18+" da seção 3.1 também deixa de ser
um filtro ativo — todo usuário do app já é 18+ por força da própria
DIR-001, então não existe mais população "não-adulta" para diferenciar
visibilidade de foto.

---

## Revisão 26/08/2026 — cadastro mínimo obrigatório

Decisão de Rhoney: **nome, país, cidade, gênero e faixa etária** (18-25,
26-30, 31-45, 46-50, 51+) passam a ser **obrigatórios antes de jogar**,
coletados numa tela de onboarding única (uma vez por conta,
`onboarding_completed_at` no backend). Isso substitui, para esses 5
campos específicos, o princípio geral da seção 1 abaixo.

A restrição original de "nunca cidade exata" (seção 3) era motivada
pelo público misto (crianças incluídas) de antes da MENTAL-DIR-001 —
com o MENTAL agora exclusivo para maiores de 18 anos (sem
`child_safe_mode`), o risco de localização fina de menor que motivava
essa regra deixou de existir. Cidade passa a ser coletada normalmente.

Nickname/avatar continuavam, nesta data, como identidade pública; nome
real continuava nunca exibido publicamente (mesma regra da seção 3) —
**revertido em 27/08/2026, ver revisão mais recente no topo deste
documento.** Localização (estado) continua opcional além do
país/cidade agora obrigatórios.

---

## 1. Princípio geral

Obrigatório = só o que o sistema precisa pra funcionar (login, identificação básica, compliance).
Opcional = tudo que é personalização social — e dentro do opcional, evitar qualquer dado que, isolado ou combinado, possa identificar ou localizar uma criança de forma precisa (nome real, foto real, cidade exata).

Nenhum campo opcional pode bloquear ou degradar o uso do app se não for preenchido — mesmo espírito do resto do produto (Clarity Principle, não-humilhação).

---

## 2. Campos obrigatórios

| Campo | Motivo |
|---|---|
| **Nickname** | Identificação do jogador em ranking, amigos, badges — já em uso no sistema. |
| **E-mail** | Login/recuperação de conta via Supabase Auth — já parte do fluxo existente. |
| **Confirmação de idade (gate neutro)** | Exigência de compliance do Google Play Families Policy (já implementado em FAMILY_SAFETY.md) — não é campo social, é dado de compliance. |

---

## 3. Campos opcionais

| Campo | Formato recomendado | Justificativa |
|---|---|---|
| **Foto de perfil** | Upload de foto real (avatar emoji removido — Revisão 27/08/2026) | Ver seção 3.1 para regras completas (moderação obrigatória, fail-closed). |
| **Nome real** | Exibido publicamente ao lado da foto (Revisão 27/08/2026) | Aparece em ranking, amigos e batalhas junto com a foto de perfil. Nickname continua existindo, mas nome real deixou de ser interno-apenas. |
| **Localização** | Só **estado/país** — nunca cidade exata | Cidade exata combinada com "criança usa este app" é dado sensível com risco regulatório real (mesmo cuidado já aplicado no MeuPet com GPS/IP/manual). Estado/país entrega valor social/cultural (inclusive conecta com a ideia futura de Regionalismo Brasileiro do V3) sem risco de localização fina de menor. |

---

### 3.1 Upload de foto real — regra especial (atualização, revisada 27/08/2026)

Todo usuário (já 18+ por força da DIR-001) pode fazer **upload de foto
real de perfil**, sob duas condições que precisam valer em conjunto
(a condição original de "elegibilidade só 18+" caiu — ver Revisão
27/08/2026 no topo do documento, não existe mais população
não-adulta a diferenciar):

1. **Visibilidade pública:** a foto real, junto do nome real, aparece para **todos os outros usuários** em ranking, amigos e batalhas — não há mais diferenciação de audiência por faixa etária.

2. **Moderação obrigatória, fail-closed:** toda foto nova enviada nasce em estado `pending` e só fica visível para outros usuários depois de aprovada (`services.public_photo_url()` no backend — checagem centralizada, nunca duplicada por tela). Enquanto pendente ou rejeitada, nenhuma foto é exibida para terceiros (o próprio dono pode ver o preview da própria foto pendente, com indicação de status). **Estado atual da implementação:** só a camada manual existe (`/admin/profile-photos`, um humano com role=admin aprova/rejeita). As camadas automatizadas "Claude" e "Mentora_AI" descritas na concepção original de UGC (REGIONAL_UGC_CONCEPT_V3.md) **não foram implementadas** — pendência registrada, não lacuna silenciosa.

Esta regra é uma extensão da política de UGC já estabelecida — foto de perfil é tratada com o mesmo rigor de conteúdo enviado por usuário, não como um campo de perfil trivial.

---

- **Nickname:** sempre visível (ranking, amigos, badges).
- **Nome real:** visível publicamente ao lado da foto de perfil (Revisão 27/08/2026) — ranking, amigos, batalhas.
- **Foto de perfil:** visível publicamente somente após moderação aprovada (fail-closed, seção 3.1) — antes disso, o campo aparece vazio/nulo para terceiros.
- **Localização (estado/país):** visível apenas se o usuário preencher e explicitamente permitir exibição — campo opcional dentro do opcional (preencher ≠ exibir automaticamente). Detalhe de UI a definir na implementação (ex.: toggle "mostrar meu estado no perfil").

---

## 5. Fora de escopo agora

- Bio/descrição de texto livre: não incluída nesta formalização — texto livre de usuário abre superfície de moderação (mesmo tipo de risco do UGC do V3). Se desejado no futuro, deve passar pelo mesmo processo de moderação em camadas já definido para UGC (Rhoney + Claude + Mentora_AI).
- Qualquer campo de contato direto (telefone, redes sociais, outros apps de mensagem): não incluído — foge do escopo de um perfil de jogo e abre risco desnecessário de contato externo não moderado, especialmente relevante em público misto com menores.
