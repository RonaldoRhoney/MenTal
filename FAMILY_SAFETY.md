# MENTAL — Family Safety & Google Play Compliance

Status: aprovado por Rhoney (dono) e revisado tecnicamente por Claude (arquitetura).
Este documento é vinculante para toda a implementação. Nenhuma decisão aqui pode
ser contornada silenciosamente pelo Claude Code — qualquer exceção precisa de ADR.

## 1. Classificação do público

MENTAL é um app de **público misto** (mixed audience): projetado para funcionar
bem para crianças, adolescentes, adultos e idosos, com dificuldade e conteúdo
adaptados ao jogador. Não é um app "Designed for Families" (infantil puro), mas
também não pode assumir que todo usuário é adulto.

Isso ativa a **Google Play Families Policy** para a parcela de usuários que são
ou podem ser crianças, mesmo o app não sendo infantil-exclusivo.

## 2. Regra de ouro

> Até que a idade do usuário seja confirmada, o app deve tratá-lo como se fosse
> uma criança. Nenhum dado sensível trafega, nenhum anúncio personalizado é
> solicitado, nenhum identificador de publicidade é transmitido.

Isso vale mesmo que o V1 não tenha anúncios — a arquitetura de idade nasce agora
para não virar retrabalho estrutural quando a monetização for implementada.

## 3. Tela de idade neutra (obrigatória desde o V1)

- Deve aparecer no onboarding, antes de qualquer coleta de dado além do
  estritamente necessário para autenticação.
- Não pode ser estilizada como parte "divertida" do jogo, nem incentivar a
  criança a inserir uma idade falsa.
- Linguagem neutra, sem gamificação, sem emoji, sem personagem falando.
- Resultado da resposta define o "modo de dados" da sessão (ver seção 4).

### 3.1 Ordem dos métodos de login e público infantil

Decisão de Rhoney (2026-08-20): a ordem de apresentação dos métodos de
login no onboarding é **1) Google, 2) email/senha, 3) Facebook**.

Ressalva registrada na mesma decisão, não bloqueante mas vinculante para
o design da tela: criança tipicamente não tem conta Google própria sem
supervisão via Family Link, o que pode deixar o método #1 inacessível
justamente para parte do público-alvo do MENTAL (`FAMILY_SAFETY.md` §1).
Implicação prática para a tela de login (Foundation de UX, a formalizar
antes do onboarding ser implementado):

- A ordem de exibição (Google primeiro) não pode significar fricção
  extra para quem não tem conta Google — o caminho para email/senha
  precisa ser igualmente visível e rápido, não enterrado como alternativa
  secundária na prática.
- Login social (Google, Facebook) só deve solicitar o escopo mínimo de
  dado necessário (idealmente só identificador + email) — nunca perfil
  estendido, lista de contatos, ou dado adicional não essencial, reforça
  a regra de ouro da Seção 2.
- Cada provedor OAuth usado pelo MENTAL precisa de credencial (Client ID)
  **própria do MENTAL**, nunca reaproveitada de outro produto RhoneyInc —
  decisão registrada em `docs/02_IMPLEMENTATION/SUPABASE_SETUP.md` após
  identificar acoplamento acidental com o Client ID Google do MeuPet.

## 4. Regras de dados por faixa

| Situação | Advertising ID | Nº de telefone | Anúncio personalizado |
|---|---|---|---|
| Idade desconhecida | Bloqueado | Bloqueado | Bloqueado |
| Confirmado criança | Bloqueado | Bloqueado | Bloqueado |
| Confirmado adulto | Permitido | Permitido | Permitido |

- `AAID` (Android Advertising ID) nunca é transmitido no startup do app.
  Só é liberado depois de confirmar que o usuário é adulto.
- Nenhuma chamada a `TelephonyManager` para obter número de telefone de
  usuário não confirmado como adulto.
- Qualquer SDK de terceiros (analytics, crash reporting, ads) só pode ser
  inicializado em modo "child-directed" até a confirmação de idade.

## 5. Publicidade (para quando for implementada — não está no V1)

- Somente SDKs **auto-certificados no Google Play Families Ads Program**.
- Configurar `tagForChildDirectedTreatment` corretamente por sessão.
- Nunca anúncio de terceiro não certificado em sessão de idade desconhecida
  ou confirmada como criança.
- Isso será formalizado em `MONETIZATION.md` quando a monetização entrar em
  escopo — mas o *hook* técnico (flag de sessão "child_safe_mode") nasce no V1.

## 6. Target Audience no Google Play Console

- Só declarar múltiplas faixas etárias (crianças + adultos) porque o app é
  *de fato* desenhado para isso — dificuldade adaptativa e conteúdo apropriado
  por idade não são "nice to have", são requisito de submissão honesta.
- Questionário de content rating deve refletir com precisão: sem violência,
  sem conteúdo sexual, sem linguagem imprópria, dados coletados descritos com
  exatidão.

## 7. Privacy Policy

- Não pode ser boilerplate genérico. Deve descrever com precisão:
  - Quais dados são coletados (email, progresso de jogo, XP, tentativas).
  - Que não há coleta de identificadores de publicidade para menores.
  - Retenção e exclusão de dados (LGPD — ver `LGPD.md`).
  - Contato do responsável (Rhoney / RhoneyInc).

## 8. Checklist obrigatório antes de qualquer build de release

- [ ] Tela de idade neutra implementada e testada.
- [ ] Nenhuma transmissão de AAID/telefone antes da confirmação de idade.
- [ ] Nenhum SDK de terceiro inicializado fora do modo child-safe por padrão.
- [ ] Privacy Policy publicada e linkada no app e no Play Console.
- [ ] Content rating questionnaire preenchido com precisão.
- [ ] Target audience declarado de forma honesta (não “todas as idades” por
      padrão sem justificativa de design).

## 9. Papel de cada parte

- **Rhoney**: aprova a Privacy Policy final e a submissão do Target Audience.
- **Claude (arquitetura)**: garante que o `SECURITY.md`, `DATA_MODEL.md` e
  `API_CONTRACT.md` implementam as regras deste documento antes de qualquer
  código ser escrito.
- **Claude Code**: implementa a tela de idade neutra e o "child_safe_mode" como
  parte do Vertical Slice 01 — não como feature futura.
