/// Global configuration for Blood Donation Finder & Tracker.
///
/// Supports compile-time overrides via `--dart-define`:
/// - `--dart-define=MAPS_API_KEY=your_key_here`
/// - `--dart-define=DONATION_ELIGIBILITY_DAYS=90`
class AppConfig {
  AppConfig._();

  static const String appName = 'Blood Donation Finder & Tracker';
  static const String appVersion = '1.0.0';

  /// Standard medical donor eligibility interval (in days)
  static const int eligibilityDays = int.fromEnvironment(
    'DONATION_ELIGIBILITY_DAYS',
    defaultValue: 90,
  );

  /// Google Maps API Key provided via dart-define or build configuration
  static const String googleMapsApiKey = String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: '',
  );

  /// Whether to use OpenStreetMap fallback if Google Maps API key is missing
  static bool get hasGoogleMapsKey => googleMapsApiKey.trim().isNotEmpty;

  /// Default search radius in kilometers for donor discovery
  static const double defaultRadiusKm = 10.0;
  static const List<double> radiusOptionsKm = [1.0, 5.0, 10.0, 25.0];

  /// Emergency SOS broadcast radius increments (in km)
  static const List<double> sosBroadcastRadiiKm = [5.0, 10.0, 25.0];
}
