Preciso que você execute uma varredura de conformidade do projeto MENTAL com as políticas do Google Play. Isso é AUDITORIA, não correção — não altere nenhum código nesta rodada, apenas investigue e reporte o estado real de cada item. Eu decido depois, item a item, o que corrigir e em que ordem.

Para cada item numerado abaixo, responda exatamente neste formato:

[ITEM]: ✅ Conforme / ⚠️ Atenção / 🔴 Não conforme / ❓ Não foi possível verificar
Evidência: [arquivo/linha do código, ou tela do Play Console a checar manualmente]
Ação necessária (se houver): [o que precisaria ser feito — sem fazer ainda]

---

## 1. Target API Level (prazo 31 de agosto de 2026)
- Verifique o `targetSdkVersion` atual no build.gradle (ou equivalente Flutter/Android) do projeto.
- Confirme se corresponde a Android 15 (API level 35) ou superior.
- Se não conforme, reporte o API level atual e o que muda tecnicamente para atualizar (dependências afetadas, breaking changes conhecidos do Android 15).

## 2. Registro de Package Name (prazo 30 de setembro de 2026)
- Reporte o `applicationId` exato em uso no projeto.
- Isso precisa ser confirmado no Play Console (não no código) — se não for possível verificar, responda ❓ e me diga exatamente onde no Play Console eu devo checar.

## 3. Seção "Data Safety" do Play Console
- Varra o código-fonte e liste todos os tipos de dado pessoal que o app efetivamente coleta e envia ao backend (não suponha — confira chamadas reais de API e tabelas do Supabase envolvidas): e-mail, nome real, foto de perfil, dados de localização (se houver), dados de sensor/atividade física (passos), identificadores de dispositivo (token FCM), dados de analytics (se houver SDK).
- Para cada um: é coletado, é compartilhado com terceiros (ex: Firebase/FCM), é opcional ou obrigatório, tem opção de exclusão pelo usuário.
- Confirme especificamente se o dado do contador de passos está claramente identificável como categoria "Fitness/Activity" na forma como é tratado no código (isso me ajuda a declarar corretamente no Play Console, que eu confiro manualmente depois).

## 4. Permissões sensíveis no Android Manifest
- Liste todas as permissões declaradas no AndroidManifest.xml, com atenção a: ACTIVITY_RECOGNITION (passos), câmera/galeria (foto de perfil), notificações (FCM), e qualquer outra sensível.
- Para cada uma, confirme se existe uma tela/diálogo no app explicando ao usuário por que ela é necessária, antes ou no momento da solicitação (não apenas o diálogo padrão do sistema).
- Reporte se alguma permissão está declarada mas não é mais usada em nenhum fluxo (permissão órfã — deve ser removida).

## 5. Classificação etária e conteúdo 18+
- Confirme que a tela de confirmação de idade (`age_confirmed_at`) de fato bloqueia acesso ao conteúdo até a confirmação, sem caminho de bypass.
- Confirme que a Política de Privacidade publicada (GitHub Pages) está acessível ao vivo sem erro, e que o conteúdo reflete a coleta de dados real e atual do app (nome/foto pública, passos, etc.) — não uma versão desatualizada.
- Content Rating no Play Console é declaração de painel — reporte como ❓ e me diga onde checar.

## 6. Moderação de conteúdo gerado por usuário (UGC)
- Confirme que o fluxo de moderação de fotos de perfil é de fato fail-closed no código (foto nunca aparece publicamente antes de `photo_moderation_status` = aprovado) — checar backend e também se nenhuma tela do cliente Flutter exibe foto pendente como se já fosse pública.
- Verifique se existe, em qualquer tela onde um usuário vê outro (Amigos, Ranking, Batalhas), mecanismo de denúncia/reporte de perfil ou conteúdo impróprio. Se não existir, marque como 🔴 — é exigência do Google para apps com UGC.
- Verifique se existe mecanismo de bloqueio de usuário (evitar convites repetidos após bloqueio). Se não existir, marque como ⚠️.

## 7. Impersonation / Branding
- Confirme que nome do app, ícone e nome do desenvolvedor (RhoneyInc) não colidem com apps/empresas já estabelecidos.
- Confirme que a store listing (descrição curta/longa, screenshots) não faz comparação direta com outros apps.

## 8. Anúncios e SDKs de terceiros
- Confirme que nenhum SDK de anúncios está integrado hoje (esperado: nenhum, já que MONETIZATION_ENABLED=false) — confira ausência real no pubspec.yaml/dependências nativas.
- Liste todos os SDKs de terceiros integrados (Firebase/FCM, Supabase client, libs de auth social) e confirme que cada um está coberto na análise do item 3.

## 9. Qualidade mínima e funcionalidade básica
- Relacione com o bug já reportado separadamente de "desafio não avança após resposta" — se ainda não estiver corrigido no momento desta varredura, ele por si só é risco de reprovação por funcionalidade básica insuficiente. Confirme o status atual desse bug.

## 10. Autenticação e verificação de conta
- Confirme que o login social (Google Sign-In via OAuth) e o login por e-mail/senha não usam nenhuma permissão sensível desnecessária para verificação (ex: leitura de SMS/call log) — o Google está restringindo esse tipo de acesso. Reporte se há qualquer uso de permissão de leitura de SMS ou log de chamadas no fluxo de autenticação.

---

Ao final, me entregue um relatório único, item por item (1 a 10), no formato definido acima, para eu conseguir ver rapidamente o que é urgente (🔴), o que precisa de atenção (⚠️), e o que já está certo (✅) — com a evidência exata usada em cada conclusão.
