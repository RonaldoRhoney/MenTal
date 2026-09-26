package com.rhoneyinc.mental

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

// INVESTIGACAO_PLAY_CONSOLE_V8_V1.md (18/09/2026) — aviso do Google Play
// Console: "A exibição de ponta a ponta pode não estar disponível para
// todos os usuários" (SDK alvo 35+ passa a ser edge-to-edge por padrão no
// Android 15+). `androidx.activity.enableEdgeToEdge()` (a chamada que o
// próprio aviso sugere) é uma extensão de ComponentActivity — não
// compila aqui porque FlutterActivity estende android.app.Activity puro
// (confirmado no fonte do engine), não ComponentActivity/AppCompatActivity.
// WindowCompat.setDecorFitsSystemWindows funciona em qualquer Activity via
// Window, faz exatamente o que enableEdgeToEdge faz por baixo dos panos, e
// já vem garantido pelo androidx.core que o próprio embedding do Flutter
// já traz — sem dependência nova.
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
