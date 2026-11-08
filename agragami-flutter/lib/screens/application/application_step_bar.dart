import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// আবেদনের ধাপের নির্দেশক
class ApplicationStepBar extends StatelessWidget {
  final int step; // 0, 1, 2

  const ApplicationStepBar({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    const labels = ['তথ্য', 'ছবি', 'যাচাই'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            _stepItem(i + 1, labels[i], i <= step, i == step),
            if (i < labels.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: i < step ? AppColors.green : AppColors.line,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _stepItem(int number, String label, bool done, bool active) {
    final bg = active
        ? AppColors.green
        : (done ? AppColors.greenSoft : AppColors.line);
    final fg = active
        ? Colors.white
        : (done ? AppColors.green : AppColors.muted);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.ink : AppColors.muted,
          ),
        ),
      ],
    );
  }
}
