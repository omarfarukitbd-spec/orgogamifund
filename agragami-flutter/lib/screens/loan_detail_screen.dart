import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../models/loan.dart';
import '../models/member.dart';
import '../models/membership.dart';
import '../models/payment_method.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/date_parser.dart';
import '../utils/firebase_errors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/not_member_gate.dart';
import '../widgets/skeleton_loader.dart';
import 'loans/edit_loan_dialog.dart';
import 'loans/loan_repayment_form.dart';
import 'loans/loan_repayments_ledger.dart';
import 'passbook_screen.dart';

/// ঋণের বিস্তারিত স্ক্রিন — ঋণ স্থিতি, কিস্তি পরিশোধ ও কিস্তির খাতা।
class LoanDetailScreen extends ConsumerWidget {
  final String loanId;

  const LoanDetailScreen({super.key, required this.loanId});

  Future<void> _deleteLoan(
    BuildContext context,
    WidgetRef ref,
    Loan loan,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ঋণ মুছবেন?'),
        content: Text(
          '${formatTaka(loan.amount)}-এর এই ঋণটি মুছে যাবে। এই কাজ ফিরিয়ে নেওয়া যাবে না।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('মুছুন', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(firestoreServiceProvider).deleteLoan(
            loan.id,
            by: AuthService().uidOrEmpty,
          );
      if (!context.mounted) return;
      invalidateTotals(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ঋণ মুছা হয়েছে')),
      );
      context.goNamed('loans');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            firebaseErrorMessage(e, fallback: 'ঋণ মুছা যায়নি — আবার চেষ্টা করুন'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanAsync = ref.watch(loanStreamProvider(loanId));
    final userAsync = ref.watch(currentUserProvider);
    final membershipsAsync = ref.watch(myMembershipsProvider);
    final isAdmin = userAsync.valueOrNull?.isAdmin ?? false;
    // F6: "ঋণ মুছুন" শুধু সুপার অ্যাডমিন দেখে।
    final isSuperAdmin = userAsync.valueOrNull?.isSuperAdmin ?? false;
    final myBranchIds = approvedBranchIds(
      membershipsAsync.valueOrNull ?? const <Membership>[],
    );

    return loanAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonCardList(),
      ),
      error: (e, _) {
        if (e is FirebaseException && e.code == 'permission-denied') {
          return const NotMemberGate();
        }
        return EmptyState(
          icon: Icons.error_outline,
          title: 'তথ্য আনা যায়নি',
          message: 'নেট দেখে আবার চেষ্টা করুন।',
          actionLabel: AppStrings.tryAgain,
          onAction: () => ref.invalidate(loanStreamProvider(loanId)),
        );
      },
      data: (loan) {
        if (loan == null) {
          return const EmptyState(
            icon: Icons.handshake_outlined,
            title: 'ঋণটি পাওয়া যায়নি',
            message: 'তালিকা থেকে আবার খুলে দেখুন।',
          );
        }
        if (!isAdmin && !myBranchIds.contains(loan.branchId)) {
          return NotMemberGate(branchId: loan.branchId);
        }
        // সদস্যের নাম সক্রিয় সদস্যদের মধ্যে খোঁজা হয় (F3)।
        final membersAsync =
            ref.watch(activeMembersByBranchProvider(loan.branchId));
        final members = membersAsync.valueOrNull ?? const <Member>[];
        final found = members.where((m) => m.id == loan.memberId).toList();
        final name = found.isEmpty ? '—' : found.first.name;
        final isRepaid = loan.status == LoanStatus.repaid;
        // F31: মেয়াদ পেরোনো কি না পড়ার সময় হিসাব হয়।
        final isOverdue = loan.isOverdue;

        final methodsAsync =
            ref.watch(activePaymentMethodsProvider(loan.branchId));
        final methods =
            methodsAsync.valueOrNull ?? const <PaymentMethodConfig>[];
        final loadingMethods = methodsAsync is AsyncLoading;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        PillTag(
                          text: isRepaid
                              ? 'পরিশোধিত'
                              : isOverdue
                                  ? 'মেয়াদ পার'
                                  : 'চলমান',
                          backgroundColor: isRepaid
                              ? AppColors.greenSoft
                              : isOverdue
                                  ? AppColors.danger.withValues(alpha: 0.12)
                                  : AppColors.goldSoft,
                          textColor: isRepaid
                              ? AppColors.green
                              : isOverdue
                                  ? AppColors.danger
                                  : AppColors.goldDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'কারণ: ${loan.reason}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      'তারিখ: ${isMissingDate(loan.dateIssued) ? "তারিখ নেই" : "${loan.dateIssued.day}/${loan.dateIssued.month}/${loan.dateIssued.year}"}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                    ),
                    if (loan.monthlyInstallment != null &&
                        loan.installmentMonths != null)
                      Text(
                        'পরিকল্পনা: মাসে ${formatTaka(loan.monthlyInstallment!)} করে ${loan.installmentMonths} মাসে',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.payments_outlined,
                      label: 'মোট ঋণ',
                      value: formatTaka(loan.amount),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.handshake_outlined,
                      label: 'বকেয়া ঋণ',
                      value: formatTaka(loan.outstanding),
                      isGold: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (isAdmin) ...[
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'ঋণ বদলান',
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => EditLoanDialog(loan: loan),
                        ),
                      ),
                    ),
                    // F6: "ঋণ মুছুন" শুধু সুপার অ্যাডমিন দেখে।
                    if (isSuperAdmin) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                          ),
                          // কিস্তি জমা আছে এমন ঋণ মুছা যায় না।
                          onPressed: loan.repayments.isEmpty
                              ? () => _deleteLoan(context, ref, loan)
                              : null,
                          icon: const Icon(Icons.delete_outlined, size: 18),
                          label: const Text('ঋণ মুছুন'),
                        ),
                      ),
                    ],
                  ],
                ),
                if (isSuperAdmin && loan.repayments.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'কিস্তি জমা আছে — এই ঋণ মুছা যাবে না।',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 18),
                const SectionTitle('কিস্তি জমা নিন'),
                if (isRepaid)
                  const EmptyState(
                    icon: Icons.check_circle_outlined,
                    title: 'এই ঋণ পুরো ফেরত দেওয়া হয়েছে',
                    message: 'আর কোনো কিস্তি বাকি নেই।',
                  )
                else
                  LoanRepaymentForm(
                    loan: loan,
                    methods: methods,
                    loadingMethods: loadingMethods,
                  ),
                const SizedBox(height: 14),
              ],
              const SectionTitle('কিস্তির খাতা'),
              LoanRepaymentsLedger(repayments: loan.repayments),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
