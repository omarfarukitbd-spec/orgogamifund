import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loan.dart';
import '../models/member.dart';
import '../models/membership.dart';
import '../models/payment_method.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/not_member_gate.dart';
import '../widgets/skeleton_loader.dart';
import 'loans/loan_repayment_form.dart';
import 'loans/loan_repayments_ledger.dart';
import 'passbook_screen.dart';

/// ঋণের বিস্তারিত স্ক্রিন — ঋণ স্থিতি, কিস্তি পরিশোধ ও কিস্তির খাতা।
class LoanDetailScreen extends ConsumerWidget {
  final String loanId;

  const LoanDetailScreen({super.key, required this.loanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanAsync = ref.watch(
      StreamProvider<Loan?>(
        (ref) => FirestoreService().watchLoan(loanId),
      ),
    );
    final userAsync = ref.watch(currentUserProvider);
    final membershipsAsync = ref.watch(myMembershipsProvider);
    final isAdmin = userAsync.valueOrNull?.isAdmin ?? false;
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
        return const EmptyState(
          icon: Icons.error_outline,
          title: 'তথ্য আনা যায়নি',
          message: 'নেট দেখে আবার চেষ্টা করুন।',
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
        final membersAsync = ref.watch(
          StreamProvider<List<Member>>(
            (ref) => FirestoreService().watchMembers(branchId: loan.branchId),
          ),
        );
        final members = membersAsync.valueOrNull ?? const <Member>[];
        final found = members.where((m) => m.id == loan.memberId).toList();
        final name = found.isEmpty ? '—' : found.first.name;
        final isRepaid = loan.status == LoanStatus.repaid;

        final methodsAsync = ref.watch(
          StreamProvider<List<PaymentMethodConfig>>(
            (ref) => FirestoreService().watchActivePaymentMethods(
              branchId: loan.branchId,
            ),
          ),
        );
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
                          text: isRepaid ? 'পরিশোধিত' : 'চলমান',
                          backgroundColor:
                              isRepaid ? AppColors.greenSoft : AppColors.goldSoft,
                          textColor:
                              isRepaid ? AppColors.green : AppColors.goldDark,
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
                      'তারিখ: ${loan.dateIssued.day}/${loan.dateIssued.month}/${loan.dateIssued.year}',
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
