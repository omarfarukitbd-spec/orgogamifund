import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_strings.dart';
import '../models/branch.dart';
import '../models/membership.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/not_member_gate.dart';
import '../widgets/skeleton_loader.dart';

/// সমিতির তালিকা — লগইন করা যে কেউ দেখতে পায়।
/// এখানে শুধু সবার জন্য খোলা তথ্য থাকে: নাম, উদ্দেশ্য,
/// মাসিক দান আর অনুমোদিত সদস্যের সংখ্যা।
/// সদস্য কে কে, সমিতিতে কত টাকা আছে, কে জমা দিলো —
/// এগুলো এখানে আসে না; ওগুলো শুধু ওই সমিতির সদস্যরাই
/// বিস্তারিত পাতায় দেখতে পায়।
///
/// তালিকা আনার পথটা নাম দিয়ে রাখা হয়েছে, যাতে ভুল হলে
/// "আবার চেষ্টা করুন" বোতামটা সত্যিই আবার আনতে পারে।
final branchesProvider = StreamProvider<List<Branch>>(
  (ref) => FirestoreService().watchBranches(),
);

class SamitiListScreen extends ConsumerWidget {
  const SamitiListScreen({super.key});

  void _openCreateSamiti(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const _CreateSamitiDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesProvider);
    final userAsync = ref.watch(currentUserProvider);
    final membershipsAsync = ref.watch(myMembershipsProvider);
    final isAdmin = userAsync.valueOrNull?.isAdmin ?? false;

    return Scaffold(
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              onPressed: () => _openCreateSamiti(context),
              icon: const Icon(Icons.add),
              label: const Text(AppStrings.createSamiti),
            )
          : null,
      body: branchesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonCardList(),
        ),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'তালিকা আনা যায়নি',
          message: 'ইন্টারনেট দেখে আবার চেষ্টা করুন।',
          actionLabel: AppStrings.tryAgain,
          onAction: () => ref.invalidate(branchesProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.groups_outlined,
              title: AppStrings.samitiEmptyTitle,
              message: isAdmin
                  ? AppStrings.samitiEmptyAdminBody
                  : AppStrings.samitiEmptyBody,
              actionLabel: isAdmin ? AppStrings.createSamiti : null,
              onAction:
                  isAdmin ? () => _openCreateSamiti(context) : null,
            );
          }
          final memberships =
              membershipsAsync.valueOrNull ?? const <Membership>[];
          Membership? membershipFor(String branchId) {
            final found =
                memberships.where((m) => m.branchId == branchId).toList();
            return found.isEmpty ? null : found.first;
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final b = list[i];
              final m = membershipFor(b.id);
              return AppCard(
                onTap: () => context.go('/samiti/${b.id}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            b.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const Icon(Icons.chevron_right_outlined),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(samitiPurposeText(b.purpose)),
                    if (b.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(b.description),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${AppStrings.monthlyDonation}: ৳${b.monthlyDonation}'
                      '  •  ${AppStrings.memberCountLabel}: ${b.memberCount} জন',
                    ),
                    const SizedBox(height: 12),
                    if (isAdmin)
                      const _StateChip(
                        label: 'অ্যাডমিন',
                        color: Colors.green,
                      )
                    else if (m?.isApproved ?? false)
                      const _StateChip(
                        label: AppStrings.alreadyMember,
                        color: Colors.green,
                      )
                    else if (m?.isPending ?? false)
                      const _StateChip(
                        label: AppStrings.applicationPending,
                        color: Colors.amber,
                      )
                    else if (m?.isRejected ?? false)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(AppStrings.applicationRejected),
                          const SizedBox(height: 8),
                          SecondaryButton(
                            label: AppStrings.joinSamiti,
                            onPressed: () =>
                                context.go('/apply?branchId=${b.id}'),
                          ),
                        ],
                      )
                    else
                      SecondaryButton(
                        label: AppStrings.joinSamiti,
                        onPressed: () =>
                            context.go('/apply?branchId=${b.id}'),
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

class _StateChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StateChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

/// নতুন সমিতি খোলার ফরম — শুধু অ্যাডমিন দেখতে পায়।
/// নাম, উদ্দেশ্য আর মাসিক দান বসালেই সমিতি তৈরি হয়।
class _CreateSamitiDialog extends StatefulWidget {
  const _CreateSamitiDialog();

  @override
  State<_CreateSamitiDialog> createState() => _CreateSamitiDialogState();
}

class _CreateSamitiDialogState extends State<_CreateSamitiDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _donationController = TextEditingController();
  SamitiPurpose _purpose = SamitiPurpose.madrasa;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _donationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await FirestoreService().createBranch(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        purpose: _purpose,
        monthlyDonation: int.parse(_donationController.text.trim()),
        by: AuthService().uidOrEmpty,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.samitiCreated)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.samitiCreateFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.createSamiti),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: AppStrings.samitiNameLabel,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'নাম লিখুন' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<SamitiPurpose>(
                initialValue: _purpose,
                decoration: const InputDecoration(
                  labelText: AppStrings.samitiPurposeLabel,
                ),
                items: SamitiPurpose.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(samitiPurposeText(p)),
                      ),
                    )
                    .toList(),
                onChanged: (p) {
                  if (p != null) setState(() => _purpose = p);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _donationController,
                decoration: const InputDecoration(
                  labelText: AppStrings.monthlyDonation,
                  suffixText: '৳',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'পরিমাণ লিখুন';
                  if (int.tryParse(v.trim()) == null) {
                    return 'শুধু সংখ্যা লিখুন';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: AppStrings.samitiDescriptionLabel,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('বাতিল'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'খোলা হচ্ছে…' : AppStrings.createSamiti),
        ),
      ],
    );
  }
}
