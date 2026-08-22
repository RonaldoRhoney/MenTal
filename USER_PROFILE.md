# MENTAL — Perfil do Usuário (campos obrigatórios vs opcionais)

**Status:** Aprovado.
**Documentos relacionados:** FAMILY_SAFETY.md, V2_KICKOFF.md (item 12 — Amigos), DESIGN_SYSTEM.md

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
| **Foto de perfil** | Avatares pré-definidos (ilustrados), **não upload de foto real** | Upload de foto real em app de público misto (criança + adulto) é risco de moderação e de identificação de menor — mesmo motivo que já levou à decisão de bloquear UGC de imagem no V3 (REGIONAL_UGC_CONCEPT_V3.md). Avatar resolve personalização sem abrir essa porta. |
| **Nome real** | Campo interno, **nunca exibido publicamente** | Se existir, serve só para uso interno (ex.: contato/suporte) — nunca aparece em ranking, amigos, ou qualquer tela social. Nickname já cumpre o papel de identidade pública. Mesma lógica de proteção já usada no child_safe_mode. |
| **Localização** | Só **estado/país** — nunca cidade exata | Cidade exata combinada com "criança usa este app" é dado sensível com risco regulatório real (mesmo cuidado já aplicado no MeuPet com GPS/IP/manual). Estado/país entrega valor social/cultural (inclusive conecta com a ideia futura de Regionalismo Brasileiro do V3) sem risco de localização fina de menor. |

---

## 4. Regras de exibição pública

- **Nickname:** sempre visível (ranking, amigos, badges) — respeitando já a regra de child_safe_mode (nickname gerado pelo sistema para perfis infantis, se aplicável).
- **Avatar:** visível onde o nickname aparece.
- **Nome real:** nunca visível publicamente, em nenhuma tela.
- **Localização (estado/país):** visível apenas se o usuário preencher e explicitamente permitir exibição — campo opcional dentro do opcional (preencher ≠ exibir automaticamente). Detalhe de UI a definir na implementação (ex.: toggle "mostrar meu estado no perfil").

---

## 5. Fora de escopo agora

- Bio/descrição de texto livre: não incluída nesta formalização — texto livre de usuário abre superfície de moderação (mesmo tipo de risco do UGC do V3). Se desejado no futuro, deve passar pelo mesmo processo de moderação em camadas já definido para UGC (Rhoney + Claude + Mentora_AI).
- Qualquer campo de contato direto (telefone, redes sociais, outros apps de mensagem): não incluído — foge do escopo de um perfil de jogo e abre risco desnecessário de contato externo não moderado, especialmente relevante em público misto com menores.
