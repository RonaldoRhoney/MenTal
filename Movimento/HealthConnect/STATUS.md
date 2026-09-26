# Health Connect — status

**Isolado na branch `health-connect`** (decisão de Rhoney, 25/09/2026): o app está em fase final de produção no Google Play e o Health Connect exige, antes de qualquer AAB, a declaração de permissões de saúde no Play Console, a atualização da política de privacidade e Android mínimo 8.0 (minSdk 26).

A `main` NÃO tem o plugin `health`, a permissão `READ_STEPS`, o cartão do Movimento nem a mudança de minSdk. Todo o código (cartão, serviço, manifest, testes) está na branch `health-connect`.

Para retomar: `git merge health-connect` na `main` depois de (1) declarar no Play Console, (2) atualizar a política de privacidade, (3) decidir sobre aparelhos com Android 7.x. Desenho técnico em `DESENHO_TECNICO_V1.md`.
