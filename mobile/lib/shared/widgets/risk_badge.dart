import 'package:flutter/material.dart';
import '../../core/constants/risk_level.dart';

class RiskBadge extends StatelessWidget {
  final RiskLevel level;
  final bool large;

  const RiskBadge({super.key, required this.level, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: level.backgroundColor,
        borderRadius: BorderRadius.circular(large ? 12 : 8),
        border: Border.all(color: level.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(level.icon, color: level.color, size: large ? 20 : 16),
          const SizedBox(width: 6),
          Text(
            'Riesgo ${level.label}',
            style: TextStyle(
              color: level.color,
              fontWeight: FontWeight.w600,
              fontSize: large ? 15 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
