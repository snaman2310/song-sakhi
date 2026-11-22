import 'package:url_launcher/url_launcher.dart';
import '../auth_service.dart';

/// Opens the backend OAuth URL with the mobile flag so the backend redirects
/// back via the `songsakhi://` deep link. Returns an error string on failure.
Future<String?> startMobileOAuth(String kind) async {
  try {
    final base = AuthService().buildAuthUrl(kind);
    final uri = Uri.parse('$base?platform=mobile');

    // Try external browser first; fall back to in-app browser.
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok) return null;

    final ok2 = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (ok2) return null;

    return 'Could not open the sign-in page.';
  } catch (e) {
    return 'Launch error: ${e.toString()}';
  }
}
