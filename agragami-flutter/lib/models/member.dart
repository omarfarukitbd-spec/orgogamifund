import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/date_parser.dart';

/// একজন সদস্য।
/// Firestore কালেকশন: members
class Member {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String? photoUrl;
  final String nidNumber;
  final String? nidPhotoUrl;
  final String branchId;
  final DateTime joinDate;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String? linkedUserId;
  final bool active;

  /// মানুষের পড়ার মতো সদস্য নম্বর — সমিতি-ভিত্তিক ক্রমিক
  /// (১, ২, ৩...), অনুমোদনের সময় বসে। পুরোনো সদস্যদের
  /// ডকুমেন্টে এই ক্ষেত্র নেই — তখন null থাকে আর দেখানোর
  /// জায়গায় [displayNumber] ডকুমেন্ট id-এর সংক্ষিপ্ত রূপ দেখায়।
  final int? memberNumber;

  const Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.photoUrl,
    required this.nidNumber,
    this.nidPhotoUrl,
    required this.branchId,
    required this.joinDate,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    this.linkedUserId,
    this.active = true,
    this.memberNumber,
  });

  /// দেখানোর জন্য সদস্য নম্বর: ক্রমিক নম্বর থাকলে সেটা,
  /// না থাকলে ডকুমেন্ট id-এর প্রথম ৬ অক্ষর — কোথাও পুরো
  /// ২০-অক্ষরের id দেখানো হয় না।
  String get displayNumber =>
      memberNumber != null ? '$memberNumber' : id.substring(0, id.length < 6 ? id.length : 6);

  factory Member.fromMap(String id, Map<String, dynamic> data) {
    final rawStatus = (data['status'] as String?)?.toLowerCase();
    final isActive = rawStatus == null || (rawStatus != 'left' && rawStatus != 'inactive');

    return Member(
      id: id,
      name: (data['name'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      photoUrl: data['photoUrl'] as String?,
      nidNumber: (data['nid'] as String?) ?? '',
      nidPhotoUrl: data['nidPhotoUrl'] as String?,
      branchId: (data['branchId'] as String?) ?? '',
      joinDate: parseFirestoreDate(data['joinDate']),
      emergencyContactName:
          (data['emergencyContact'] as Map?)?['name'] as String? ?? '',
      emergencyContactPhone:
          (data['emergencyContact'] as Map?)?['phone'] as String? ?? '',
      linkedUserId: data['linkedUserId'] as String?,
      active: isActive,
      memberNumber: (data['memberNumber'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'photoUrl': photoUrl,
      'nid': nidNumber,
      'nidPhotoUrl': nidPhotoUrl,
      'branchId': branchId,
      'joinDate': Timestamp.fromDate(joinDate),
      'emergencyContact': {
        'name': emergencyContactName,
        'phone': emergencyContactPhone,
      },
      'linkedUserId': linkedUserId,
      'status': active ? 'active' : 'left',
      if (memberNumber != null) 'memberNumber': memberNumber,
    };
  }
}
