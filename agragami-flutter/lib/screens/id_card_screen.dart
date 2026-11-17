import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/branch.dart';
import '../models/member.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/id_card_download.dart';
import '../services/id_card_service.dart';
import '../widgets/app_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/member_id_card.dart';
import '../widgets/not_member_gate.dart';
import '../widgets/skeleton_loader.dart';

/// সদস্যের পরিচয়পত্র — সামনে আর পেছনে, CR80 মাপে।
/// PNG নিলে স্ক্রিনে দেখা কার্ডটারই ছবি নামে (বাংলা ঠিক থাকে)।
/// PDF নিলে প্রিন্টের জন্য দুই পাতার ফাইল নামে — বাংলা
/// ঠিকভাবে আসতে assets/fonts/ ফোল্ডারে কালপুরুষ TTF লাগে,
/// না থাকলে ইংরেজি অক্ষরে লেখা হবে।
class IdCardScreen extends ConsumerStatefulWidget {
  const IdCardScreen({super.key});

  @override
  ConsumerState<IdCardScreen> createState() => _IdCardScreenState();
}

class _IdCardScreenState extends ConsumerState<IdCardScreen> {
  String? _memberId;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonCardList(),
      ),
      error: (e, _) => const EmptyState(
        icon: Icons.error_outline,
        title: 'তথ্য আনা যায়নি',
        message: 'নেট দেখে আবার চেষ্টা করুন।',
      ),
      data: (user) {
        final uid = user?.id ?? '';
        if (uid.isEmpty) {
          return const EmptyState(
            icon: Icons.badge_outlined,
            title: 'তথ্য আনা যায়নি',
            message: 'নেট দেখে আবার চেষ্টা করুন।',
          );
        }
        final membersAsync = ref.watch(
          StreamProvider<List<Member>>(
            (ref) => FirestoreService().watchMembersForUser(uid),
          ),
        );
        return membersAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: SkeletonCardList(),
          ),
          error: (e, _) => const EmptyState(
            icon: Icons.error_outline,
            title: 'তথ্য আনা যায়নি',
            message: 'নেট দেখে আবার চেষ্টা করুন।',
          ),
          data: (members) {
            final active = members.where((m) => m.active).toList();
            if (active.isEmpty) {
              return const NotMemberGate();
            }
            if (active.length == 1) {
              return _IdCardBody(memberId: active.first.id);
            }
            final chosenId = _memberId ?? active.first.id;
            final chosen = active
                .where((m) => m.id == chosenId)
                .toList(growable: false);
            final member = chosen.isEmpty ? active.first : chosen.first;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _IdCardMemberPicker(
                    members: active,
                    selectedId: member.id,
                    onChanged: (id) => setState(() => _memberId = id),
                  ),
                ),
                Expanded(child: _IdCardBody(memberId: member.id)),
              ],
            );
          },
        );
      },
    );
  }
}

/// একাধিক সমিতির সদস্য হলে কোন সমিতির কার্ড দেখবে — সেটা।
class _IdCardMemberPicker extends ConsumerWidget {
  final List<Member> members;
  final String selectedId;
  final void Function(String) onChanged;

  const _IdCardMemberPicker({
    required this.members,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(
      StreamProvider<List<Branch>>((ref) => FirestoreService().watchBranches()),
    );
    final branches = branchesAsync.valueOrNull ?? const <Branch>[];
    String branchName(String id) {
      final found = branches.where((b) => b.id == id).toList();
      return found.isEmpty ? 'সমিতি' : found.first.name;
    }

    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      decoration: const InputDecoration(
        labelText: 'কোন সমিতির কার্ড',
        prefixIcon: Icon(Icons.groups_outlined),
      ),
      items: members
          .map(
            (m) => DropdownMenuItem(
              value: m.id,
              child: Text(branchName(m.branchId)),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _IdCardBody extends ConsumerStatefulWidget {
  final String memberId;

  const _IdCardBody({required this.memberId});

  @override
  ConsumerState<_IdCardBody> createState() => _IdCardBodyState();
}

class _IdCardBodyState extends ConsumerState<_IdCardBody> {
  final _frontKey = GlobalKey();
  final _backKey = GlobalKey();
  bool _busy = false;

  Future<Uint8List?> _capturePng(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _downloadPng(Member member, bool front) async {
    if (_busy) return;
    setState(() => _busy = true);
    final bytes = await _capturePng(front ? _frontKey : _backKey);
    if (!mounted) return;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ছবি নেওয়া যায়নি — আবার চেষ্টা করুন')),
      );
      setState(() => _busy = false);
      return;
    }
    final message = await savePngBytes(
      bytes,
      'id-card-${member.id}-${front ? 'front' : 'back'}.png',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    setState(() => _busy = false);
  }

  Future<void> _downloadPdf(Member member, Branch? branch) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await IdCardService().sharePdf(member, branch);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF নেওয়া যায়নি — আবার চেষ্টা করুন')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(
      StreamProvider<Member?>(
        (ref) => FirestoreService().watchMember(widget.memberId),
      ),
    );
    final branchesAsync = ref.watch(
      StreamProvider<List<Branch>>(
        (ref) => FirestoreService().watchBranches(),
      ),
    );
    return memberAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonCardList(),
      ),
      error: (e, _) => const EmptyState(
        icon: Icons.error_outline,
        title: 'কার্ড আনা যায়নি',
        message: 'নেট দেখে আবার চেষ্টা করুন।',
      ),
      data: (member) {
        if (member == null) {
          return const EmptyState(
            icon: Icons.badge_outlined,
            title: 'সদস্যের তথ্য পাওয়া যায়নি',
            message: 'অ্যাডমিনের সাথে যোগাযোগ করুন।',
          );
        }
        final branches = branchesAsync.valueOrNull ?? const <Branch>[];
        final found =
            branches.where((b) => b.id == member.branchId).toList();
        final branch = found.isEmpty ? null : found.first;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: idCardAspectRatio,
                child: RepaintBoundary(
                  key: _frontKey,
                  child: MemberIdCardFront(member: member, branch: branch),
                ),
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: idCardAspectRatio,
                child: RepaintBoundary(
                  key: _backKey,
                  child: MemberIdCardBack(member: member),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'সামনের ছবি নামান (PNG)',
                onPressed: _busy ? null : () => _downloadPng(member, true),
                icon: Icons.image_outlined,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'পেছনের ছবি নামান (PNG)',
                onPressed: _busy ? null : () => _downloadPng(member, false),
                icon: Icons.image_outlined,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'PDF হিসেবে নিন',
                onPressed: _busy ? null : () => _downloadPdf(member, branch),
              ),
              const SizedBox(height: 12),
              const Text(
                'PDF-এ বাংলা ঠিকভাবে আসতে কালপুরুষ ফন্টের ফাইল '
                'assets/fonts/ ফোল্ডারে রাখতে হয়। PNG নিলে বাংলা সবসময় ঠিক থাকে।',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
