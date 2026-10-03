import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/campus_location.dart';
import '../../models/enums.dart';
import '../../models/incident.dart';
import '../../models/responder.dart';
import '../../services/incident_service.dart';

/// LBRCE DEMO MAP — a schematic, clearly-labelled SIMULATED campus layout.
/// Building names come from the configurable location list; positions are
/// not real coordinates. Real navigation uses device GPS + Google Maps.
class CampusMap extends StatelessWidget {
  const CampusMap({super.key, this.focusIncidentId, this.height = 300, this.onIncidentTap});
  final String? focusIncidentId;
  final double height;
  final void Function(String incidentId)? onIncidentTap;

  static const worldW = 1000.0;
  static const worldH = 700.0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    final incidents = store.activeIncidents;
    final focus = focusIncidentId == null ? null : store.incident(focusIncidentId!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: height,
        color: const Color(0xFF0A1424),
        child: Stack(children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: LayoutBuilder(builder: (context, c) {
                return GestureDetector(
                  onTapUp: onIncidentTap == null
                      ? null
                      : (d) {
                          final sx = c.maxWidth / worldW, sy = c.maxHeight / worldH;
                          for (final i in incidents) {
                            final dx = i.x * sx - d.localPosition.dx, dy = i.y * sy - d.localPosition.dy;
                            if (dx * dx + dy * dy < 22 * 22) {
                              onIncidentTap!(i.id);
                              return;
                            }
                          }
                        },
                  child: CustomPaint(
                    size: Size(c.maxWidth, c.maxHeight),
                    painter: _MapPainter(
                      locations: store.locations,
                      incidents: incidents,
                      responders: store.responders.values.toList(),
                      focus: focus,
                      store: store,
                    ),
                  ),
                );
              }),
            ),
          ),
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
              child: const Text('LBRCE DEMO MAP · SIMULATED LAYOUT',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: RgColors.amber)),
            ),
          ),
          const Positioned(right: 10, bottom: 8, child: _Legend()),
        ]),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String t) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.circle, size: 9, color: c),
            const SizedBox(width: 3),
            Text(t, style: const TextStyle(fontSize: 9.5, color: RgColors.muted)),
          ]),
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
      child: Wrap(children: [
        item(RgColors.red, 'Critical'),
        item(RgColors.orange, 'High'),
        item(RgColors.yellow, 'Medium'),
        item(RgColors.green, 'Available'),
        item(RgColors.blue, 'En route'),
      ]),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.locations,
    required this.incidents,
    required this.responders,
    required this.focus,
    required this.store,
  });
  final List<CampusLocation> locations;
  final List<Incident> incidents;
  final List<Responder> responders;
  final Incident? focus;
  final RescueStore store;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / CampusMap.worldW, sy = size.height / CampusMap.worldH;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    // Grid
    final grid = Paint()
      ..color = const Color(0xFF13223A)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= CampusMap.worldW; x += 50) {
      canvas.drawLine(p(x, 0), p(x, CampusMap.worldH), grid);
    }
    for (var y = 0.0; y <= CampusMap.worldH; y += 50) {
      canvas.drawLine(p(0, y), p(CampusMap.worldW, y), grid);
    }

    // Roads (schematic)
    final road = Paint()
      ..color = const Color(0xFF1D2F4D)
      ..strokeWidth = 14 * sx
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p(500, 700), p(500, 140), road);
    canvas.drawLine(p(100, 440), p(920, 440), road);
    canvas.drawLine(p(100, 300), p(920, 300), road);
    canvas.drawLine(p(100, 150), p(920, 150), road);

    // Buildings
    final fill = Paint()..color = const Color(0xFF1A2944);
    final stroke = Paint()
      ..color = const Color(0xFF2E4670)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final l in locations) {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(center: p(l.x, l.y), width: l.w * sx, height: l.h * sy),
        Radius.circular(6 * sx),
      );
      canvas.drawRRect(r, fill);
      canvas.drawRRect(r, stroke);
      _label(canvas, l.name, p(l.x, l.y), math.min(12.0, math.max(7.0, 9.5 * sx)), const Color(0xFF9DB0D0), maxW: l.w * sx);
    }

    // Routes
    for (final i in incidents) {
      final r = store.responderById(i.assignedResponderId);
      if (r != null && (i.status == IncidentStatus.enRoute || i.status == IncidentStatus.accepted)) {
        final route = Paint()
          ..color = RgColors.blue.withValues(alpha: focus == null || focus == i ? 0.9 : 0.35)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
        _dashed(canvas, p(r.x, r.y), p(i.x, i.y), route);
      }
    }

    // Incidents
    for (final i in incidents) {
      final c = i.severityLevel.color;
      final center = p(i.x, i.y);
      final isFocus = focus?.id == i.id;
      canvas.drawCircle(center, isFocus ? 20 : 15, Paint()..color = c.withValues(alpha: 0.22));
      canvas.drawCircle(center, isFocus ? 9 : 7, Paint()..color = c);
      canvas.drawCircle(
          center,
          isFocus ? 9 : 7,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      _label(canvas, i.id, center.translate(0, -20), 9, c);
    }

    // Responders
    for (final r in responders) {
      if (r.status == ResponderStatus.offDuty) continue;
      final color = switch (r.status) {
        ResponderStatus.available => RgColors.green,
        ResponderStatus.enRoute => RgColors.blue,
        _ => RgColors.amber,
      };
      final c = p(r.x, r.y);
      final path = Path()
        ..moveTo(c.dx, c.dy - 9)
        ..lineTo(c.dx + 8, c.dy + 6)
        ..lineTo(c.dx - 8, c.dy + 6)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
      _label(canvas, r.id, c.translate(0, 15), 8.5, color);
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    final d = b - a;
    final len = d.distance;
    if (len < 1) return;
    final dir = d / len;
    var t = 0.0;
    while (t < len) {
      final s = a + dir * t;
      final e = a + dir * (t + 7 > len ? len : t + 7);
      canvas.drawLine(s, e, paint);
      t += 12;
    }
  }

  void _label(Canvas canvas, String text, Offset at, double size, Color color, {double? maxW}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w700)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: maxW ?? 120);
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => true;
}
