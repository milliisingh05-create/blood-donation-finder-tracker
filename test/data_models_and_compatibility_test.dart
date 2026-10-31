import 'package:flutter_test/flutter_test.dart';
import 'package:blood_donation_finder/core/utils/blood_compatibility.dart';
import 'package:blood_donation_finder/core/data/mock_seed_data.dart';
import 'package:blood_donation_finder/features/profile/domain/models/user_profile.dart';
import 'package:blood_donation_finder/features/requests/domain/models/donation_request.dart';
import 'package:blood_donation_finder/features/hospitals/domain/models/hospital.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Blood Compatibility Matrix Tests', () {
    test('O- is universal donor (can donate to all groups)', () {
      for (final recipient in BloodCompatibility.allBloodGroups) {
        expect(
          BloodCompatibility.canDonateTo(donorGroup: 'O-', recipientGroup: recipient),
          isTrue,
          reason: 'O- must be able to donate to $recipient',
        );
      }
    });

    test('AB+ is universal recipient (can receive from all groups)', () {
      for (final donor in BloodCompatibility.allBloodGroups) {
        expect(
          BloodCompatibility.canDonateTo(donorGroup: donor, recipientGroup: 'AB+'),
          isTrue,
          reason: 'AB+ must be able to receive from $donor',
        );
      }
    });

    test('O- recipient can only receive from O-', () {
      final donors = BloodCompatibility.getCompatibleDonorsFor('O-');
      expect(donors, equals(['O-']));
      expect(BloodCompatibility.canDonateTo(donorGroup: 'O+', recipientGroup: 'O-'), isFalse);
      expect(BloodCompatibility.canDonateTo(donorGroup: 'A+', recipientGroup: 'O-'), isFalse);
      expect(BloodCompatibility.canDonateTo(donorGroup: 'B-', recipientGroup: 'O-'), isFalse);
    });

    test('A+ recipient can receive from O-, O+, A-, A+', () {
      final compatible = BloodCompatibility.getCompatibleDonorsFor('A+');
      expect(compatible, containsAll(['O-', 'O+', 'A-', 'A+']));
      expect(compatible, isNot(contains('B+')));
      expect(compatible, isNot(contains('AB+')));
    });

    test('B- donor can only give to B-, B+, AB-, AB+', () {
      final recipients = BloodCompatibility.getCompatibleRecipientsFor('B-');
      expect(recipients, equals(['B-', 'B+', 'AB-', 'AB+']));
    });
  });

  group('UserProfile Model & Eligibility Tests', () {
    test('Donor with no previous donation is immediately eligible', () {
      final donor = UserProfile(
        uid: 'test_1',
        name: 'New Donor',
        phone: '+1 415-555-1234',
        email: 'test@example.com',
        bloodGroup: 'O+',
        city: 'San Francisco',
        geohash: '9q8yy',
        latitude: 37.77,
        longitude: -122.41,
        lastDonationDate: null,
        createdAt: DateTime.now(),
      );

      expect(donor.isEligible, isTrue);
      expect(donor.daysUntilEligible, 0);
    });

    test('Donor who donated 30 days ago is ineligible with 60 days remaining', () {
      final donor = UserProfile(
        uid: 'test_2',
        name: 'Recent Donor',
        phone: '+1 415-555-1234',
        email: 'recent@example.com',
        bloodGroup: 'A+',
        city: 'San Francisco',
        geohash: '9q8yy',
        latitude: 37.77,
        longitude: -122.41,
        lastDonationDate: DateTime.now().subtract(const Duration(days: 30)),
        createdAt: DateTime.now(),
      );

      expect(donor.isEligible, isFalse);
      expect(donor.daysUntilEligible, inInclusiveRange(59, 61));
    });

    test('Phone number masking protects donor privacy', () {
      final donor = MockSeedData.donors.first;
      expect(donor.maskedPhone, contains('***'));
      expect(donor.maskedPhone.length, lessThanOrEqualTo(donor.phone.length));
    });

    test('Serialization roundtrip converts cleanly', () {
      final original = MockSeedData.donors.first;
      final map = original.toMap();
      final restored = UserProfile.fromMap(map, documentId: original.uid);

      expect(restored.uid, original.uid);
      expect(restored.name, original.name);
      expect(restored.bloodGroup, original.bloodGroup);
      expect(restored.points, original.points);
      expect(restored.badges, equals(original.badges));
    });
  });

  group('Mock Seed Repository Verification', () {
    test('Contains 10 valid donors across all blood groups', () {
      expect(MockSeedData.donors.length, 10);
      final bloodGroupsInSeed = MockSeedData.donors.map((d) => d.bloodGroup).toSet();
      expect(bloodGroupsInSeed.length, 8); // All 8 groups represented
    });

    test('Contains 5 hospitals with comprehensive blood stock maps', () {
      expect(MockSeedData.hospitals.length, 5);
      for (final hosp in MockSeedData.hospitals) {
        expect(hosp.totalStockUnits, greaterThan(0));
        expect(hosp.phone, isNotEmpty);
      }
    });

    test('Hospital model serialization works correctly', () {
      final hosp = MockSeedData.hospitals.first;
      final map = hosp.toMap();
      final restored = Hospital.fromMap(map, documentId: hosp.id);

      expect(restored.id, hosp.id);
      expect(restored.name, hosp.name);
      expect(restored.totalStockUnits, hosp.totalStockUnits);
    });

    test('DonationRequest model serialization works correctly', () {
      final req = MockSeedData.requests.first;
      final map = req.toMap();
      final restored = DonationRequest.fromMap(map, documentId: req.id);

      expect(restored.id, req.id);
      expect(restored.isCritical, isTrue);
      expect(restored.bloodGroup, 'O-');
    });
  });
}
