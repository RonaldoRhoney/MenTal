import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// MAPA_TRAJETORIA_MUNDOS_V1.md — Fase 3 (mapa espacial). Layout e estilo
/// replicam fielmente o mockup que Rhoney aprovou (SVG embutido em
/// `Mental App - Claude_files/saved_resource.html`, 18/09/2026): esfera
/// com gradiente por Mundo, anel elíptico, caminho de constelação
/// serpenteando conectando os planetas, % dentro do planeta pra "em
/// órbita", estrelas pra progresso, cadeado + cinza pra "a explorar"
/// (efeito "fog of war" — a cor real do Mundo só aparece quando o
/// jogador começa a explorá-lo). Continua só exibindo o que GET
/// /progress/trajectory-map já devolve pronto — nenhum cálculo de
/// progresso acontece aqui, só posicionamento/estilo visual.
class TrajectoryMapScreen extends StatefulWidget {
  const TrajectoryMapScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<TrajectoryMapScreen> createState() => _TrajectoryMapScreenState();
}

class _TrajectoryMapScreenState extends State<TrajectoryMapScreen> {
  List<Map<String, dynamic>> _nodes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.client.trajectoryMap();
      if (!mounted) return;
      setState(() => _nodes = (result['nodes'] as List).cast<Map<String, dynamic>>());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.trajectoryMapScreenTitle)),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: TextStyle(color: AppColors.error)))
                : _nodes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(l10n.trajectoryMapEmptyMessage, textAlign: TextAlign.center),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.gold,
                        child: _GalaxyMap(nodes: _nodes, l10n: l10n),
                      ),
      ),
    );
  }
}

class _NodePos {
  const _NodePos(this.center, this.radius);
  final Offset center;
  final double radius;
}

const double _kCanvasWidth = 320;
const double _kLeftX = 96;
const double _kRightX = 224;
const double _kWorldSpacing = 118;
// 132 (era 92): o rótulo de 2 linhas do Mundo vizinho invadia o SubMundo (achado UX 20/09/2026).
const double _kSubmundoSpacing = 132;
const double _kWorldRadius = 32;
const double _kSubmundoRadius = 23;
const double _kTopMargin = 56;
const double _kBottomMargin = 56;

List<_NodePos> _computePositions(List<Map<String, dynamic>> nodes) {
  final positions = <_NodePos>[];
  double y = _kTopMargin;
  var leftSide = true;
  var parentX = _kLeftX;
  for (final node in nodes) {
    if (node['type'] == 'world') {
      final x = leftSide ? _kLeftX : _kRightX;
      positions.add(_NodePos(Offset(x, y), _kWorldRadius));
      parentX = x;
      y += _kWorldSpacing;
      leftSide = !leftSide;
    } else {
      final x = parentX == _kLeftX ? _kRightX - 32 : _kLeftX + 32;
      positions.add(_NodePos(Offset(x, y), _kSubmundoRadius));
      y += _kSubmundoSpacing;
    }
  }
  if (positions.isEmpty) return positions;
  // Pedido de Rhoney (18/09/2026): a jornada começa embaixo (1º Mundo) e
  // sobe conforme o jogador conquista — mesma direção do mockup original
  // (metáfora de "subir no universo"). O algoritmo acima calcula as
  // posições de cima pra baixo por simplicidade; aqui só espelha o eixo Y
  // pra inverter a ordem visual sem duplicar a lógica de espaçamento/zigue-zague.
  final minY = positions.first.center.dy;
  final maxY = positions.last.center.dy;
  return [
    for (final p in positions) _NodePos(Offset(p.center.dx, maxY - p.center.dy + minY), p.radius),
  ];
}

/// Cor de identidade por Mundo/SubMundo (par claro/escuro pro gradiente
/// radial) — só aparece quando o status já é "em órbita" ou
/// "conquistado"; "a explorar" sempre usa o cinza neutro (fog of war).
const Map<String, List<Color>> _kPlanetPalette = {
  'linguagem': [Color(0xFFED93B1), Color(0xFF72243E)],
  'mente_logica': [Color(0xFF85B7EB), Color(0xFF0C447C)],
  'cultura_geral': [Color(0xFFFAC775), Color(0xFF854F0B)],
  'descoberta': [Color(0xFF9FE1CB), Color(0xFF0C6B4F)],
  'idiomas': [Color(0xFFED93B1), Color(0xFF72243E)],
  'valores': [Color(0xFFFAC775), Color(0xFF854F0B)],
  'transito': [Color(0xFFF0997B), Color(0xFF993C1D)],
  'esportes': [Color(0xFFF0997B), Color(0xFF993C1D)],
  'mitologia': [Color(0xFFB79BEF), Color(0xFF4B3878)],
  'enem': [Color(0xFF5DCAA5), Color(0xFF085041)],
  'concursos': [Color(0xFF5DCAA5), Color(0xFF085041)],
  'tecnologia': [Color(0xFF6FD8E0), Color(0xFF0B5A63)],
  'regioes_brasil': [Color(0xFFA8D98A), Color(0xFF3E6B25)],
  'gastronomia': [Color(0xFFF2B15C), Color(0xFF8A4E0F)],
  'oceanos': [Color(0xFF6FB8E0), Color(0xFF0E4870)],
  'espaco': [Color(0xFFB7A6F0), Color(0xFF3B2E70)],
  'tecnologia:internet': [Color(0xFF5DCAA5), Color(0xFF085041)],
  'esportes:copa_do_mundo': [Color(0xFFF0997B), Color(0xFF993C1D)],
  'esportes:futebol': [Color(0xFFF0997B), Color(0xFF993C1D)],
};

