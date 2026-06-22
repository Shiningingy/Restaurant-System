import 'package:flutter/material.dart';

/// A compact status chip: an icon **and** a text label on a tinted pill.
///
/// Status on the POS is never colour-only (it runs on bright counters, and for
/// accessibility) — every state pairs a [Material Symbol] with a word. Colours
/// come from the caller (usually the [PosStatusColors] tokens or the scheme).
class StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  const StatusPill({
    super.key,
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
