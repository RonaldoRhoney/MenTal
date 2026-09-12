# MENTAL — Auditoria Completa Pré-Produção (Solicitação de Acesso à Produção)

**Status:** Concluída (11/09/2026) — as 6 seções foram cobertas e todos
os achados aplicáveis corrigidos: seções 1-4 (idade 18+, segurança,
regras de negócio, RLS) pelo agente `mental-security`; seção 5
(agentes de IA) pelo agente `mental-testing` (MentalQA) + revisão
direta do MentalGuard; seção 6 (documentação/nomenclatura) por revisão
direta. Achados corrigidos: schema `mental` verificado como não-exposto
ao PostgREST; FK de LGPD em 4 tabelas (migration 071); Política de
Privacidade atualizada; rate limit em `/social/report` e
`/profile/{id}/follow`; nome real em 5 notificações push + Painel
Admin; `XP_PER_LEVEL` duplicado eliminado; comentários desatualizados
em `seed.py` e no agente `mental-security`.
**Contexto:** O período de teste fechado terminou e Rhoney vai solicitar o acesso à produção no Google Play Console. Esta é a última checagem ampla antes de o app ficar disponível para o público em geral — deve ser tratada com o mesmo rigor da auditoria de segurança pré-AAB já realizada, mas com escopo mais amplo, cobrindo política, segurança, regras de negócio, RLS, agentes de IA e documentação.
**Tipo:** Auditoria/investigação — não é para corrigir nada automaticamente. Reportar tudo encontrado, propor correção, aguardar aprovação antes de aplicar qualquer mudança, mesmo padrão já usado em auditorias anteriores.

---

## 1. Política de classificação etária — verificação central desta rodada

Confirmar, de ponta a ponta, que o app está **hoje, de fato, corretamente restrito a maiores de 18 anos**, sem nenhuma brecha:

- Confirmar que a classificação declarada no Play Console está corretamente marcada como 18+, condizente com o conteúdo real do app.
- Confirmar que não existe nenhum fluxo, tela ou funcionalidade que ainda pressuponha ou permita usuário menor de idade (ex.: resquício de `parental_gate`, já identificado como pendência em auditoria anterior — verificar se ainda existe e reportar).
- Confirmar que a Data Safety Section do Play Console reflete com precisão o que o app realmente coleta e faz, sem divergência entre o declarado e o comportamento real.
- Confirmar que toda a documentação de política de privacidade e termos de uso, tanto no app quanto no repositório, está atualizada e menciona claramente a exigência de 18+.
- Verificar se há qualquer texto, tela ou copy no app (incluindo o mural de Feedback, Torcida, convites) que direcione ou pareça se dirigir a público infantil/adolescente, mesmo que de forma não intencional.

## 2. Segurança

- Revalidar que as correções críticas já aprovadas em APROVACAO_CORRECOES_PRE_AAB_V1.md (C1, A1, M5, e o pacote M1/M2/M4) foram de fato aplicadas e estão presentes na versão que vai para produção — não presumir que já foram aplicadas só porque foram aprovadas antes; confirmar no código atual.
- Rodar uma nova varredura de segurança completa (mesmo escopo do MentalGuard), já que pode ter havido mudança de código desde a última auditoria formal.
- Confirmar que a configuração de build de produção (assinatura, minificação, permissões declaradas) está correta, sem repetir o risco já identificado antes de builds caindo silenciosamente para chave de debug.

## 3. Regras de negócio

- Revisar se as regras de negócio centrais do app (XP, streak, MentalCoins, limites de Torcida, limites de denúncia/bloqueio, elegibilidade de Movimento) continuam consistentes entre backend e cliente, sem nenhuma regra que possa ter ficado desalinhada com as últimas mudanças de estrutura (reorganização de Mundos, Feed, etc.).
- Confirmar que a autoridade de cálculo de XP, passos, tempo e resultado continua 100% no backend, sem nenhuma exceção introduzida por mudanças recentes.

## 4. RLS (Row Level Security) do Supabase

- Revisar as políticas de RLS de todas as tabelas do banco, confirmando que cada uma restringe corretamente o acesso ao dono do dado (ou ao escopo público correto, quando aplicável — ex.: Ranking, Perfil Público).
- Dar atenção especial às tabelas mais recentes (Feed, sistema de Seguir/Fã, novos Mundos), confirmando que já têm RLS aplicado corretamente, já que são as mais propensas a terem sido criadas sem esse cuidado replicado das tabelas mais antigas.
- Confirmar que a correção de bloqueio de usuário (item A1) se reflete corretamente também no nível de RLS, não apenas na lógica de aplicação.

## 5. Agentes de IA (MentalGuard, MentalQA, MentalScout, e demais formalizados)

- Confirmar o status real de implementação de cada agente já formalizado (MentalGuard, MentalQA, MentalScout implementados; MentalPulse, MentalFeedAI, MentalShield formalizados aguardando implementação; MentalComply, MentalAudit, MentalGrowth ainda candidatos).
- Rodar MentalGuard e MentalQA nesta rodada, já que ambos estão implementados e são diretamente relevantes para esta auditoria pré-produção.
- Reportar se algum agente já implementado ficou desatualizado em relação à stack real do projeto (mesmo problema já corrigido uma vez no MentalGuard, verificar se não regrediu).

## 6. Documentação e dinâmica geral do projeto

- Revisar se a documentação viva do projeto (README, documentos de arquitetura, checklist de compliance) reflete o estado real e atual do app, e não decisões antigas já superadas por reorganizações posteriores (ex.: desmembramento do Mundo da Cultura Geral, renomeações de Mundo).
- Confirmar que não há nenhuma referência quebrada a nomes antigos de Mundo/território em qualquer parte do sistema (código, banco, documentação, Admin Dashboard).
- Revisar a dinâmica geral de uso do app de ponta a ponta (fluxo completo: cadastro → Home → jogar um desafio → Movimento → Ranking → Amigos → Feed → Batalhas), confirmando que tudo funciona de forma coesa após todas as mudanças recentes, sem quebra de fluxo entre uma tela e outra.

## 7. O que NÃO fazer nesta rodada

- Não aplicar nenhuma correção antes de reportar todos os achados e aguardar aprovação.
- Não presumir que algo está certo só porque foi aprovado ou corrigido em documento anterior — esta auditoria existe justamente para confirmar que o que foi decidido está de fato implementado e ainda válido hoje.

## 8. Formato do relatório

Mesmo formato já validado em auditorias anteriores: para cada item encontrado, indicar severidade (crítico / alto / médio / baixo), localização exata (arquivo/linha ou tela), evidência, e ação sugerida — sem aplicar nada ainda. Seções sem nenhum achado devem ser reportadas explicitamente como "✅ verificado, nenhum problema encontrado", não deixadas em silêncio.

## 9. Critério de aceite

- Relatório completo cobrindo as 6 frentes desta auditoria (classificação etária, segurança, regras de negócio, RLS, agentes, documentação/dinâmica).
- Confirmação explícita, com evidência, de que o app está corretamente restrito a 18+ em todos os pontos verificados.
- Nenhuma correção aplicada sem aprovação prévia de Rhoney.
- Relatório entregue a tempo de ser revisado antes da solicitação de acesso à produção no Play Console.
