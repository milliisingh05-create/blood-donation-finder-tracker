/// Standard medical blood compatibility rules engine.
///
/// Rules:
/// - O- is the universal red cell donor (can donate to any blood group).
/// - AB+ is the universal red cell recipient (can receive from any blood group).
/// - Rh-negative patients can generally only receive Rh-negative blood safely.
class BloodCompatibility {
  BloodCompatibility._();

  static const List<String> allBloodGroups = [
    'O-',
    'O+',
    'A-',
    'A+',
    'B-',
    'B+',
    'AB-',
    'AB+',
  ];

  /// Map of [Recipient Blood Group] -> List of [Compatible Donor Blood Groups]
  static const Map<String, List<String>> _compatibleDonors = {
    'O-': ['O-'],
    'O+': ['O-', 'O+'],
    'A-': ['O-', 'A-'],
    'A+': ['O-', 'O+', 'A-', 'A+'],
    'B-': ['O-', 'B-'],
    'B+': ['O-', 'O+', 'B-', 'B+'],
    'AB-': ['O-', 'A-', 'B-', 'AB-'],
    'AB+': ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'],
  };

  /// Map of [Donor Blood Group] -> List of [Compatible Recipient Blood Groups]
  static const Map<String, List<String>> _compatibleRecipients = {
    'O-': ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'],
    'O+': ['O+', 'A+', 'B+', 'AB+'],
    'A-': ['A-', 'A+', 'AB-', 'AB+'],
    'A+': ['A+', 'AB+'],
    'B-': ['B-', 'B+', 'AB-', 'AB+'],
    'B+': ['B+', 'AB+'],
    'AB-': ['AB-', 'AB+'],
    'AB+': ['AB+'],
  };

  /// Returns true if a donor with [donorGroup] can donate to [recipientGroup].
  static bool canDonateTo({
    required String donorGroup,
    required String recipientGroup,
  }) {
    final recipients = _compatibleRecipients[donorGroup.trim().toUpperCase()];
    if (recipients == null) return false;
    return recipients.contains(recipientGroup.trim().toUpperCase());
  }

  /// Returns the list of donor blood groups compatible with the [recipientGroup].
  static List<String> getCompatibleDonorsFor(String recipientGroup) {
    return _compatibleDonors[recipientGroup.trim().toUpperCase()] ?? [];
  }

  /// Returns the list of recipient blood groups that [donorGroup] can give blood to.
  static List<String> getCompatibleRecipientsFor(String donorGroup) {
    return _compatibleRecipients[donorGroup.trim().toUpperCase()] ?? [];
  }

  /// Returns true if [bloodGroup] is valid.
  static bool isValidBloodGroup(String bloodGroup) {
    return allBloodGroups.contains(bloodGroup.trim().toUpperCase());
  }
}
