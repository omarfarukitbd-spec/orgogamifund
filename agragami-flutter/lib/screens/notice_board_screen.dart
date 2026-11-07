import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/branch.dart';
import '../models/notice.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
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
      setState(() => _error = 'ছবি নেওয়া যায়নি — আবার চেষ্টা করুন');
    }
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'নোটিশের শিরোনাম লিখুন');
      return;
    }
    if (_body.text.trim().isEmpty) {
      setState(() => _error = 'নোটিশের কথা লিখুন');
      return;
    }
    if (_scope == 'branch' && _branchId == null) {
      setState(() => _error = 'কোন সমিতির জন্য, বেছে নিন');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final notice = Notice(
        id: '',
        title: _title.text.trim(),
        body: _body.text.trim(),
        scope: _scope == 'branch' ? NoticeScope.branch : NoticeScope.org,
        branchId: _scope == 'branch' ? _branchId : null,
        postedBy: AuthService().uidOrEmpty,
        postedAt: DateTime.now(),
      );
      await FirestoreService().submitNotice(
        notice: notice,
        attachmentBytes: _attachmentBytes,
      );
      if (!mounted) return;
      setState(() {
        _writing = false;
        _title.clear();
        _body.clear();
        _attachmentBytes = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('নোটিশ দেওয়া হয়েছে')),
      );
    } catch (_) {
      setState(() => _error = 'নোটিশ দেওয়া যায়নি — নেট দেখে আবার চেষ্টা করুন');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final branchesAsync = ref.watch(
      StreamProvider<List<Branch>>((ref) => FirestoreService().watchBranches()),
    );
    final noticesAsync = ref.watch(
      StreamProvider<List<Notice>>(
        (ref) => FirestoreService().watchNotices(
          branchId: userAsync.valueOrNull?.branchId,
        ),
      ),
    );
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];
    final notices = noticesAsync.valueOrNull ?? const <Notice>[];
    final isAdmin = userAsync.valueOrNull?.isAdmin ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isAdmin && !_writing)
            ElevatedButton.icon(
              onPressed: () => setState(() => _writing = true),
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
                  DropdownButtonFormField<String>(
                    initialValue: _scope,
                    decoration: const InputDecoration(
                      labelText: 'কার জন্য',
                      prefixIcon: Icon(Icons.groups_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'org', child: Text('সবার জন্য')),
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
                      decoration: const InputDecoration(labelText: 'কোন সমিতি'),
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
          else if (notices.isEmpty)
            const EmptyState(
              icon: Icons.campaign_outlined,
              title: 'এখনো কোনো নোটিশ নেই',
              message: 'নোটিশ দিলে এখানে দেখা যাবে।',
            )
          else
            ...notices.map(
              (n) => AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.campaign_outlined),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            n.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(n.body),
                    const SizedBox(height: 6),
                    Text(
                      '${n.postedAt.day}/${n.postedAt.month}/${n.postedAt.year}'
                      ' • ${n.scope == NoticeScope.org ? 'সবার জন্য' : 'সমিতির জন্য'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
        ],
      ),
    );
  }
}