List<Color> _paletteFor(String nodeId) {
  if (_kPlanetPalette.containsKey(nodeId)) return _kPlanetPalette[nodeId]!;
  // Fallback determinístico pra qualquer Mundo/SubMundo futuro ainda não
  // registrado acima — nunca deixa um planeta sem cor própria.
  const fallback = [
    [Color(0xFF85B7EB), Color(0xFF0C447C)],
    [Color(0xFFF0997B), Color(0xFF993C1D)],
    [Color(0xFF9FE1CB), Color(0xFF0C6B4F)],
    [Color(0xFFFAC775), Color(0xFF854F0B)],
  ];
  return fallback[nodeId.hashCode.abs() % fallback.length];
}

/// Pedido de Rhoney (18/09/2026): cada planeta precisa remeter à
/// característica do próprio Mundo, não só ter uma cor genérica — um
/// ícone temático (livro, bola, chip, foguete...) desenhado dentro da
/// esfera, sem depender de ilustração externa (continua tudo nativo,
/// leve e testável).
const Map<String, IconData> _kPlanetIcons = {
  'linguagem': Icons.menu_book_rounded,
  'mente_logica': Icons.calculate_rounded,
  'cultura_geral': Icons.public_rounded,
  'descoberta': Icons.explore_rounded,
  'idiomas': Icons.translate_rounded,
  'valores': Icons.favorite_rounded,
  'transito': Icons.traffic_rounded,
  'esportes': Icons.sports_soccer_rounded,
  'mitologia': Icons.bolt_rounded,
  'enem': Icons.school_rounded,
  'concursos': Icons.gavel_rounded,
  'tecnologia': Icons.memory_rounded,
  'regioes_brasil': Icons.map_rounded,
  'gastronomia': Icons.restaurant_rounded,
  'oceanos': Icons.waves_rounded,
  'espaco': Icons.rocket_launch_rounded,
  'tecnologia:internet': Icons.wifi_rounded,
  'esportes:copa_do_mundo': Icons.emoji_events_rounded,
  'esportes:futebol': Icons.sports_soccer_rounded,
};

IconData _iconFor(String nodeId) => _kPlanetIcons[nodeId] ?? Icons.public_rounded;

class _GalaxyMap extends StatelessWidget {
  const _GalaxyMap({required this.nodes, required this.l10n});

  final List<Map<String, dynamic>> nodes;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final positions = _computePositions(nodes);
    // O 1º nó fica embaixo (dy maior) após o espelhamento em
    // _computePositions, então a altura do canvas usa o maior dy entre
    // todos os nós, não necessariamente o último da lista.
    final canvasHeight = positions.isEmpty
        ? _kTopMargin + _kBottomMargin
        : positions.map((p) => p.center.dy).reduce(math.max) + _kBottomMargin;
    final worldNodes = nodes.where((n) => n['type'] == 'world').toList();
    final exploredWorlds = worldNodes.where((n) => n['status'] != 'not_started').length;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.trajectoryMapUniverseLabel, style: Theme.of(context).textTheme.titleMedium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bg2,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.muted.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    l10n.trajectoryMapWorldsCount(exploredWorlds, worldNodes.length),
                    style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: _kCanvasWidth,
              height: canvasHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _ConstellationBackgroundPainter(positions)),
                  ),
                  for (var i = 0; i < nodes.length; i++)
                    _PositionedPlanet(node: nodes[i], pos: positions[i], l10n: l10n),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _MapLegend(l10n: l10n),
        ],
      ),
    );
  }
}

/// Estrelas de fundo + caminho de constelação pontilhado conectando o
/// centro de cada planeta em sequência — puramente decorativo, sem
/// nenhum texto (texto real fica em widgets, não desenhado no canvas,
/// pra continuar testável via `find.text`).
class _ConstellationBackgroundPainter extends CustomPainter {
  _ConstellationBackgroundPainter(this.positions);

  final List<_NodePos> positions;

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    final starRandom = math.Random(7);
    for (var i = 0; i < 18; i++) {
      final dx = starRandom.nextDouble() * size.width;
      final dy = starRandom.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 1 + starRandom.nextDouble() * 0.6, starPaint);
    }

    if (positions.length < 2) return;
    final path = Path()..moveTo(positions.first.center.dx, positions.first.center.dy);
    for (var i = 1; i < positions.length; i++) {
      final prev = positions[i - 1].center;
      final curr = positions[i].center;
      final midY = (prev.dy + curr.dy) / 2;
      path.quadraticBezierTo(prev.dx, midY, curr.dx, curr.dy);
    }
    final dashed = _dashPath(path, dashWidth: 5, dashGap: 5);
    final connectorPaint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(dashed, connectorPaint);
  }

  Path _dashPath(Path source, {required double dashWidth, required double dashGap}) {
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final len = draw ? dashWidth : dashGap;
        final next = math.min(distance + len, metric.length);
        if (draw) dashed.addPath(metric.extractPath(distance, next), Offset.zero);
        distance = next;
        draw = !draw;
      }
    }
    return dashed;
  }

  @override
  bool shouldRepaint(covariant _ConstellationBackgroundPainter oldDelegate) => false;
}

