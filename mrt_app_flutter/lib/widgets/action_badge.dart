import 'package:flutter/material.dart';
import '../models/control_point.dart';
import '../theme/app_theme.dart';

class ActionBadge extends StatelessWidget {
  final ActionType action;
  final double diffCm;
  final bool compact;

  const ActionBadge({
    Key? key,
    required this.action,
    required this.diffCm,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (action) {
      case ActionType.rellenar:
        bg = const Color(0xFFE8F4FA); // Agua & Precisión suave
        fg = AppTheme.colorRellenar;  // #2376A4
        label = "RELLENAR";
        icon = Icons.arrow_upward;
        break;
      case ActionType.cortar:
        bg = const Color(0xFFFDE8E8); // Rojo rasante suave
        fg = AppTheme.colorCortar;    // #C53030
        label = "CORTAR";
        icon = Icons.arrow_downward;
        break;
      case ActionType.ok:
        bg = const Color(0xFFEAF6EC); // Naturaleza & Crecimiento suave
        fg = AppTheme.colorOk;        // #3FA34D
        label = "OK";
        icon = Icons.check_circle;
        break;
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: fg.withOpacity(0.55), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontHeading,
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.3,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontHeading,
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
