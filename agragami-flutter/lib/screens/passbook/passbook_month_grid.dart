import 'package:flutter/material.dart';
import '../../models/payment.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_parser.dart';
import '../../utils/dues.dart';
import '../passbook_screen.dart';

/// ১২ মাসের ছক — এইচটিএমএল প্রিভিউয়ের হুবহু ৩ কলামের গ্রিড।
/// পরিশোধিত (সবুজ), বকেয়া (লাল), এবং ভবিষ্যৎ (হালকা ধূসর)।
/// যোগদানের আগের মাস নিরপেক্ষ দেখায় — বকেয়া নয়।
class PassbookMonthGrid extends StatelessWidget {
  final List<Payment> payments;
  final int year;
  final DateTime? joinDate;
  final DateTime? branchStart;
  final int monthlyAmount;

  const PassbookMonthGrid({
    super.key,
    required this.payments,
    required this.year,
    this.joinDate,
    this.branchStart,
    this.monthlyAmount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // বকেয়া গোনা শুরুর মাস — যোগদান আর সমিতি শুরুর
    // মধ্যে যেটা পরে। এর আগের মাস বকেয়া নয়।
    DateTime? startMonth;
    final join = joinDate != null && !isMissingDate(joinDate!)
        ? joinDate
        : null;
    final branch = branchStart != null && !isMissingDate(branchStart!)
        ? branchStart
        : null;
    if (join != null) startMonth = join;
    if (branch != null &&
        (startMonth == null || branch.isAfter(startMonth))) {
      startMonth = branch;
    }
    final paidByMonth = paidAmountByMonth(payments: payments, year: year);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.1,
      ),
      itemCount: 12,
      itemBuilder: (context, i) {
        final month = i + 1;
        final isFuture = (year > now.year) || (year == now.year && month > now.month);
        final isPreJoin = startMonth != null &&
            (year < startMonth.year ||
                (year == startMonth.year && month < startMonth.month));
        // মাস পরিশোধিত ধরা হয় শুধু অনুমোদিত জমা মাসিক
        // পরিমাণের সমান বা বেশি হলে — আংশিক জমা আলাদা দেখায়।
        final paidAmount = paidByMonth[month] ?? 0;
        final approved = monthlyAmount > 0
            ? paidAmount >= monthlyAmount
            : paidAmount > 0;
        final partial = monthlyAmount > 0 &&
            paidAmount > 0 &&
            paidAmount < monthlyAmount;
        final pending = payments.any(
          (p) =>
              p.forMonth == month &&
              p.forYear == year &&
              p.status == PaymentStatus.pending,
        );

        final Color bg;
        final Color border;
        final Color text;
        final String statusLabel;

        if (isFuture || isPreJoin) {
          bg = AppColors.background;
          border = AppColors.line;
          text = AppColors.muted;
          statusLabel = '—';
        } else if (approved) {
          bg = AppColors.greenSoft;
          border = const Color(0xFFB7DBC6);
          text = AppColors.green;
          statusLabel = 'জমা হয়েছে';
        } else if (pending) {
          bg = AppColors.goldSoft;
          border = const Color(0xFFE8D7A3);
          text = AppColors.goldDark;
          statusLabel = 'যাচাইাধীন';
        } else if (partial) {
          bg = AppColors.goldSoft;
          border = const Color(0xFFE8D7A3);
          text = AppColors.goldDark;
          statusLabel = 'আংশিক জমা';
        } else {
          bg = const Color(0xFFFDF1F0);
          border = const Color(0xFFF3C2BE);
          text = AppColors.danger;
          statusLabel = 'বকেয়া';
        }

        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                bengaliMonths[i],
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: text,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
