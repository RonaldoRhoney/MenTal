# MENTAL — ATUALIZAÇÃO DE MONETIZAÇÃO: LANÇAMENTO 100% GRATUITO

Status: aprovado por Rhoney (dono). Atualiza `MONETIZATION.md` e a Seção 4
de `MENTAL_KICKOFF.md`. Não substitui o modelo freemium documentado — adia
sua ativação para uma fase futura, decidida por Rhoney.

## 1. Decisão

O MENTAL será lançado **100% gratuito**, sem nenhuma cobrança, mesmo tendo
territórios/features já desenhados como "pagos" na documentação original.

Motivo estratégico (não é mudança de arquitetura, é sequenciamento de
negócio): não faz sentido cobrar de um app recém-lançado, sem base de
usuários, sem prova social e sem dado real de comportamento de uso. A
sequência correta é: lançar gratuito → crescer base de usuários → observar
dados reais de engajamento e retenção → **então** decidir preço, régua
free/pago e o momento de ativar cobrança, com informação real em mãos em
vez de suposição.

## 2. O que muda tecnicamente — e o que não muda

**Não muda:** nenhuma tabela do `DATA_MODEL.md`, nenhum endpoint do
`API_CONTRACT.md`, nenhuma regra do `SECURITY.md`. Toda a estrutura de
assinatura (`subscriptions`, `daily_challenge_usage`, mapeamento
território↔plano) permanece exatamente como já implementada. Isso não é
retrabalho — é trabalho que já existe e continua existindo, apenas não
aplicado por enquanto.

**Muda:** o backend passa a operar com uma flag de configuração global —
sugestão de nome: `MONETIZATION_ENABLED` (env var, default `false`).

- Quando `MONETIZATION_ENABLED=false`: toda checagem de "território exige
  assinatura" é ignorada — todos os territórios ficam liberados para todos
  os usuários, independentemente de status de assinatura. O endpoint de
  status de assinatura pode continuar existindo e respondendo normalmente
  (ex.: sempre retornar "acesso completo liberado"), sem necessidade de
  esconder ou remover UI relacionada a assinatura no client — apenas o
  bloqueio de conteúdo é desativado.
- Quando `MONETIZATION_ENABLED=true` (ativação futura): volta a valer
  exatamente o modelo já documentado em `MONETIZATION.md` — territórios
  pagos exigem assinatura ativa, validação de recibo, parental gate, etc.

Isso deve ser implementado como uma única flag central, verificada em um
ponto único do backend (ex.: no serviço que resolve "este usuário pode
acessar este território?") — nunca espalhada em múltiplos lugares do
código, para que ativar cobrança no futuro seja alterar uma variável de
ambiente, não caçar checagens por vários arquivos.

## 3. O que permanece ativo mesmo no modo gratuito

O **limite diário de desafios** **continua ativo** mesmo com
`MONETIZATION_ENABLED=false`. Ele não existe por causa de dinheiro — existe
para criar ritmo de uso e hábito de retorno diário (parte do design de
streak/retenção). Suspendê-lo removeria um mecanismo de engajamento que não
tem relação com a decisão de monetização.

**Atualização (revisão de valor):** o limite diário foi ajustado de 8 para
**24 desafios/dia**. Motivo: 8 era calibrado originalmente como parte da
régua freemium (incentivo a assinar); com o lançamento 100% gratuito
(Seção 1), a única função do limite passou a ser hábito/retenção via
streak, não conversão. Um teto baixo nesse contexto tende a frustrar o
jogador novo e reduzir a chance de retorno no dia seguinte — 24 permite
uma sessão diária mais longa e satisfatória, mantendo o gatilho de "volte
amanhã" sem soar como bloqueio.

Requisitos de implementação desta mudança:
- O valor deve estar centralizado em um único ponto de configuração (mesma
  prática já usada para XP/nível/dificuldade) — nunca hardcoded em mais de
  um lugar.
- O contador visível na Home/UI (se existir) deve refletir o novo teto de
  24, consistente com o que o backend aplica.
- A mensagem da tela de "limite atingido" deve ter tom celebratório e
  motivador (ex.: "Volte amanhã para mais 24 desafios!"), não tom de
  bloqueio ou restrição — coerente com o Princípio de Não-Humilhação já
  definido no produto.

## 4. Ativação futura

Quando Rhoney decidir ativar monetização (com base em volume real de
usuários e dado de uso), a ativação deve ser: mudar a env var
`MONETIZATION_ENABLED` para `true`, revisar se o valor da assinatura e a
régua free/pago documentados em `MONETIZATION.md` ainda fazem sentido à
luz do dado real coletado, e só então liberar. Isso não deve exigir nova
rodada de desenvolvimento de funcionalidade — o sistema já nasce pronto
para essa transição.

## 5. Papel de cada parte

- **Rhoney**: decide o momento de ativar monetização; decide se ajusta
  preço/régua com base em dado real antes de ativar.
- **Claude (arquitetura)**: garante que a flag está implementada em ponto
  único e que nenhuma lógica de negócio depende de forma implícita de
  cobrança estar ativa (ex.: nada quebra ou se comporta de forma inesperada
  rodando com `MONETIZATION_ENABLED=false` por tempo indefinido).
- **Claude Code**: implementa a flag, testa os dois estados
  (`true`/`false`) com os testes automatizados já existentes, e documenta
  o default (`false`) claramente no `README.md` do backend.

## 6. Ação imediata

1. Adicionar `MONETIZATION_ENABLED` (default `false`) na configuração do
   backend.
2. Centralizar a checagem de acesso a território em um único ponto que
   respeita essa flag.
3. Rodar os testes existentes com a flag em `false` — confirmar que todos
   os territórios ficam acessíveis a qualquer usuário autenticado.
4. Rodar os testes existentes com a flag em `true` — confirmar que o
   comportamento freemium documentado em `MONETIZATION.md` continua
   funcionando exatamente como antes desta mudança.
5. Atualizar `MONETIZATION.md` com uma nota no topo referenciando este
   documento como a decisão vigente de lançamento.
6. Não remover, não simplificar e não apagar nenhuma lógica de assinatura
   já implementada — apenas desativá-la por trás da flag.
