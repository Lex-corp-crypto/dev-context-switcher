import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../domain/entities/window_snapshot.dart';

class WindowLayoutCanvas extends StatefulWidget {
  final List<WindowInfo> windows;

  const WindowLayoutCanvas({super.key, required this.windows});

  @override
  State<WindowLayoutCanvas> createState() => _WindowLayoutCanvasState();
}

class _WindowLayoutCanvasState extends State<WindowLayoutCanvas> {
  String? _hoveredWindowId;

  Color _getAppColor(String appName) {
    final lower = appName.toLowerCase();
    if (lower.contains('code') || lower.contains('vscode')) return Colors.blue;
    if (lower.contains('term') || lower.contains('bash') || lower.contains('zsh')) return Colors.teal;
    if (lower.contains('chrome') || lower.contains('brave') || lower.contains('firefox') || lower.contains('browser')) return Colors.amber;
    if (lower.contains('flutter') || lower.contains('dart')) return Colors.lightBlue;
    if (lower.contains('docker')) return Colors.cyan;
    if (lower.contains('git')) return Colors.orange;
    if (lower.contains('idea') || lower.contains('android') || lower.contains('studio')) return Colors.pink;
    return Colors.indigoAccent;
  }

  IconData _getAppIcon(String appName) {
    final lower = appName.toLowerCase();
    if (lower.contains('code') || lower.contains('vscode')) return Icons.code;
    if (lower.contains('term') || lower.contains('bash') || lower.contains('zsh')) return Icons.terminal;
    if (lower.contains('chrome') || lower.contains('brave') || lower.contains('firefox') || lower.contains('browser')) return Icons.language;
    if (lower.contains('docker')) return Icons.grid_view;
    if (lower.contains('file') || lower.contains('nautilus') || lower.contains('thunar')) return Icons.folder;
    return Icons.window;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.windows.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        child: const Center(
          child: Text('Aucune disposition de fenêtre capturée', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    // Calculate virtual desktop bounds
    double minX = 0;
    double minY = 0;
    double maxX = 1920;
    double maxY = 1080;

    for (final w in widget.windows) {
      if (w.bounds.left < minX) minX = w.bounds.left;
      if (w.bounds.top < minY) minY = w.bounds.top;
      if (w.bounds.right > maxX) maxX = w.bounds.right;
      if (w.bounds.bottom > maxY) maxY = w.bounds.bottom;
    }

    final desktopWidth = math.max(1280.0, maxX - minX);
    final desktopHeight = math.max(720.0, maxY - minY);
    final aspectRatio = desktopWidth / desktopHeight;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141721),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Virtual Monitor Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFF1C2030),
            child: Row(
              children: [
                Row(
                  children: [
                    Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(width: 14),
                Icon(Icons.desktop_windows, size: 14, color: Colors.white.withOpacity(0.7)),
                const SizedBox(width: 6),
                Text(
                  'Topologie Virtuelle (${desktopWidth.toInt()} × ${desktopHeight.toInt()} px)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
                  ),
                  child: Text(
                    '${widget.windows.length} fenêtres actives',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Canvas Area
          AspectRatio(
            aspectRatio: aspectRatio.clamp(1.2, 2.4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scaleX = constraints.maxWidth / desktopWidth;
                final scaleY = constraints.maxHeight / desktopHeight;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Grid pattern background
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GridPainter(),
                      ),
                    ),

                    // Windows
                    ...widget.windows.map((w) {
                      final left = (w.bounds.left - minX) * scaleX;
                      final top = (w.bounds.top - minY) * scaleY;
                      final width = math.max(60.0, w.bounds.width * scaleX);
                      final height = math.max(40.0, w.bounds.height * scaleY);
                      final isHovered = _hoveredWindowId == w.id;
                      final appColor = _getAppColor(w.appName);

                      return Positioned(
                        left: left.clamp(0.0, constraints.maxWidth - width),
                        top: top.clamp(0.0, constraints.maxHeight - height),
                        width: width.clamp(50.0, constraints.maxWidth),
                        height: height.clamp(35.0, constraints.maxHeight),
                        child: MouseRegion(
                          onEnter: (_) => setState(() => _hoveredWindowId = w.id),
                          onExit: (_) => setState(() => _hoveredWindowId = null),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: isHovered
                                  ? appColor.withOpacity(0.25)
                                  : const Color(0xFF24283B).withOpacity(0.9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isHovered ? appColor : appColor.withOpacity(0.45),
                                width: isHovered ? 2 : 1,
                              ),
                              boxShadow: [
                                if (isHovered)
                                  BoxShadow(
                                    color: appColor.withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Window Title Bar
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: appColor.withOpacity(isHovered ? 0.35 : 0.2),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(_getAppIcon(w.appName), size: 11, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          w.appName.isNotEmpty ? w.appName : 'Fenêtre',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Window Body
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (w.title.isNotEmpty && w.title != w.appName)
                                          Expanded(
                                            child: Text(
                                              w.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.7),
                                                fontSize: 9,
                                              ),
                                            ),
                                          )
                                        else
                                          const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.4),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            '${w.bounds.width.toInt()}×${w.bounds.height.toInt()} @ (${w.bounds.left.toInt()},${w.bounds.top.toInt()})',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.6),
                                              fontSize: 8,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;

    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
