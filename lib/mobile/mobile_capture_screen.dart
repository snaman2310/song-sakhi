import 'package:flutter/material.dart';

import '../gemini_service.dart';
import '../theme.dart';
import 'mobile_audio_service.dart';

class MobileCaptureScreen extends StatefulWidget {
  const MobileCaptureScreen({super.key});

  @override
  State<MobileCaptureScreen> createState() => _MobileCaptureScreenState();
}

class _MobileCaptureScreenState extends State<MobileCaptureScreen> {
  static const _seconds = 8;

  final _service = MobileAudioService();
  bool _busy = false;
  bool _needsKey = false;
  String _status = 'Tap the button, then hold your phone near the reel audio.';
  String? _error;

  Future<void> _capture() async {
    setState(() {
      _busy = true;
      _error = null;
      _needsKey = false;
      _status = 'Listening for $_seconds seconds…';
    });
    try {
      final path = await _service.recordClip(seconds: _seconds);
      if (path == null) {
        throw const GeminiException(
          'Microphone permission was denied. Enable it in Settings → Nudge & permissions.',
          code: 'MIC_DENIED',
        );
      }
      if (!mounted) return;
      setState(() => _status = 'Identifying songs…');

      final songs = await _service.identifySongs(path);
      if (!mounted) return;
      if (songs.isEmpty) {
        setState(() {
          _busy = false;
          _status = 'No song recognised. Move closer to the speaker, make sure '
              'the reel is audible, and try again.';
        });
        return;
      }
      Navigator.pushNamed(context, '/suggestions', arguments: songs);
      if (mounted) setState(() => _busy = false);
    } on GeminiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _needsKey = e.needsKey;
        _error = e.message;
        _status = e.needsKey ? 'One-time setup needed' : 'Could not identify audio.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceAll('Exception: ', '');
        _status = 'Could not identify audio.';
      });
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Reel'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
                boxShadow: const [BoxShadow(color: Color(0x5533E076), blurRadius: 40)],
              ),
              child: Icon(_busy ? Icons.graphic_eq : Icons.mic,
                  size: 58, color: AppColors.primary),
            ),
            const SizedBox(height: 28),
            Text(_status,
                style: AppText.bodyMedium(AppColors.onSurfaceVariant),
                textAlign: TextAlign.center),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.secondaryContainer.withValues(alpha: 0.35)),
                ),
                child: Text(_error!,
                    style: AppText.bodySmall(AppColors.onSurface),
                    textAlign: TextAlign.center),
              ),
            ],
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _capture,
                icon: Icon(_busy ? Icons.hourglass_top : Icons.mic),
                label: Text(_busy ? 'Listening…' : 'Capture $_seconds-second clip'),
              ),
            ),
            if (_needsKey) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                  icon: const Icon(Icons.key),
                  label: const Text('Add Gemini API key'),
                ),
              ),
            ],
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tips for a good capture',
                      style: AppText.titleMedium(AppColors.onSurface)),
                  const SizedBox(height: 8),
                  _tip('Play the reel through the phone speaker, not headphones.'),
                  _tip('Hold the phone 10–20 cm from the speaker.'),
                  _tip('Vocals and lyrics help most — avoid silent intros.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tip(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Icon(Icons.circle, size: 6, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: AppText.bodySmall(AppColors.onSurfaceVariant)),
            ),
          ],
        ),
      );
}
