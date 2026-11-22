import 'package:url_launcher/url_launcher.dart';
import '../auth_service.dart';

/// Opens the backend OAuth URL for [kind] with the mobile flag so the backend
/// redirects back to the `songsakhi://` deep link.
Future<void> startMobileOAuth(String kind) async {
  final base = AuthService().buildAuthUrl(kind);
  final uri = Uri.parse('$base?platform=mobile');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
