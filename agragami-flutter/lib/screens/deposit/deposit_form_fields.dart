import 'package:flutter/material.dart';
import '../../models/branch.dart';
import '../../models/payment_method.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/payment_method_card.dart';
import '../passbook_screen.dart';

/// জমার মূল ফরমের ফিল্ডসমূহ
class DepositFormFields extends StatelessWidget {
  final List<Branch> branches;
  final String? effectiveBranchId;
  final ValueChanged<String?> onBranchChanged;
  final List<PaymentMethodConfig> methods;
  final bool loadingMethods;
  final String? methodId;
  final ValueChanged<String> onMethodSelected;
  final int month;
  final ValueChanged<int> onMonthChanged;
  final int year;
  final ValueChanged<int> onYearChanged;
  final TextEditingController amountController;
  final TextEditingController senderMobileController;
  final TextEditingController trxIdController;
  final String? error;
  final bool busy;
  final VoidCallback onSubmit;

  const DepositFormFields({
    super.key,
    required this.branches,
    required this.effectiveBranchId,
    required this.onBranchChanged,
    required this.methods,
    required this.loadingMethods,
    required this.methodId,
    required this.onMethodSelected,
    required this.month,
    required this.onMonthChanged,
    required this.year,
    required this.onYearChanged,
    required this.amountController,
    required this.senderMobileController,
    required this.trxIdController,
    required this.error,
    required this.busy,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final chosen = methods.where((m) => m.id == methodId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: effectiveBranchId,
          decoration: const InputDecoration(
            labelText: 'সমিতি বেছে নিন',
            prefixIcon: Icon(Icons.groups_outlined),
          ),
          items: branches
              .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
              .toList(),
          onChanged: onBranchChanged,
        ),
        const SizedBox(height: 12),
        if (effectiveBranchId != null) ...[
          Text(
            'পেমেন্ট মাধ্যম — অ্যাডমিনের তালিকা থেকে বেছে নিন',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          if (loadingMethods)
            const Center(child: CircularProgressIndicator())
          else if (methods.isEmpty)
            const EmptyState(
              icon: Icons.account_balance_outlined,
              title: 'এই সমিতির জন্য কোনো মাধ্যম যোগ করা হয়নি',
            )
          else
            ...methods.map(
              (m) => PaymentMethodCard(
                method: m,
                selected: methodId == m.id,
                onTap: () => onMethodSelected(m.id),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: month,
                  decoration: const InputDecoration(labelText: 'মাস'),
                  items: [
                    for (var m = 1; m <= 12; m++)
                      DropdownMenuItem(
                        value: m,
                        child: Text(bengaliMonths[m - 1]),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) onMonthChanged(v);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: year,
                  decoration: const InputDecoration(labelText: 'বছর'),
                  items: [
                    for (var y = DateTime.now().year - 1;
                        y <= DateTime.now().year;
                        y++)
                      DropdownMenuItem(value: y, child: Text('$y')),
                  ],
                  onChanged: (v) {
                    if (v != null) onYearChanged(v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'টাকার পরিমাণ (৳)',
              prefixText: '৳ ',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          if (chosen != null &&
              chosen.type == PaymentMethodType.mobileBanking) ...[
            const SizedBox(height: 12),
            TextField(
              controller: senderMobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'যে নম্বর থেকে পাঠিয়েছেন',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
          ],
          if (chosen != null && chosen.type != PaymentMethodType.cash) ...[
            const SizedBox(height: 12),
            TextField(
              controller: trxIdController,
              decoration: const InputDecoration(
                labelText: 'লেনদেন নম্বর (TrxID)',
                prefixIcon: Icon(Icons.receipt_outlined),
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13.5),
            ),
          ],
          const SizedBox(height: 18),
          PrimaryButton(
            label: busy ? 'পাঠানো হচ্ছে…' : 'জমা দিন',
            onPressed: busy ? null : onSubmit,
            icon: Icons.send_outlined,
          ),
        ],
      ],
    );
  }
}
