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
  });

  factory Member.fromMap(String id, Map<String, dynamic> data) {
    return Member(
      id: id,
      name: (data['name'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      photoUrl: data['photoUrl'] as String?,
      nidNumber: (data['nid'] as String?) ?? '',
      nidPhotoUrl: data['nidPhotoUrl'] as String?,
      branchId: (data['branchId'] as String?) ?? '',
      joinDate: DateTime.tryParse((data['joinDate'] as String?) ?? '') ??
          DateTime.now(),
      emergencyContactName:
          (data['emergencyContact'] as Map?)?['name'] as String? ?? '',
      emergencyContactPhone:
          (data['emergencyContact'] as Map?)?['phone'] as String? ?? '',
      linkedUserId: data['linkedUserId'] as String?,
      active: (data['status'] as String? ?? 'active') == 'active',
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
      'joinDate': joinDate.toIso8601String(),
      'emergencyContact': {
        'name': emergencyContactName,
        'phone': emergencyContactPhone,
      },
      'linkedUserId': linkedUserId,
      'status': active ? 'active' : 'left',
    };
  }
}