/// Anel elíptico inclinado tipo Saturno — decorativo, atrás/ao redor da
/// esfera do planeta.
class _RingPainter extends CustomPainter {
  _RingPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.save();
    canvas.translate(size.width / 2, size.height * 0.32);
    canvas.rotate(-0.22);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: size.width * 1.35, height: size.height * 0.34),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.color != color;
}

class _PositionedPlanet extends StatelessWidget {
  const _PositionedPlanet({required this.node, required this.pos, required this.l10n});

  final Map<String, dynamic> node;
  final _NodePos pos;
  final AppLocalizations l10n;

  String _statusLabel(String status) => switch (status) {
        'completed' => l10n.trajectoryStatusCompleted,
        'in_progress' => l10n.trajectoryStatusInProgress,
        _ => l10n.trajectoryStatusNotStarted,
      };

  @override
  Widget build(BuildContext context) {
    final status = node['status'] as String;
    final percent = (node['percent'] as num).toDouble();
    final stars = node['stars'] as int;
    final isSubmundo = node['type'] == 'submundo';
    final notStarted = status == 'not_started';
    final palette = _paletteFor(node['id'] as String);
    final diameter = pos.radius * 2;
    // Cinza neutro (fog of war) enquanto o Mundo não começou a ser
    // explorado — a cor de identidade só aparece com progresso real.
    final gradientColors = notStarted ? const [Color(0xFF5F5E5A), Color(0xFF2C2C2A)] : palette;
    final ringColor = notStarted ? AppColors.muted.withValues(alpha: 0.5) : palette[0].withValues(alpha: 0.7);

    const columnWidth = 128.0;
    final labelTop = pos.center.dy + pos.radius + 6;

    return Stack(
      children: [
        Positioned(
          left: pos.center.dx - pos.radius,
          top: pos.center.dy - pos.radius,
          width: diameter,
          height: diameter,
          child: Opacity(
            opacity: notStarted ? 0.55 : 1,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                CustomPaint(size: Size(diameter, diameter), painter: _RingPainter(color: ringColor)),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.35, -0.35),
                      colors: gradientColors,
                    ),
                    border: Border.all(color: notStarted ? AppColors.muted : palette[0], width: 1.4),
                  ),
                  child: Center(
                    child: notStarted
                        ? Icon(Icons.lock_rounded, color: AppColors.muted, size: pos.radius * 0.75)
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              // Ícone temático do Mundo — sempre presente
                              // quando explorado, pra o planeta remeter à
                              // característica dele (livro, bola, chip...),
                              // não só a uma cor genérica. Em "em andamento"
                              // fica como marca d'água atrás do %, que
                              // continua sendo a informação principal.
                              Icon(
                                _iconFor(node['id'] as String),
                                color: Colors.white.withValues(alpha: status == 'completed' ? 0.9 : 0.35),
                                size: pos.radius * (status == 'completed' ? 0.85 : 1.05),
                              ),
                              if (status == 'in_progress')
                                Text(
                                  '${percent.toStringAsFixed(0)}%',
                                  style: AppTheme.technicalStyle(color: Colors.white, fontSize: pos.radius * 0.42)
                                      .copyWith(shadows: const [Shadow(color: Colors.black54, blurRadius: 3)]),
                                ),
                            ],
                          ),
                  ),
                ),
                if (stars > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: _StarBadge(stars: stars),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          left: pos.center.dx - columnWidth / 2,
          top: labelTop,
          width: columnWidth,
          child: Column(
            children: [
              if (isSubmundo)
                Text(
                  l10n.trajectoryMapSubmundoLabel,
                  textAlign: TextAlign.center,
                  style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 9),
                ),
              Text(
                node['name'] as String,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: notStarted ? AppColors.muted : AppColors.bone,
                  fontWeight: FontWeight.w500,
                  fontSize: isSubmundo ? 11 : 12,
                ),
              ),
              Text(
                _statusLabel(status),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: notStarted ? AppColors.muted : palette[0],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StarBadge extends StatelessWidget {
  const _StarBadge({required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEF9F27)),
      child: Center(
        child: Text('$stars', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    Widget dot(Color color, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: AppColors.muted, fontSize: 11)),
          ],
        );

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        dot(AppColors.teal, l10n.trajectoryStatusCompleted),
        dot(AppColors.gold, l10n.trajectoryStatusInProgress),
        dot(AppColors.muted, l10n.trajectoryStatusNotStarted),
      ],
    );
  }
}
