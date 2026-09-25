import 'package:flutter/material.dart';

/// Identidade visual NEON dos agentes do MENTAL (padrão do banner do
/// MENTAL LINGO, print Mental_Lingo.webp) — pedido de Rhoney (25/09/2026):
/// aplicar o mesmo estilo (fonte, cores, contorno, brilho) ao My_Mental_AI
/// em todos os Mundos, pra manter um padrão único entre os agentes.
const Color kAgentNavy = Color(0xFF0B1030);
const Color kAgentNavy2 = Color(0xFF16123F);
const Color kAgentCyan = Color(0xFF3DC8FF);
const Color kAgentBlue = Color(0xFF3A6BFF);
const Color kAgentIndigo = Color(0xFF6A45FF);
const Color kAgentSoftText = Color(0xFFB8BEDF);

/// Fundo padrão dos cartões de agente: gradiente navy, borda azul e brilho.
BoxDecoration agentNeonDecoration({double radius = 20}) => BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [kAgentNavy, kAgentNavy2],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: kAgentBlue.withValues(alpha: 0.85), width: 1.2),
      boxShadow: [
        BoxShadow(color: kAgentBlue.withValues(alpha: 0.35), blurRadius: 18, spreadRadius: 0.5),
      ],
    );
