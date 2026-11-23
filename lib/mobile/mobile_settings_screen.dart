import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../auth_service.dart';
import '../gemini_service.dart';
import '../theme.dart';
import 'mobile_auth_launcher.dart';

/// Real settings screen: AI key management, service connections, nudge setup.
class MobileSettingsScreen extends StatefulWidget {
  const MobileSettingsScreen({super.key});

  @override
  State<MobileSettingsScreen> createState() => _MobileSettingsScreenState();
}

class _MobileSettingsScreenState extends State<MobileSettingsScreen> {
  final _keyController = TextEditingController();
  final _gemini = GeminiService();
  final _auth = AuthService();

  bool _obscure = true;
  bool _saving = false;
  bool _testing = false;
  bool _checkingServer = false;
  bool _hasLocalKey = false;
  String? _localHint;
  String? _status;
  bool _statusOk = false;

  bool _spotify = false;
  bool _youtube = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final key = await _gemini.localKey();
    final spotify = await _auth.tokenFor('spotify');
    final youtube = await _auth.tokenFor('google');
    if (!mounted) return;
    setState(() {
      _hasLocalKey = key != null;
      _localHint = key == null
          ? null
          : '${key.substring(0, 6)}…${key.substring(key.length - 4)}';
      _spotify = spotify != null && spotify.isNotEmpty;
      _youtube = youtube != null && youtube.isNotEmpty;
    });
  }

  void _toast(String message, {bool ok = false}) {
    if (!mounted) return;
    setState(() {
      _status = message;
      _statusOk = ok;
    });
  }

  Future<void> _saveKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      _toast('Paste your Gemini API key first.');
      return;
    }
    if (!GeminiService.looksLikeGeminiKey(key)) {
      _toast('That key looks wrong — Gemini keys start with "AIza".', ok: false);
      return;
    }
    setState(() => _saving = true);
    await _gemini.saveLocalKey(key);
    await _load();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _keyController.clear();
    });
    _toast('Key saved on this device. Tap "Test key" to verify it.', ok: true);
  }

  Future<void> _testKey() async {
    final typed = _keyController.text.trim();
    final key = typed.isNotEmpty ? typed : await _gemini.localKey();
    if (key == null) {
      _toast('Paste a Gemini API key first.');
      return;
    }
    setState(() => _testing = true);
    try {
      final model = await _gemini.testKey(key);
      if (typed.isNotEmpty) {
        await _gemini.saveLocalKey(key);
        await _load();
      }
      _toast('Key works — answered by $model.', ok: true);
    } on GeminiException catch (e) {
      _toast(e.message, ok: false);
    } catch (e) {
      _toast('Test failed: $e', ok: false);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _removeKey() async {
    await _gemini.clearLocalKey();
    await _load();
    _toast('Key removed from this device.');
  }

  Future<void> _showKeyHelp() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: const Text('Get a free Gemini key'),
        content: const Text(
          '1. Open aistudio.google.com/apikey\n'
          '2. Sign in with your Google account\n'
          '3. Tap "Create API key"\n'
          '4. Copy it — it starts with "AIza"\n'
          '5. Paste it above, tap Save key, then Test key\n\n'
          'The free tier is enough for personal use. The key stays on this '
          'device and is only sent to Google.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final uri = Uri.parse('https://aistudio.google.com/apikey');
              final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
              if (!ok) {
                await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
              }
            },
            child: const Text('Open AI Studio'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  /// Asks the backend whether *it* has a working Gemini key configured.
  Future<void> _checkServer() async {
    setState(() => _checkingServer = true);
    try {
      final res = await http
          .get(Uri.parse('${GeminiService.backendUrl}/api/gemini/health'))
          .timeout(const Duration(seconds: 60));
      final body = json.decode(res.body) as Map<String, dynamic>;
      if (body['ok'] == true) {
        _toast('Server key is working (${body['model']}).', ok: true);
      } else {
        _toast(
          'Server: ${body['error'] ?? 'not ready'}',
          ok: false,
        );
      }
    } catch (e) {
      _toast('Could not reach the song service: $e');
    } finally {
      if (mounted) setState(() => _checkingServer = false);
    }
  }

  Future<void> _connect(String kind) async {
    final err = await startMobileOAuth(kind);
    if (err != null) {
      _toast(err);
      return;
    }
    // Tokens arrive through the deep link; refresh when we come back.
    await Future.delayed(const Duration(seconds: 1));
    await _load();
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: const Text('Sign out?'),
        content: const Text(
          'This removes your Spotify and YouTube Music connections from this '
          'device. Your saved songs stay on the phone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out', style: TextStyle(color: AppColors.secondary)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _auth.clearTokens();
    await _load();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _sectionTitle('AI Settings'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Gemini song identification',
                          style: AppText.titleMedium(AppColors.onSurface)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _hasLocalKey
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _hasLocalKey ? 'Key set' : 'No key',
                        style: AppText.labelSmall(
                            _hasLocalKey ? AppColors.primary : AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _hasLocalKey
                      ? 'Using the key stored on this device (${_localHint ?? ''}). '
                          'It is never uploaded anywhere except Google.'
                      : 'The song service has no key configured, so add your own free '
                          'Gemini key. Create one at aistudio.google.com/apikey — it '
                          'starts with "AIza".',
                  style: AppText.bodySmall(AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _keyController,
                  obscureText: _obscure,
                  style: AppText.bodyMedium(AppColors.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Gemini API key',
                    hintText: 'AIza…',
                    filled: true,
                    fillColor: AppColors.surfaceLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off,
                          color: AppColors.onSurfaceVariant, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveKey,
                        icon: const Icon(Icons.save, size: 18),
                        label: Text(_saving ? 'Saving…' : 'Save key'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _testing ? null : _testKey,
                        icon: _testing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.science, size: 18),
                        label: Text(_testing ? 'Testing…' : 'Test key'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _showKeyHelp,
                      icon: const Icon(Icons.help_outline, size: 16),
                      label: const Text('How do I get a key?'),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _checkingServer ? null : _checkServer,
                      icon: _checkingServer
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_outlined, size: 16),
                      label: const Text('Check server'),
                    ),
                    if (_hasLocalKey)
                      TextButton(
                        onPressed: _removeKey,
                        child: const Text('Remove',
                            style: TextStyle(color: AppColors.secondary)),
                      ),
                  ],
                ),
                if (_status != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (_statusOk ? AppColors.primary : AppColors.secondaryContainer)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _status!,
                      style: AppText.bodySmall(
                          _statusOk ? AppColors.primary : AppColors.onSurface),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 22),
          _sectionTitle('Connections'),
          _connectionTile(
            icon: Icons.graphic_eq,
            color: const Color(0xFF1DB954),
            title: 'Spotify',
            connected: _spotify,
            onConnect: () => _connect('spotify'),
          ),
          const SizedBox(height: 10),
          _connectionTile(
            icon: Icons.play_circle_fill,
            color: const Color(0xFFFF0000),
            title: 'YouTube Music',
            connected: _youtube,
            onConnect: () => _connect('google'),
          ),

          const SizedBox(height: 22),
          _sectionTitle('Nudge & permissions'),
          _card(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.layers, color: AppColors.primary),
                  title: Text('Floating nudge setup',
                      style: AppText.titleMedium(AppColors.onSurface)),
                  subtitle: Text('Overlay, microphone and battery permissions',
                      style: AppText.bodySmall(AppColors.onSurfaceVariant)),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.onSurfaceVariant),
                  onTap: () => Navigator.pushNamed(context, '/permissions'),
                ),
                const Divider(color: AppColors.outlineVariant, height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.mic, color: AppColors.primary),
                  title: Text('Capture a reel now',
                      style: AppText.titleMedium(AppColors.onSurface)),
                  subtitle: Text('Listen for 5 seconds and identify songs',
                      style: AppText.bodySmall(AppColors.onSurfaceVariant)),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.onSurfaceVariant),
                  onTap: () => Navigator.pushNamed(context, '/capture'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),
          _sectionTitle('Account'),
          _card(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout, color: AppColors.secondary),
              title: Text('Sign out',
                  style: AppText.titleMedium(AppColors.onSurface)),
              subtitle: Text('Disconnect Spotify and YouTube Music',
                  style: AppText.bodySmall(AppColors.onSurfaceVariant)),
              onTap: _signOut,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text('Song Sakhi v1.0.0',
                style: AppText.bodySmall(AppColors.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Text(text.toUpperCase(),
            style: AppText.labelSmall(AppColors.onSurfaceVariant)),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: child,
      );

  Widget _connectionTile({
    required IconData icon,
    required Color color,
    required String title,
    required bool connected,
    required VoidCallback onConnect,
  }) {
    return _card(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.titleMedium(AppColors.onSurface)),
                Text(connected ? 'Connected' : 'Not connected',
                    style: AppText.bodySmall(
                        connected ? AppColors.primary : AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          TextButton(
            onPressed: onConnect,
            child: Text(connected ? 'Reconnect' : 'Connect'),
          ),
        ],
      ),
    );
  }
}
