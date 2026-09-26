package com.rhoneyinc.mental

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle

// Health Connect (Android 14+ exige uma tela de "por que o app usa dados de
// saúde"): abre a Política de Privacidade do MENTAL no navegador e fecha. O
// texto da política precisa citar o uso de passos (ver
// Movimento/HealthConnect/DESENHO_TECNICO_V1.md §5) antes de qualquer AAB com essa
// permissão.
class PermissionsRationaleActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        startActivity(
            Intent(Intent.ACTION_VIEW, Uri.parse("https://ronaldorhoney.github.io/MenTal/"))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        )
        finish()
    }
}
