import 'package:flutter/material.dart';

/// Compact icon button without the default 48×48 hit area of [IconButton].
/// Used across admin pages so action rows stay narrow on tight viewports.
class CompactIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  const CompactIcon(
    this.icon, {
    super.key,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: size, color: color ?? Colors.black54),
        ),
      ),
    );
  }
}
