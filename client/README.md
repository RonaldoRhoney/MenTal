# MENTAL client — Vertical Slice 01 (Flutter)

Implementa o core loop completo do V1: Age Gate → Home → escolher
território → responder desafio (com dica opcional) → resultado/explicação
→ progresso → próximo desafio.

## Status — VALIDADO de ponta a ponta (2026-08-20)

Diferente da primeira entrega deste slice (código revisado só
manualmente, sem execução real), este client agora foi:

1. `flutter pub get` ✓ — 49 dependências resolvidas sem conflito.
2. `flutter analyze` ✓ — 0 problemas (corrigido uso de API depreciada,
   `RadioListTile.groupValue/onChanged` → `RadioGroup`).
3. `flutter test` ✓ — teste de widget real passando (`test/widget_test.dart`,
   confirma o estado de loading explícito no boot do app).
4. `flutter build web` e `flutter build linux` ✓ — compilação completa,
   sem erros, em dois alvos diferentes.
5. **Execução real, interativa, feita por Rhoney**: o binário Linux
   desktop (`flutter build linux`) rodou contra o backend local
   (`uvicorn`, SQLite de dev) e Rhoney passou pelo fluxo completo nos
   **4 territórios** (Palavras, Números, Lógica, Conhecimento), incluindo
   pedido de dica — confirmado pelo log de acesso do backend: 26
   requisições, todas `200 OK`, zero erro.

Não havia Flutter SDK nem Android Studio disponíveis originalmente
(ambiente sem esses componentes) — a alternativa que funcionou foi
instalar o Flutter SDK via clone do repositório oficial e compilar para
**Linux desktop e Web** em vez de Android, já que é o mesmo código
Dart/Flutter rodando num alvo diferente (não precisa de emulador Android
nem de KVM). Isso valida toda a lógica de UI, navegação, chamadas de API
e tratamento de erro — a mesma coisa que rodaria num APK Android.

**O que isso não valida** (ainda pendente, escopo diferente):
- Empacotamento específico do Android (APK/AAB), permissões do
  `AndroidManifest.xml`, comportamento em tela pequena/touch real.
- Nenhum SDK Android foi instalado neste ambiente — `flutter build apk`
  não foi tentado.
- Antes de gerar um build de release para a Play Store, alguém com
  Android Studio (ou Android SDK cmdline-tools + emulador) precisa
  confirmar o app rodando de fato em Android.

## Como rodar localmente (Linux desktop, sem Android SDK)

```bash
# backend (num terminal)
cd backend && source .venv/bin/activate && uvicorn app.main:app --host 127.0.0.1 --port 8000

# client (noutro terminal)
cd client
flutter build linux
./build/linux/x64/release/bundle/mental
```

`kApiBaseUrl` em `lib/main.dart` detecta a plataforma automaticamente:
`10.0.2.2:8000` no emulador Android, `127.0.0.1:8000` em Web/desktop.

## Autenticação (mesmo gap do backend)

Sem login real implementado ainda, o cliente gera um `user_id` local
(UUID, `lib/api/session_store.dart`) e o envia como Bearer token — espelha
o modo `DEV_INSECURE` do backend. Ver `backend/README.md` e
`docs/02_IMPLEMENTATION/SUPABASE_SETUP.md` §5 para o plano de integração
real com Supabase Auth (Google/email-senha/Facebook, já decidido em
`FAMILY_SAFETY.md` §3.1) — ainda não implementado no client.

## Fora de escopo deste slice (por decisão travada, não esquecimento)

Splash screen com sequência de marca (`BRAND.md` §3), tela de ranking,
tela de assinatura/paywall, card de conquista compartilhável, deep link de
convite. O escopo do V1 travado por Rhoney é só o loop de desafio — essas
telas consomem endpoints que já existem no backend (`ranking`,
`subscription`, `social`) mas não têm UI neste slice.
