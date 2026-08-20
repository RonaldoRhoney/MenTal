# MENTAL client — Vertical Slice 01 (Flutter)

Implementa o core loop completo do V1: Age Gate → Home → escolher
território → responder desafio (com dica opcional) → resultado/explicação
→ progresso → próximo desafio.

## Status — NÃO TESTADO (limitação do ambiente de implementação)

Este código foi escrito seguindo `docs/01_FOUNDATION/*` e o Dart/Flutter
foi revisado manualmente, mas **o Flutter SDK não está disponível no
ambiente onde este Vertical Slice foi implementado** — não foi possível
rodar `flutter pub get`, `flutter analyze`, `flutter test` nem abrir num
emulador/dispositivo real. Diferente do backend (16 testes executados de
verdade, servidor validado com `curl`), este cliente **não tem nenhuma
execução real confirmada**.

Antes de considerar o Vertical Slice 01 completo do lado do cliente,
alguém com Flutter SDK instalado precisa:
1. `flutter pub get` (confirmar que as dependências resolvem).
2. `flutter analyze` (pegar erro de sintaxe/tipo que a revisão manual não vê).
3. Rodar num emulador Android contra o backend local (`kApiBaseUrl` já
   aponta para `10.0.2.2:8000`, endereço padrão do host a partir do
   emulador Android).
4. Exercitar o fluxo completo manualmente: age gate → escolher território
   → pedir dica → responder → ver resultado → próximo desafio.

## Autenticação (mesmo gap do backend)

Sem projeto Supabase configurado, o cliente gera um `user_id` local
(UUID, `lib/api/session_store.dart`) e o envia como Bearer token — espelha
o modo `DEV_INSECURE` do backend. Ver `backend/README.md` e o relatório do
Vertical Slice 01 para o plano de substituição por login real.

## Fora de escopo deste slice (por decisão travada, não esquecimento)

Splash screen com sequência de marca (`BRAND.md` §3), tela de ranking,
tela de assinatura/paywall, card de conquista compartilhável, deep link de
convite. O escopo do V1 travado por Rhoney é só o loop de desafio — essas
telas consomem endpoints que já existem no backend (`ranking`,
`subscription`, `social`) mas não têm UI neste slice.
