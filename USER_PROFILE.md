# MENTAL — Perfil do Usuário (campos obrigatórios vs opcionais)

**Status:** Aprovado. **Revisado em 26/08/2026** — ver nota abaixo.
**Documentos relacionados:** FAMILY_SAFETY.md, V2_KICKOFF.md (item 12 — Amigos), DESIGN_SYSTEM.md, MENTAL-DIR-001

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

Nickname/avatar continuam como identidade pública; nome real continua
nunca exibido publicamente (mesma regra da seção 3). Localização
(estado) continua opcional além do país/cidade agora obrigatórios.

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
| **Foto de perfil** | Avatares pré-definidos (ilustrados) para todos; **upload de foto real permitido apenas para usuário confirmado como 18+** no campo obrigatório de idade | Ver seção 3.1 para regras completas (visibilidade condicional e moderação). |
| **Nome real** | Campo interno, **nunca exibido publicamente** | Se existir, serve só para uso interno (ex.: contato/suporte) — nunca aparece em ranking, amigos, ou qualquer tela social. Nickname já cumpre o papel de identidade pública. Mesma lógica de proteção já usada no child_safe_mode. |
| **Localização** | Só **estado/país** — nunca cidade exata | Cidade exata combinada com "criança usa este app" é dado sensível com risco regulatório real (mesmo cuidado já aplicado no MeuPet com GPS/IP/manual). Estado/país entrega valor social/cultural (inclusive conecta com a ideia futura de Regionalismo Brasileiro do V3) sem risco de localização fina de menor. |

---

### 3.1 Upload de foto real — regra especial (atualização)

Diferente da decisão original (só avatar), foi aprovado permitir **upload de foto real de perfil**, sob três condições que precisam valer em conjunto:

1. **Elegibilidade:** somente usuários que se declararam **18 anos ou mais** no campo obrigatório de idade do perfil podem habilitar upload de foto real. Usuários em `child_safe_mode` (ou que não confirmaram 18+) nunca veem essa opção — para eles, permanece só avatar pré-definido.

2. **Visibilidade condicional (quem sobe ≠ quem vê):** a foto real de um adulto **só é exibida para outros usuários também confirmados como adultos**. Um usuário em `child_safe_mode` sempre vê o **avatar padrão** no lugar da foto real, mesmo ao visualizar o perfil de um amigo ou posição no ranking de alguém que tenha foto real cadastrada — a foto nunca chega a ser renderizada para essa audiência, em nenhuma tela (ranking, amigos, badges, disputa territorial, batalha assíncrona).

3. **Moderação obrigatória:** toda foto de perfil enviada passa pela mesma camada de moderação já definida para UGC em REGIONAL_UGC_CONCEPT_V3.md — revisão em 3 camadas (Rhoney + Claude + Mentora_AI), **fail-closed** (foto ambígua nunca fica visível até revisão concluída; enquanto isso, avatar padrão é exibido no lugar).

Esta regra é uma extensão da política de UGC já estabelecida — foto de perfil é tratada com o mesmo rigor de conteúdo enviado por usuário, não como um campo de perfil trivial.

---

- **Nickname:** sempre visível (ranking, amigos, badges) — respeitando já a regra de child_safe_mode (nickname gerado pelo sistema para perfis infantis, se aplicável).
- **Avatar:** visível onde o nickname aparece.
- **Nome real:** nunca visível publicamente, em nenhuma tela.
- **Localização (estado/país):** visível apenas se o usuário preencher e explicitamente permitir exibição — campo opcional dentro do opcional (preencher ≠ exibir automaticamente). Detalhe de UI a definir na implementação (ex.: toggle "mostrar meu estado no perfil").

---

## 5. Fora de escopo agora

- Bio/descrição de texto livre: não incluída nesta formalização — texto livre de usuário abre superfície de moderação (mesmo tipo de risco do UGC do V3). Se desejado no futuro, deve passar pelo mesmo processo de moderação em camadas já definido para UGC (Rhoney + Claude + Mentora_AI).
- Qualquer campo de contato direto (telefone, redes sociais, outros apps de mensagem): não incluído — foge do escopo de um perfil de jogo e abre risco desnecessário de contato externo não moderado, especialmente relevante em público misto com menores.
