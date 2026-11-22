import 'package:flutter/material.dart';
import '../theme.dart';
import 'mobile_audio_service.dart';

class MobileCaptureScreen extends StatefulWidget {
  const MobileCaptureScreen({super.key});
  @override
  State<MobileCaptureScreen> createState() => _MobileCaptureScreenState();
}

class _MobileCaptureScreenState extends State<MobileCaptureScreen> {
  final _service = MobileAudioService();
  bool _busy = false;
  String _status = 'Tap the button to listen to the reel audio.';
  String? _error;

  Future<void> _capture() async {
    setState(() {
      _busy = true;
      _error = null;
      _status = 'Listening for 5 seconds…';
    });
    try {
      final path = await _service.recordClip(seconds: 5);
      if (path == null) {
        throw Exception('Microphone permission denied.');
      }
      if (!mounted) return;
      setState(() => _status = 'Identifying songs with Gemini…');
      final songs = await _service.identifySongs(path);
      if (!mounted) return;
      if (songs.isEmpty) {
        setState(() {
          _busy = false;
          _status = 'No songs identified. Try again closer to your phone.';
        });
        return;
      }
      Navigator.pushNamed(context, '/suggestions', arguments: songs);
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
      appBar: AppBar(title: const Text('Capture Reel')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.12),
                  boxShadow: const [BoxShadow(color: Color(0x5533E076), blurRadius: 40)],
                ),
                child: Icon(_busy ? Icons.graphic_eq : Icons.mic,
                    size: 56, color: AppColors.primary),
              ),
              const SizedBox(height: 28),
              Text(_status,
                  style: AppText.bodyMedium(AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: AppText.bodySmall(AppColors.secondaryContainer),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _capture,
                  icon: const Icon(Icons.mic),
                  label: Text(_busy ? 'Listening…' : 'Capture Reel Audio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
