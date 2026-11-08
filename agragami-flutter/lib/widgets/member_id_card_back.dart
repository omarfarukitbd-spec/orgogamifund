import 'package:flutter/material.dart';
import '../models/member.dart';
import '../theme/app_theme.dart';

/// কার্ডের পেছন দিক — সবুজ পটভূমি, জরুরি যোগাযোগ, সই ও কিউআর ছক।
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

/// সদস্য নম্বর থেকে বানানো কোডের মতো ছক
class QrPatternPainter extends CustomPainter {
  final String seed;

  QrPatternPainter({required this.seed});

  List<List<bool>> grid() {
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

    final g = List.generate(
      size,
      (_) => List.generate(size, (_) => next()),
    );
    for (final corner in [
      (0, 0),
      (0, size - 7),
      (size - 7, 0),
    ]) {
      for (var r = 0; r < 7; r++) {
        for (var c = 0; c < 7; c++) {
          final onBorder = r == 0 || r == 6 || c == 0 || c == 6;
          final inCenter = r >= 2 && r <= 4 && c >= 2 && c <= 4;
          g[corner.$1 + r][corner.$2 + c] = onBorder || inCenter;
        }
      }
    }
    return g;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final g = grid();
    final cell = size.width / g.length;
    final paint = Paint()..color = AppColors.ink;
    for (var r = 0; r < g.length; r++) {
      for (var c = 0; c < g.length; c++) {
        if (g[r][c]) {
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

List<List<bool>> qrPatternGrid(String seed) {
  return QrPatternPainter(seed: seed).grid();
}
