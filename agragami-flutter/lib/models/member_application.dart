import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/date_parser.dart';
import 'app_user.dart';

/// সদস্য হওয়ার আবেদন।
/// Firestore কালেকশন: memberApplications
/// আবেদন জমা হলে অবস্থা pending থাকে — অ্যাডমিন অনুমোদন
/// দিলে তবেই members-এ সদস্যের রেকর্ড তৈরি হয়।
enum ApplicationStatus { pending, approved, rejected }

class MemberApplication {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String branchId;
  final DateTime joinDate;
  final String nidNumber;
  final String? photoUrl;
  final String? nidFrontUrl;
  final String? nidBackUrl;
  final String? applicantUid;
  /// আবেদনের সময় বানানো অ্যাকাউন্টের ইমেইল — লগইনের পরিচয়।
  final String? email;
  final ApplicationStatus status;
  final DateTime requestedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectReason;

  const MemberApplication({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.branchId,
    required this.joinDate,
    required this.nidNumber,
    this.photoUrl,
    this.nidFrontUrl,
    this.nidBackUrl,
    this.applicantUid,
    this.email,
    this.status = ApplicationStatus.pending,
    required this.requestedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectReason,
  });

  factory MemberApplication.fromMap(String id, Map<String, dynamic> data) {
    return MemberApplication(
      id: id,
      name: (data['name'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      emergencyContactName:
          (data['emergencyContact'] as Map?)?['name'] as String? ?? '',
      emergencyContactPhone:
          (data['emergencyContact'] as Map?)?['phone'] as String? ?? '',
      branchId: (data['branchId'] as String?) ?? '',
      // Timestamp তারিখেও চলে — আগের `as String` কাস্টে
      // Timestamp ডকুমেন্টে পুরো স্ট্রিম ভেঙে যেত।
      joinDate: parseFirestoreDate(data['joinDate']),
      nidNumber: (data['nid'] as String?) ?? '',
      photoUrl: data['photoUrl'] as String?,
      nidFrontUrl: data['nidFrontUrl'] as String?,
      nidBackUrl: data['nidBackUrl'] as String?,
      applicantUid: data['applicantUid'] as String?,
      email: data['email'] as String?,
      status: ApplicationStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ApplicationStatus.pending,
      ),
      requestedAt: parseFirestoreDate(data['requestedAt']),
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: parseFirestoreDateOrNull(data['reviewedAt']),
      rejectReason: data['rejectReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'emergencyContact': {
        'name': emergencyContactName,
        'phone': emergencyContactPhone,
      },
      'branchId': branchId,
      'joinDate': Timestamp.fromDate(joinDate),
      'nid': nidNumber,
      'photoUrl': photoUrl,
      'nidFrontUrl': nidFrontUrl,
      'nidBackUrl': nidBackUrl,
      'applicantUid': applicantUid,
      'email': email,
      'status': status.name,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'reviewedBy': reviewedBy,
      'reviewedAt':
          reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
      'rejectReason': rejectReason,
    };
  }

  /// অনুমোদনের সময় members কালেকশনে বসানোর মতো রেকর্ড।
  /// অনুমোদনের সময় সদস্য ডকুমেন্টের ম্যাপ। [memberNumber] —
  /// সমিতি-ভিত্তিক ক্রমিক সদস্য নম্বর (F15) — অনুমোদনকারী
  /// ট্রানজ্যাকশন ঠিক করে দেয়; না দিলে ক্ষেত্রটা লেখা হয় না।
  Map<String, dynamic> toMemberMap({int? memberNumber}) {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'photoUrl': photoUrl,
      'nid': nidNumber,
      'nidPhotoUrl': nidFrontUrl,
      'branchId': branchId,
      'joinDate': Timestamp.fromDate(joinDate),
      'emergencyContact': {
        'name': emergencyContactName,
        'phone': emergencyContactPhone,
      },
      'linkedUserId': applicantUid,
      'status': 'active',
      if (memberNumber != null) 'memberNumber': memberNumber,
    };
  }

  MemberApplication copyWith({
    ApplicationStatus? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectReason,
  }) {
    return MemberApplication(
      id: id,
      name: name,
      phone: phone,
      address: address,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      branchId: branchId,
      joinDate: joinDate,
      nidNumber: nidNumber,
      photoUrl: photoUrl,
      nidFrontUrl: nidFrontUrl,
      nidBackUrl: nidBackUrl,
      applicantUid: applicantUid,
      email: email,
      status: status ?? this.status,
      requestedAt: requestedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectReason: rejectReason ?? this.rejectReason,
    );
  }
}

/// আবেদনের অবস্থার বাংলা নাম।
String applicationStatusText(ApplicationStatus status) {
  switch (status) {
    case ApplicationStatus.pending:
      return 'অপেক্ষায়';
    case ApplicationStatus.approved:
      return 'অনুমোদিত';
    case ApplicationStatus.rejected:
      return 'বাতিল';
  }
}

/// ApprovalStatus-এর বাংলা নাম — রাউটার গার্ড আর স্ক্রিনে ব্যবহার হবে।
String approvalStatusText(ApprovalStatus status) {
  switch (status) {
    case ApprovalStatus.pending:
      return 'অপেক্ষায়';
    case ApprovalStatus.approved:
      return 'অনুমোদিত';
    case ApprovalStatus.rejected:
      return 'বাতিল';
  }
}
