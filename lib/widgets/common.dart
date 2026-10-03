import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/enums.dart';
import '../models/incident.dart';
import '../services/incident_service.dart';

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color, this.border, this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? RgColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border ?? RgColors.line),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: box),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, required this.color, this.icon, this.dense = false});
  final String text;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: dense ? 12 : 14, color: color), const SizedBox(width: 4)],
        Text(text,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: dense ? 10.5 : 12, letterSpacing: 0.6)),
      ]),
    );
  }
}

class SeverityBadge extends StatelessWidget {
  const SeverityBadge(this.level, this.score, {super.key, this.dense = false});
  final SeverityLevel level;
  final int score;
  final bool dense;
  @override
  Widget build(BuildContext context) => Pill('${level.label} — $score/100', color: level.color, dense: dense);
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key, this.dense = false});
  final IncidentStatus status;
  final bool dense;
  @override
  Widget build(BuildContext context) => Pill(status.label, color: status.color, dense: dense);
}

class ResponderStatusPill extends StatelessWidget {
  const ResponderStatusPill(this.status, {super.key, this.dense = false});
  final ResponderStatus status;
  final bool dense;
  @override
  Widget build(BuildContext context) => Pill(status.label, color: status.color, icon: Icons.circle, dense: dense);
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value, this.color = RgColors.text, this.icon});
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (icon != null) Icon(icon, size: 14, color: RgColors.muted),
          if (icon != null) const SizedBox(width: 6),
          Expanded(
            child: Text(label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: RgColors.muted, fontSize: 10.5, letterSpacing: 1.1, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(value,
            style: AppTheme.mono.copyWith(fontSize: 30, fontWeight: FontWeight.w900, color: color, height: 1.0)),
      ]),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
        child: Row(children: [
          Expanded(
            child: Text(text.toUpperCase(),
                style: const TextStyle(fontSize: 12, letterSpacing: 1.6, fontWeight: FontWeight.w800, color: RgColors.muted)),
          ),
          if (trailing != null) trailing!,
        ]),
      );
}

class DemoModeBadge extends StatelessWidget {
  const DemoModeBadge({super.key});
  @override
  Widget build(BuildContext context) {
    final demo = context.select<RescueStore, bool>((s) => s.demoMode);
    if (!demo) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(right: 12),
      child: Center(child: Pill('DEMO MODE', color: RgColors.amber, dense: true, icon: Icons.science_outlined)),
    );
  }
}

class BrandFooter extends StatelessWidget {
  const BrandFooter({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(Brand.footer,
              textAlign: TextAlign.center, style: TextStyle(color: RgColors.muted, fontSize: 11, letterSpacing: 0.4)),
        ),
      );
}

class CategoryIcon extends StatelessWidget {
  const CategoryIcon(this.category, {super.key, this.size = 44, this.color});
  final IncidentCategory category;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: (color ?? RgColors.red).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Text(category.emoji, style: TextStyle(fontSize: size * 0.48)),
      );
}

class IncidentPhoto extends StatelessWidget {
  const IncidentPhoto(this.incident, {super.key, this.height = 180});
  final Incident incident;
  final double height;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (incident.photoPath != null) {
      child = Image.file(
        File(incident.photoPath!),
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder('Photo could not be loaded'),
      );
    } else if (incident.demoPhoto) {
      child = _placeholder('DEMO PHOTO PLACEHOLDER');
    } else {
      return const SizedBox.shrink();
    }
    return ClipRRect(borderRadius: BorderRadius.circular(16), child: child);
  }

  Widget _placeholder(String label) => Container(
        height: height,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF1B2B4A), Color(0xFF3A1420)]),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(incident.category.emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: RgColors.muted, letterSpacing: 1.2, fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key, this.icon = Icons.inbox_outlined});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          Icon(icon, size: 40, color: RgColors.muted),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: RgColors.muted)),
        ]),
      );
}

/// Live pulsing dot used to signal real-time state.
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, this.color = RgColors.red, this.size = 10});
  final Color color;
  final double size;
  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => SizedBox(
        width: widget.size * 2.4,
        height: widget.size * 2.4,
        child: Stack(alignment: Alignment.center, children: [
          Container(
            width: widget.size * (1 + _c.value * 1.4),
            height: widget.size * (1 + _c.value * 1.4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: (1 - _c.value) * 0.45),
            ),
          ),
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
          ),
        ]),
      ),
    );
  }
}

void showMsg(BuildContext context, String text, {Color? color}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
}

/// Runs a store action that may throw a permission error and reports it.
void guarded(BuildContext context, void Function() action, {String? success}) {
  try {
    action();
    if (success != null) showMsg(context, success);
  } on StateError catch (e) {
    showMsg(context, e.message, color: RgColors.redDeep);
  }
}
