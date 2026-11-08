import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_strings.dart';
import '../models/branch.dart';
import '../models/payment_method.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';

/// পেমেন্ট মাধ্যম — অ্যাডমিনের পাতা।
/// নতুন মাধ্যম যোগ করা, পুরোনোটা বদলানো, চালু/বন্ধ করা — সব এখানে।
/// বন্ধ করলেও আগের জমার হিসাব মুছে না, শুধু নতুন জমায়
/// ওই মাধ্যম আর দেখা যায় না। মুছে ফেলার বোতাম রাখা হয়নি,
/// যাতে ভুলে কোনো মাধ্যমের হিসাব হারিয়ে না যায়।
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

  Future<bool> _askConfirm(BuildContext context, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('নিশ্চিত করুন'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('হ্যাঁ'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _openForm(
    BuildContext context,
    WidgetRef ref,
    List<Branch> branches, {
    PaymentMethodConfig? existing,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => _MethodFormDialog(
        branches: branches,
        existing: existing,
      ),
    );
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
        onPressed: () => _openForm(context, ref, branchList),
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
            padding: const EdgeInsets.all(16),
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
                      children: [
                        Expanded(
                          child: Text(
                            m.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: m.isActive
                                ? Colors.green.shade100
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            m.isActive ? 'চালু' : 'বন্ধ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: m.isActive
                                  ? Colors.green.shade800
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${m.typeLabel} • $scope',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'নম্বর: ${m.accountNumber}'
                            '${m.accountHolderName.isEmpty ? '' : ' (${m.accountHolderName})'}',
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
                              ClipboardData(text: m.accountNumber),
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
                    if (m.instructions != null && m.instructions!.isNotEmpty)
                      Text(
                        m.instructions!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _openForm(context, ref, branchList, existing: m),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('বদলান'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final ok = await _askConfirm(
                                  context,
                                  m.isActive
                                      ? '${m.name} বন্ধ করলে সদস্যরা নতুন জমায় আর এই মাধ্যম দেখতে পাবে না। আগের জমার হিসাব ঠিক থাকবে। বন্ধ করবেন?'
                                      : '${m.name} আবার চালু করবেন?',
                                );
                                if (!ok || !context.mounted) return;
                                final by = AuthService().uidOrEmpty;
                                await _run(
                                  context,
                                  () => store.setPaymentMethodActive(
                                    m.id,
                                    active: !m.isActive,
                                    by: by,
                                    methodName: m.name,
                                  ),
                                  m.isActive
                                      ? 'মাধ্যম বন্ধ করা হয়েছে'
                                      : 'মাধ্যম চালু করা হয়েছে',
                                );
                              },
                              icon: Icon(
                                m.isActive
                                    ? Icons.pause_circle_outlined
                                    : Icons.play_circle_outlined,
                                size: 18,
                              ),
                              label: Text(m.isActive ? 'বন্ধ করুন' : 'চালু করুন'),
                            ),
                          ),
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

/// মাধ্যম যোগ/বদলানোর ফরম — ডায়ালগে খোলে।
class _MethodFormDialog extends ConsumerStatefulWidget {
  final List<Branch> branches;
  final PaymentMethodConfig? existing;

  const _MethodFormDialog({required this.branches, this.existing});

  @override
  ConsumerState<_MethodFormDialog> createState() => _MethodFormDialogState();
}

class _MethodFormDialogState extends ConsumerState<_MethodFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _accountNumber;
  late final TextEditingController _holderName;
  late final TextEditingController _instructions;
  late final TextEditingController _sortOrder;
  PaymentMethodType _type = PaymentMethodType.mobileBanking;
  String? _branchId;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _accountNumber = TextEditingController(text: e?.accountNumber ?? '');
    _holderName = TextEditingController(text: e?.accountHolderName ?? '');
    _instructions = TextEditingController(text: e?.instructions ?? '');
    _sortOrder =
        TextEditingController(text: e == null ? '0' : '${e.sortOrder}');
    _type = e?.type ?? PaymentMethodType.mobileBanking;
    _branchId = e?.branchId;
  }

  @override
  void dispose() {
    _name.dispose();
    _accountNumber.dispose();
    _holderName.dispose();
    _instructions.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'মাধ্যমের নাম লিখুন (যেমন: বিকাশ)');
      return;
    }
    if (_accountNumber.text.trim().isEmpty) {
      setState(() => _error = 'অ্যাকাউন্ট নম্বর লিখুন');
      return;
    }
    if (_type != PaymentMethodType.cash && _holderName.text.trim().isEmpty) {
      setState(() => _error = 'অ্যাকাউন্টের নাম লিখুন');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final store = ref.read(firestoreServiceProvider);
      final by = AuthService().uidOrEmpty;
      final existing = widget.existing;
      if (existing == null) {
        final method = PaymentMethodConfig(
          id: '',
          name: _name.text.trim(),
          type: _type,
          accountNumber: _accountNumber.text.trim(),
          accountHolderName: _holderName.text.trim(),
          branchId: _branchId,
          isActive: true,
          sortOrder: int.tryParse(_sortOrder.text.trim()) ?? 0,
          instructions: _instructions.text.trim().isEmpty
              ? null
              : _instructions.text.trim(),
          createdBy: by,
          createdAt: DateTime.now(),
        );
        await store.addPaymentMethod(method, createdBy: by);
      } else {
        final updated = PaymentMethodConfig(
          id: existing.id,
          name: _name.text.trim(),
          type: _type,
          accountNumber: _accountNumber.text.trim(),
          accountHolderName: _holderName.text.trim(),
          branchId: _branchId,
          isActive: existing.isActive,
          sortOrder: int.tryParse(_sortOrder.text.trim()) ?? 0,
          instructions: _instructions.text.trim().isEmpty
              ? null
              : _instructions.text.trim(),
          createdBy: existing.createdBy,
          createdAt: existing.createdAt,
        );
        await store.updatePaymentMethod(updated, updatedBy: by);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existing == null
                ? 'পেমেন্ট মাধ্যম যোগ করা হয়েছে'
                : 'পেমেন্ট মাধ্যম বদলানো হয়েছে',
          ),
        ),
      );
    } catch (_) {
      setState(() => _error = 'সংরক্ষণ করা যায়নি — আবার চেষ্টা করুন');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'নতুন পেমেন্ট মাধ্যম' : 'মাধ্যম বদলান',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'নাম (যেমন: বিকাশ, নগদ, রকেট)',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PaymentMethodType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'ধরন'),
              items: PaymentMethodType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(
                        switch (t) {
                          PaymentMethodType.mobileBanking =>
                            'মোবাইল ব্যাংকিং',
                          PaymentMethodType.bank => 'ব্যাংক',
                          PaymentMethodType.cash => 'নগদ টাকা',
                        },
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accountNumber,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'অ্যাকাউন্ট নম্বর',
                prefixIcon: Icon(Icons.numbers_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _holderName,
              decoration: const InputDecoration(
                labelText: 'অ্যাকাউন্টের নাম',
                prefixIcon: Icon(Icons.person_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _branchId,
              decoration: const InputDecoration(
                labelText: 'কোন সমিতির জন্য',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('সব সমিতি'),
                ),
                for (final b in widget.branches)
                  DropdownMenuItem<String?>(
                    value: b.id,
                    child: Text(b.name),
                  ),
              ],
              onChanged: (v) => setState(() => _branchId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instructions,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'নির্দেশনা (ঐচ্ছিক)',
                hintText: 'যেমন: সেন্ড মানি করুন, রেফারেন্সে নাম লিখুন',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sortOrder,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'দেখানোর ক্রম (ছোট সংখ্যা আগে দেখাবে)',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        PrimaryButton(
          label: _busy ? AppStrings.loading : AppStrings.save,
          onPressed: _busy ? null : _save,
        ),
      ],
    );
  }
}
