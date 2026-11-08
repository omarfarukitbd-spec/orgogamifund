import 'package:flutter/material.dart';

import '../models/branch.dart';
import '../models/member.dart';
import '../theme/app_theme.dart';
import 'app_icon.dart';

/// সদস্যের পরিচয়পত্র — CR80 মাপের (চওড়া : লম্বা ≈ 1.586)।
/// সামনে ছবি, নাম, সদস্য নম্বর, সমিতির নাম। পেছনে কোড,
/// জরুরি যোগাযোগ, মেয়াদ আর সইয়ের জায়গা। সবুজ-সাদা-সোনালি।
class MemberIdCardFront extends StatelessWidget {
  final Member member;
  final Branch? branch;

  const MemberIdCardFront({super.key, required this.member, this.branch});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.green,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const AgragamiLogo(size: 36, radius: 9),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'অগ্রগামী ফান্ড',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'সদস্য',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 3, color: AppColors.gold),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PhotoBox(member: member),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _Field('সদস্য নম্বর', member.id),
                        _Field('সমিতি', branch?.name ?? '—'),
                        _Field('ভর্তির তারিখ', _dateText(member.joinDate)),
                        _Field('ফোন', member.phone),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoBox extends StatelessWidget {
  final Member member;

  const _PhotoBox({required this.member});

  @override
  Widget build(BuildContext context) {
    final url = member.photoUrl;
    return Container(
      width: 88,
      height: 106,
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url.isNotEmpty
          ? Image.network(url, fit: BoxFit.cover)
          : const Icon(
              Icons.person_outlined,
              size: 44,
              color: AppColors.green,
            ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;

  const _Field(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

String _dateText(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

/// কার্ডের পেছন দিক।
class MemberIdCardBack extends StatelessWidget {
  final Member member;

  const MemberIdCardBack({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greenDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'অগ্রগামী ফান্ড',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _BackLine(
                    'জরুরি যোগাযোগ',
                    '${member.emergencyContactName} — ${member.emergencyContactPhone}',
                  ),
                  _BackLine('সদস্য নম্বর', member.id),
                  const SizedBox(height: 8),
                  const Text(
                    'এই কার্ড হারালে অফিসে জানান। কার্ডটি শুধু সদস্যের পরিচয়ের জন্য।',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const Spacer(),
                  const Row(
                    children: [
                      _SignLine('সভাপতি'),
                      SizedBox(width: 20),
                      _SignLine('সম্পাদক'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomPaint(
                    size: const Size(76, 76),
                    painter: QrPatternPainter(seed: member.id),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  member.id,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackLine extends StatelessWidget {
  final String label;
  final String value;

  const _BackLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class _SignLine extends StatelessWidget {
  final String label;

  const _SignLine(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(height: 1, color: Colors.white54),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

/// সদস্য নম্বর থেকে বানানো কোডের মতো ছক — আসল QR নয়,
/// দেখতে কোডের মতো একটা চিহ্ন। একই নম্বরে সবসময় একই ছক আসে।
class QrPatternPainter extends CustomPainter {
  final String seed;

  QrPatternPainter({required this.seed});

  List<List<bool>> _grid() {
    const size = 21;
    var hash = 7;
    for (final code in seed.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    var state = hash == 0 ? 12345 : hash;
    bool next() {
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      return state % 2 == 0;
    }

    final grid = List.generate(
      size,
      (_) => List.generate(size, (_) => next()),
    );
    // তিন কোণায় চোখের মতো বড় বর্গ।
    for (final corner in [
      (0, 0),
      (0, size - 7),
      (size - 7, 0),
    ]) {
      for (var r = 0; r < 7; r++) {
        for (var c = 0; c < 7; c++) {
          final onBorder = r == 0 || r == 6 || c == 0 || c == 6;
          final inCenter = r >= 2 && r <= 4 && c >= 2 && c <= 4;
          grid[corner.$1 + r][corner.$2 + c] = onBorder || inCenter;
        }
      }
    }
    return grid;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final grid = _grid();
    final cell = size.width / grid.length;
    final paint = Paint()..color = AppColors.ink;
    for (var r = 0; r < grid.length; r++) {
      for (var c = 0; c < grid.length; c++) {
        if (grid[r][c]) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell, r * cell, cell, cell),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant QrPatternPainter oldDelegate) =>
      oldDelegate.seed != seed;
}

/// একই নম্বর থেকে PDF-এ আঁকার জন্য ছক বানানো — উইজেটের মতোই।
List<List<bool>> qrPatternGrid(String seed) {
  return QrPatternPainter(seed: seed)._grid();
}

/// কার্ডের চওড়া-লম্বার অনুপাত (CR80)।
const double idCardAspectRatio = 1.586;

/// তারিখ লেখার সহজ রূপ।
String idCardDateText(DateTime date) => _dateText(date);
