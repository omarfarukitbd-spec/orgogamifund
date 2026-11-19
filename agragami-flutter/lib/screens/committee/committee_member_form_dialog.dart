import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../models/branch.dart';
import '../../models/committee_member.dart';
import '../../models/member.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/firebase_errors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

/// কমিটির পদ — দায়িত্বের তালিকা।
const committeeDesignations = [
  'সভাপতি',
  'সহ-সভাপতি',
  'সম্পাদক',
  'কোষাধ্যক্ষ',
  'সদস্য',
];

/// কমিটিতে দায়িত্বশীল যোগ/বদলানোর ফরম (M4)।
/// সমিতি বেছে নিলে ওই সমিতির সদস্যদের মধ্যে থেকে
/// একজনকে পদ দেওয়া যায়। শুধু সুপার অ্যাডমিন করতে পারে
/// (rules: committee লেখা শুধু সুপার অ্যাডমিন)।
class CommitteeMemberFormDialog extends ConsumerStatefulWidget {
  final List<Branch> branches;
  final CommitteeMember? existing;

  const CommitteeMemberFormDialog({
    super.key,
    required this.branches,
    this.existing,
  });

  @override
  ConsumerState<CommitteeMemberFormDialog> createState() =>
      _CommitteeMemberFormDialogState();
}

class _CommitteeMemberFormDialogState
    extends ConsumerState<CommitteeMemberFormDialog> {
  String? _branchId;
  String? _memberId;
  String _designation = committeeDesignations.last;
  DateTime? _termStart;
  DateTime? _termEnd;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _branchId = e.branchId;
      _memberId = e.memberId;
      // F21: আসল পদটাই থাকে — তালিকায় না থাকা পদ
      // "সদস্য"-এ বদলে যায় না।
      _designation = e.designation;
      _termStart = e.termStart;
      _termEnd = e.termEnd;
    }
  }

  Future<DateTime?> _pickDate(DateTime? initial) {
    return showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
  }

  Future<void> _save() async {
    if (_branchId == null) {
      setState(() => _error = 'কোন সমিতি, বেছে নিন');
      return;
    }
    if (_memberId == null) {
      setState(() => _error = 'কাকে দায়িত্ব দিচ্ছেন, বেছে নিন');
      return;
    }
    if (_termStart != null &&
        _termEnd != null &&
        _termEnd!.isBefore(_termStart!)) {
      setState(() => _error = 'মেয়াদ শেষের তারিখ শুরুর আগে হতে পারে না');
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
      final member = CommitteeMember(
        id: existing?.id ?? '',
        memberId: _memberId!,
        designation: _designation,
        branchId: _branchId,
        termStart: _termStart,
        termEnd: _termEnd,
      );
      if (existing == null) {
        await store.addCommitteeMember(member, by: by);
      } else {
        await store.updateCommitteeMember(member, by: by);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? 'কমিটিতে যোগ করা হয়েছে'
                : 'কমিটির দায়িত্ব বদলানো হয়েছে',
          ),
        ),
      );
    } catch (e) {
      // F14: await-এর পর setState-এর আগে mounted দেখা হয়।
      if (!mounted) return;
      setState(
        () => _error = firebaseErrorMessage(
          e,
          fallback: 'সংরক্ষণ করা যায়নি — আবার চেষ্টা করুন',
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _dateTile(String label, DateTime? date, VoidCallback onTap) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const ListIcon(icon: Icons.calendar_today_outlined),
        title: Text(
          date == null
              ? '$label (ঐচ্ছিক)'
              : '$label: ${date.day}/${date.month}/${date.year}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (date != null)
              IconButton(
                icon: const Icon(Icons.clear_outlined, size: 20),
                onPressed: () => setState(() {
                  if (label.contains('শুরু')) {
                    _termStart = null;
                  } else {
                    _termEnd = null;
                  }
                }),
              ),
            const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = _branchId == null
        ? const AsyncValue<List<Member>>.data([])
        : ref.watch(activeMembersByBranchProvider(_branchId!));
    final members = membersAsync.valueOrNull ?? const <Member>[];
    final memberIds = members.map((m) => m.id).toSet();
    final effectiveMemberId =
        _memberId != null && memberIds.contains(_memberId) ? _memberId : null;

    return AlertDialog(
      title: Text(
        widget.existing == null ? 'কমিটিতে যোগ করুন' : 'কমিটির দায়িত্ব বদলান',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _branchId,
              decoration: const InputDecoration(
                labelText: 'কোন সমিতি',
                prefixIcon: Icon(Icons.groups_outlined),
              ),
              items: widget.branches
                  .map(
                    (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() {
                _branchId = v;
                _memberId = null;
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: effectiveMemberId,
              decoration: const InputDecoration(
                labelText: 'কাকে দায়িত্ব দিচ্ছেন',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              items: members
                  .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
                  .toList(),
              onChanged: _branchId == null
                  ? null
                  : (v) => setState(() => _memberId = v),
            ),
            if (_branchId != null && members.isEmpty) ...[
              const SizedBox(height: 6),
              const Text(
                'এই সমিতিতে এখনো কোনো সদস্য নেই — আগে সদস্য অনুমোদন করুন',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _designation,
              decoration: const InputDecoration(labelText: 'পদ'),
              // F21: আসল পদ তালিকায় না থাকলে সেটাও
              // আইটেম হিসেবে থাকে — না বাছলে আসলটাই লেখা হয়।
              items: [
                ...committeeDesignations,
                if (!committeeDesignations.contains(_designation))
                  _designation,
              ]
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _designation = v);
              },
            ),
            const SizedBox(height: 12),
            _dateTile('মেয়াদ শুরু', _termStart, () async {
              final picked = await _pickDate(_termStart);
              if (picked != null) setState(() => _termStart = picked);
            }),
            const SizedBox(height: 12),
            _dateTile('মেয়াদ শেষ', _termEnd, () async {
              final picked = await _pickDate(_termEnd);
              if (picked != null) setState(() => _termEnd = picked);
            }),
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
          child: Text(AppStrings.cancel),
        ),
        PrimaryButton(
          label: _busy ? AppStrings.loading : AppStrings.save,
          onPressed: _busy ? null : _save,
        ),
      ],
    );
  }
}
