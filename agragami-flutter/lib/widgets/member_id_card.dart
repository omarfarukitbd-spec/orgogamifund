import 'package:flutter/material.dart';

import '../models/branch.dart';
import '../models/member.dart';
import '../theme/app_theme.dart';
import 'app_icon.dart';

export 'member_id_card_back.dart';

/// সদস্যের পরিচয়পত্র — CR80 মাপের (চওড়া : লম্বা ≈ 1.586)।
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

/// কার্ডের চওড়া-লম্বার অনুপাত (CR80)।
const double idCardAspectRatio = 1.586;

/// তারিখ লেখার সহজ রূপ।
String idCardDateText(DateTime date) => _dateText(date);
