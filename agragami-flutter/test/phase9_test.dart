import 'package:agragami_fund/models/edit_request.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 9-এর যাচাই — তথ্য সংশোধনের আবেদনের বদলানো
/// ক্ষেত্র বের করা (EditRequest.diff) আর অবস্থা/ক্ষেত্রের
/// বাংলা নাম। শুধু সত্যিকারের বদলানো ক্ষেত্র আবেদনে যায়।
void main() {
  group('EditRequest.diff', () {
    test('শুধু ফোন বদলালে শুধু ফোন আসে', () {
      final result = EditRequest.diff(
        oldPhone: '01711111111',
        newPhone: '01722222222',
        oldAddress: 'ঢাকা',
        newAddress: 'ঢাকা',
      );
      expect(result.changes, {'phone': '01722222222'});
      expect(result.previous, {'phone': '01711111111'});
    });

    test('শুধু ঠিকানা বদলালে শুধু ঠিকানা আসে', () {
      final result = EditRequest.diff(
        oldPhone: '01711111111',
        newPhone: '01711111111',
        oldAddress: 'ঢাকা',
        newAddress: 'চট্টগ্রাম',
      );
      expect(result.changes, {'address': 'চট্টগ্রাম'});
      expect(result.previous, {'address': 'ঢাকা'});
    });

    test('দুটোই বদলালে দুটোই আসে', () {
      final result = EditRequest.diff(
        oldPhone: '01711111111',
        newPhone: '01722222222',
        oldAddress: 'ঢাকা',
        newAddress: 'চট্টগ্রাম',
      );
      expect(result.changes, {
        'phone': '01722222222',
        'address': 'চট্টগ্রাম',
      });
      expect(result.previous, {
        'phone': '01711111111',
        'address': 'ঢাকা',
      });
    });

    test('কিছু না বদলালে দুটো ম্যাপই খালি', () {
      final result = EditRequest.diff(
        oldPhone: '01711111111',
        newPhone: '01711111111',
        oldAddress: 'ঢাকা',
        newAddress: 'ঢাকা',
      );
      expect(result.changes, isEmpty);
      expect(result.previous, isEmpty);
    });

    test('শুধু বাড়তি স্পেস বদলালে কিছু আসে না', () {
      final result = EditRequest.diff(
        oldPhone: '01711111111',
        newPhone: '  01711111111  ',
        oldAddress: 'ঢাকা',
        newAddress: 'ঢাকা  ',
      );
      expect(result.changes, isEmpty);
      expect(result.previous, isEmpty);
    });

    test('বদলানো মান trim হয়ে বসে', () {
      final result = EditRequest.diff(
        oldPhone: '01711111111',
        newPhone: '  01722222222 ',
        oldAddress: 'ঢাকা',
        newAddress: 'ঢাকা',
      );
      expect(result.changes, {'phone': '01722222222'});
    });
  });

  group('editRequestStatusText', () {
    test('তিন অবস্থার বাংলা নাম', () {
      expect(editRequestStatusText(EditRequestStatus.pending), 'অপেক্ষায়');
      expect(editRequestStatusText(EditRequestStatus.approved), 'অনুমোদিত');
      expect(editRequestStatusText(EditRequestStatus.rejected), 'বাতিল');
    });
  });

  group('editRequestFieldLabel', () {
    test('ফোন আর ঠিকানার লেবেল', () {
      expect(editRequestFieldLabel('phone'), 'ফোন');
      expect(editRequestFieldLabel('address'), 'ঠিকানা');
    });

    test('অজানা ক্ষেত্র যেমন আছে তেমনই ফেরে', () {
      expect(editRequestFieldLabel('name'), 'name');
    });
  });
}
