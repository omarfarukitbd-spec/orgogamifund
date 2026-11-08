import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../models/branch.dart';
import '../models/payment_method.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';
import 'payment_methods/method_form_dialog.dart';

/// পেমেন্ট মাধ্যম পরিচালনা — এইচটিএমএল প্রিভিউয়ের মতো সুইচ টগল ও কার্ড।
class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  Future<void> _run(
    BuildContext context,
    Future<void> Function() work,
    String doneMessage,
  ) async {
    try {
      await work();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(doneMessage)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('কাজটি হয়নি — আবার চেষ্টা করুন')),
        );
      }
    }
  }

  void _openForm(
    BuildContext context,
    List<Branch> branches, {
    PaymentMethodConfig? existing,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => MethodFormDialog(
        branches: branches,
        existing: existing,
      ),
    );
  }

  String _shortCode(PaymentMethodConfig m) {
    final lower = m.name.toLowerCase();
    if (lower.contains('বিকাশ') || lower.contains('bkash')) return 'ব';
    if (lower.contains('নগদ') || lower.contains('nagad')) return 'ন';
    if (lower.contains('রকেট') || lower.contains('rocket')) return 'র';
    if (lower.contains('উপায়') || lower.contains('upay')) return 'উ';
    return m.type == PaymentMethodType.bank ? 'ব্যা' : 'ন';
  }

  Color _badgeBg(PaymentMethodConfig m) {
    final lower = m.name.toLowerCase();
    if (lower.contains('বিকাশ') || lower.contains('bkash')) {
      return const Color(0xFFFDEBF2);
    }
    if (lower.contains('নগদ') || lower.contains('nagad')) {
      return const Color(0xFFFDF0E6);
    }
    return AppColors.greenSoft;
  }

  Color _badgeFg(PaymentMethodConfig m) {
    final lower = m.name.toLowerCase();
    if (lower.contains('বিকাশ') || lower.contains('bkash')) {
      return const Color(0xFFD12053);
    }
    if (lower.contains('নগদ') || lower.contains('nagad')) {
      return const Color(0xFFE65100);
    }
    return AppColors.green;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(firestoreServiceProvider);
    final userAsync = ref.watch(currentUserProvider);
    final isAdmin = userAsync.valueOrNull?.isAdmin ?? false;
    final methods = ref.watch(
      StreamProvider((ref) => store.watchAllPaymentMethods()),
    );
    final branches = ref.watch(
      StreamProvider<List<Branch>>((ref) => store.watchBranches()),
    );
    final branchList = branches.valueOrNull ?? const <Branch>[];

    if (!isAdmin) {
      return const EmptyState(
        icon: Icons.lock_outlined,
        title: 'এই পাতা শুধু অ্যাডমিন দেখতে পারেন',
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(AppStrings.navPaymentMethods),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(context, branchList),
        icon: const Icon(Icons.add_outlined),
        label: const Text('নতুন মাধ্যম যোগ করুন'),
      ),
      body: methods.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonCardList(),
        ),
        error: (e, _) => const EmptyState(
          icon: Icons.error_outline,
          title: 'তালিকা আনা যায়নি',
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.account_balance_outlined,
              title: 'এখনো কোনো পেমেন্ট মাধ্যম যোগ করা হয়নি',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final m = list[i];
              final scope = m.branchId == null
                  ? 'সব সমিতি'
                  : branchList
                          .where((b) => b.id == m.branchId)
                          .map((b) => b.name)
                          .firstOrNull ??
                      'সমিতি';
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _badgeBg(m),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _shortCode(m),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _badgeFg(m),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    m.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PillTag(
                                    text: m.isActive ? 'চালু' : 'বন্ধ',
                                    backgroundColor: m.isActive
                                        ? AppColors.greenSoft
                                        : const Color(0xFFECEFEC),
                                    textColor: m.isActive
                                        ? AppColors.green
                                        : AppColors.muted,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${m.accountNumber} • ${m.accountHolderName}',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${m.typeLabel} • $scope',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: m.isActive,
                          activeThumbColor: AppColors.green,
                          onChanged: (val) async {
                            final by = AuthService().uidOrEmpty;
                            await _run(
                              context,
                              () => store.setPaymentMethodActive(
                                m.id,
                                active: val,
                                by: by,
                                methodName: m.name,
                              ),
                              val
                                  ? 'মাধ্যম চালু করা হয়েছে'
                                  : 'মাধ্যম বন্ধ করা হয়েছে',
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () =>
                              _openForm(context, branchList, existing: m),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('বদলান'),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'নম্বর কপি করুন',
                          icon: const Icon(Icons.copy_outlined, size: 18),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: m.accountNumber),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('নম্বর কপি হয়েছে'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
