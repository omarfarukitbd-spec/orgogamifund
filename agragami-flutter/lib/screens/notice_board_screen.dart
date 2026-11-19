import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/cloudinary_config.dart';
import '../l10n/app_strings.dart';
import '../models/branch.dart';
import '../models/membership.dart';
import '../models/notice.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../utils/date_parser.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_loader.dart';

/// নোটিশ বোর্ড — সবার জন্য লেখা নোটিশ আর সভার কার্যবিবরণী।
/// অ্যাডমিন বা ব্রাঞ্চ অ্যাডমিন নতুন নোটিশ লিখতে পারেন।
class NoticeBoardScreen extends ConsumerStatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  ConsumerState<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends ConsumerState<NoticeBoardScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _scope = 'org';
  String? _branchId;
  Uint8List? _attachmentBytes;
  bool _busy = false;
  bool _writing = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        setState(() => _error = 'ছবিটি ৫ MB-এর বেশি — ছোট ছবি বেছে নিন');
        return;
      }
      setState(() {
        _attachmentBytes = bytes;
        _error = null;
      });
    } catch (_) {
      // F14: await-এর পর setState-এর আগে mounted দেখা হয়।
      if (!mounted) return;
      setState(() => _error = 'ছবি নেওয়া যায়নি — আবার চেষ্টা করুন');
    }
  }

  Future<void> _sendNotice(Notice notice, Uint8List? attachmentBytes) {
    return ref.read(firestoreServiceProvider).submitNotice(
      notice: notice,
      attachmentBytes: attachmentBytes,
    );
  }

  void _onNoticeSent() {
    // ছবি দিয়েও Cloudinary সেট করা না থাকলে ছবি জমা হয়নি —
    // ব্যবহারকারীকে জানিয়ে দিই, নোটিশ তবুও দেওয়া হয়েছে।
    final attachmentSkipped =
        _attachmentBytes != null && !CloudinaryConfig.isConfigured;
    setState(() {
      _writing = false;
      _title.clear();
      _body.clear();
      _attachmentBytes = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          attachmentSkipped
              ? 'নোটিশ দেওয়া হয়েছে — তবে ছবি আপলোড হয়নি, কারণ ছবি আপলোড এখনো সেট করা হয়নি'
              : 'নোটিশ দেওয়া হয়েছে',
        ),
      ),
    );
  }

  Future<void> _submit() async {
    // Phase 8 (G5): শাখা অ্যাডমিন শুধু নিজের সমিতির নোটিশ
    // দিতে পারে — "সবার জন্য" (org) শুধু সুপার অ্যাডমিনের।
    // UI-তে বাঁধা থাকলেও এখানে আবার জোর করা হয়, যাতে
    // কোনো পথেই ভুল সমিতির নোটিশ না যায়।
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    final isBranchAdminWriter = currentUser?.isBranchAdmin ?? false;
    var scope = _scope;
    var branchId = _branchId;
    if (isBranchAdminWriter) {
      final adminBranch = currentUser?.branchId;
      if (adminBranch == null || adminBranch.isEmpty) {
        setState(
          () => _error =
              'আপনার সমিতি ঠিক করা নেই — সুপার অ্যাডমিনের সাথে যোগাযোগ করুন',
        );
        return;
      }
      scope = 'branch';
      branchId = adminBranch;
    }
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'নোটিশের শিরোনাম লিখুন');
      return;
    }
    if (_body.text.trim().isEmpty) {
      setState(() => _error = 'নোটিশের কথা লিখুন');
      return;
    }
    if (scope == 'branch' && branchId == null) {
      setState(() => _error = 'কোন সমিতির জন্য, বেছে নিন');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final notice = Notice(
      id: '',
      title: _title.text.trim(),
      body: _body.text.trim(),
      scope: scope == 'branch' ? NoticeScope.branch : NoticeScope.org,
      branchId: scope == 'branch' ? branchId : null,
      postedBy: AuthService().uidOrEmpty,
      postedAt: DateTime.now(),
    );
    try {
      await _sendNotice(notice, _attachmentBytes);
      if (!mounted) return;
      _onNoticeSent();
    } on UploadFailedException catch (_) {
      // ছবি আপলোড হয়নি — নিঃশব্দে ছবি ছাড়া পাঠানো হয় না।
      // ব্যবহারকারী চাইলে ছবি ছাড়াই পাঠাতে পারে।
      if (!mounted) return;
      final sendWithout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ছবি আপলোড হয়নি'),
          content: const Text(
            'ছবিটা আপলোড করা যায়নি। ছবি ছাড়াই নোটিশ পাঠাবেন?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('বাতিল'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('ছবি ছাড়াই পাঠান'),
            ),
          ],
        ),
      );
      if (sendWithout != true) {
        // F14: ডায়ালগের পর setState-এর আগে mounted দেখা হয়।
        if (!mounted) return;
        setState(() => _error = 'ছবি আপলোড হয়নি — আবার চেষ্টা করুন');
        return;
      }
      try {
        await _sendNotice(notice, null);
        if (!mounted) return;
        _onNoticeSent();
      } catch (_) {
        // F14: await-এর পর setState-এর আগে mounted দেখা হয়।
        if (!mounted) return;
        setState(
          () => _error = 'নোটিশ দেওয়া যায়নি — নেট দেখে আবার চেষ্টা করুন',
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'নোটিশ দেওয়া যায়নি — নেট দেখে আবার চেষ্টা করুন');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final branchesAsync = ref.watch(branchesStreamProvider);
    final membershipsAsync = ref.watch(myMembershipsProvider);
    final user = userAsync.valueOrNull;
    final isAdmin = user?.isAdmin ?? false;
    final isSuperAdmin = user?.isSuperAdmin ?? false;
    final isBranchAdmin = isAdmin && !isSuperAdmin;
    // কোন সমিতির নোটিশ দেখবে — অনুমোদিত সদস্যপদ দিয়ে ঠিক হয়,
    // users ডকুমেন্টের একটিমাত্র branchId দিয়ে নয়। একাধিক
    // সমিতির সদস্য সবগুলোর নোটিশ পায়।
    final approvedIds = isAdmin
        ? null
        : approvedBranchIds(
            membershipsAsync.valueOrNull ?? const <Membership>[],
          );
    final noticesAsync = ref.watch(noticesForBranchProvider(''));
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];
    final allNotices = noticesAsync.valueOrNull ?? const <Notice>[];
    final notices = approvedIds == null
        ? allNotices
        : allNotices
            .where(
              (n) =>
                  n.scope == NoticeScope.org ||
                  (n.branchId != null && approvedIds.contains(n.branchId)),
            )
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isAdmin && !_writing)
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _writing = true;
                // Phase 8 (G5): শাখা অ্যাডমিনের ফরম নিজের
                // সমিতিতেই বাঁধা থাকে — স্কোপ বদলানোর সুযোগ নেই।
                if (isBranchAdmin) {
                  _scope = 'branch';
                  _branchId = user?.branchId;
                }
              }),
              icon: const Icon(Icons.add_outlined),
              label: const Text('নতুন নোটিশ লিখুন'),
            ),
          if (_writing) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(
                      labelText: 'শিরোনাম',
                      prefixIcon: Icon(Icons.title_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _body,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'নোটিশের কথা',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Phase 8 (G5): "সবার জন্য" (org) শুধু সুপার
                  // অ্যাডমিন; শাখা অ্যাডমিন শুধু নিজের সমিতির
                  // নাম দেখে — ড্রপডাউন নেই।
                  if (isSuperAdmin) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _scope,
                      decoration: const InputDecoration(
                        labelText: 'কার জন্য',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'org',
                          child: Text('সবার জন্য'),
                        ),
                        DropdownMenuItem(
                          value: 'branch',
                          child: Text('একটি সমিতির জন্য'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _scope = v ?? 'org'),
                    ),
                    if (_scope == 'branch') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _branchId,
                        decoration: const InputDecoration(
                          labelText: 'কোন সমিতি',
                        ),
                        items: branches
                            .map(
                              (b) => DropdownMenuItem(
                                value: b.id,
                                child: Text(b.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _branchId = v),
                      ),
                    ],
                  ] else
                    Row(
                      children: [
                        const Icon(Icons.groups_outlined, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _branchId == null
                                ? 'আপনার সমিতি ঠিক করা নেই — সুপার অ্যাডমিনের সাথে যোগাযোগ করুন'
                                : 'সমিতি: ${branches.where((b) => b.id == _branchId).map((b) => b.name).firstOrNull ?? '—'}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color:
                                  _branchId == null ? Colors.red : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickAttachment,
                    icon: const Icon(Icons.attach_file_outlined),
                    label: Text(
                      _attachmentBytes == null
                          ? 'ছবি যোগ করুন (যদি থাকে)'
                          : 'ছবি বদলান',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: _busy ? 'আসছে…' : 'নোটিশ দিন',
                          onPressed: _busy ? null : _submit,
                          icon: Icons.send_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () => setState(() => _writing = false),
                        child: const Text('বাতিল'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (noticesAsync.isLoading)
            const SkeletonCardList()
          else if (noticesAsync.hasError)
            EmptyState(
              icon: Icons.error_outline,
              title: 'তথ্য আনা যায়নি',
              message: 'নেট দেখে আবার চেষ্টা করুন।',
              actionLabel: AppStrings.tryAgain,
              onAction: () =>
                  ref.invalidate(noticesForBranchProvider('')),
            )
          else if (notices.isEmpty)
            const EmptyState(
              icon: Icons.campaign_outlined,
              title: 'এখনো কোনো নোটিশ নেই',
              message: 'নোটিশ দিলে এখানে দেখা যাবে।',
            )
          else
            ...notices.map(
              (n) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const ListIcon(icon: Icons.campaign_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              n.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(n.body, style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 6),
                      Text(
                        '${isMissingDate(n.postedAt) ? "তারিখ নেই" : "${n.postedAt.day}/${n.postedAt.month}/${n.postedAt.year}"}'
                        ' • ${n.scope == NoticeScope.org ? 'সবার জন্য' : 'সমিতির জন্য'}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey,
                        ),
                      ),
                      if (n.attachmentUrl != null &&
                          n.attachmentUrl!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            n.attachmentUrl!,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
