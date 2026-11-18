import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const KpiCard({
    Key? key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color = AppTheme.autoridadNavy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.sueloBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A112B4F),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontHeading,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.datosCharcoal,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: AppTheme.fontHeading,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontBody,
                      fontSize: 10,
                      color: Color(0xFF787F86),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
