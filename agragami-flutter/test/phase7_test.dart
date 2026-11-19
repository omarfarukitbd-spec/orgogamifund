import 'package:agragami_fund/utils/samiti_apply.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 7-এর যাচাই — সমিতিতে আবেদনের বোতাম কখন দেখা
/// যাবে (shouldShowApplyButton)। অ্যাডমিন হওয়া বাধা নয়:
/// বোতাম লুকায় শুধু অনুমোদিত সদস্য আর প্রক্রিয়াধীন
/// আবেদনকারীর কাছে — জমা-যাচাইয়ের (submit) গার্ডের
/// সাথে একই নিয়ম।
void main() {
  group('shouldShowApplyButton', () {
    test('সদস্য নয়, আবেদনও নেই — বোতাম দেখা যায়', () {
      expect(
        shouldShowApplyButton(
          isApprovedMember: false,
          isPendingApplication: false,
        ),
        isTrue,
      );
    });

    test('অনুমোদিত সদস্য — বোতাম দেখা যায় না', () {
      expect(
        shouldShowApplyButton(
          isApprovedMember: true,
          isPendingApplication: false,
        ),
        isFalse,
      );
    });

    test('আবেদন প্রক্রিয়াধীন — বোতাম দেখা যায় না', () {
      expect(
        shouldShowApplyButton(
          isApprovedMember: false,
          isPendingApplication: true,
        ),
        isFalse,
      );
    });

    test('দুটোই সত্য (অসম্ভব অবস্থা) — তবু বোতাম দেখা যায় না', () {
      expect(
        shouldShowApplyButton(
          isApprovedMember: true,
          isPendingApplication: true,
        ),
        isFalse,
      );
    });
  });
}
