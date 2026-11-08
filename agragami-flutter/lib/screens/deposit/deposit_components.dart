import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// জমার ৩ ধাপের নির্দেশক — এইচটিএমএল প্রিভিউয়ের হুবহু রূপ।
class DepositStepsBar extends StatelessWidget {
  final int currentStep; // 1, 2, or 3

  const DepositStepsBar({super.key, this.currentStep = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stepItem(1, 'সমিতি বাছুন', currentStep >= 1),
          _stepDivider(currentStep >= 2),
          _stepItem(2, 'টাকা পাঠান', currentStep >= 2),
          _stepDivider(currentStep >= 3),
          _stepItem(3, 'জমা দিন', currentStep >= 3),
        ],
      ),
    );
  }

  Widget _stepItem(int num, String label, bool active) {
    final bg = active ? AppColors.green : AppColors.line;
    final fg = active ? Colors.white : AppColors.muted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            '$num',
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
            fontSize: 12.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? AppColors.ink : AppColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _stepDivider(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: active ? AppColors.green : AppColors.line,
      ),
    );
  }
}

/// জমা সফল হওয়ার নিশ্চিতকরণ বক্স
class DepositSuccessView extends StatelessWidget {
  final VoidCallback onViewPassbook;
  final VoidCallback onDepositAgain;

  const DepositSuccessView({
    super.key,
    required this.onViewPassbook,
    required this.onDepositAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.green,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'জমা পাঠানো হয়েছে',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'অবস্থা: ',
                      style: TextStyle(fontSize: 14.5),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'যাচাইাধীন',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'অ্যাডমিন যাচাই করে অনুমোদন করলেই রসিদ নম্বর তৈরি হবে এবং পাসবইয়ে জমা দেখা যাবে।',
                  style: TextStyle(fontSize: 14, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onViewPassbook,
            child: const Text('পাসবই দেখুন'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onDepositAgain,
            child: const Text('আরেকটি জমা দিন'),
          ),
        ],
      ),
    );
  }
}
