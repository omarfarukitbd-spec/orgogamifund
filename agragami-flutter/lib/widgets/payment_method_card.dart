import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/payment_method.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// পেমেন্ট মাধ্যমের কার্ড — জমা আর কিস্তি, দুই জায়গায় একই চেহারা।
/// বাছা মাধ্যমের বর্ডার সবুজ, পটভূমি হালকা সবুজ; বাকিগুলোর
/// বর্ডার হালকা ধূসর। নম্বরের পাশে কপি বোতাম।
class PaymentMethodCard extends StatelessWidget {
  final PaymentMethodConfig method;
  final bool selected;
  final VoidCallback onTap;

  const PaymentMethodCard({
    super.key,
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = switch (method.type) {
      PaymentMethodType.mobileBanking => Icons.phone_android_outlined,
      PaymentMethodType.bank => Icons.account_balance_outlined,
      PaymentMethodType.cash => Icons.payments_outlined,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.greenTint : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.green : AppColors.line,
              width: 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListIcon(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${method.typeLabel} • ${method.accountHolderName}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'নম্বর: ${method.accountNumber}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'নম্বর কপি করুন',
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: method.accountNumber),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('নম্বর কপি হয়েছে'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_outlined, size: 20),
                        ),
                      ],
                    ),
                    if (method.instructions != null &&
                        method.instructions!.isNotEmpty)
                      Text(
                        method.instructions!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              RadioGroup<String?>(
                groupValue: selected ? method.id : null,
                onChanged: (_) => onTap(),
                child: Radio<String?>(
                  value: method.id,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
