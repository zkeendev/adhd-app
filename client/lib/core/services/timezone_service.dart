import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A service dedicated to handling timezone-related logic.
class TimezoneService {
  /// Fetches the device's current IANA timezone identifier.
  ///
  /// e.g., "America/New_York", "Europe/London".
  /// Returns a default value of "UTC" if detection fails.
  Future<String> getLocalTimezone() async {
    try {
      final String localTimezone = await FlutterTimezone.getLocalTimezone();
      return localTimezone;
    } catch (e) {
      // Log the error in a real app
      print('Failed to get local timezone: $e');
      // Provide a safe fallback
      return 'UTC';
    }
  }
}

/// Riverpod provider for the TimezoneService.
final timezoneServiceProvider = Provider<TimezoneService>((ref) {
  return TimezoneService();
});
