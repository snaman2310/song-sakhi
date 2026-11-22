import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';

class NudgeListeningScreen extends StatefulWidget {
  const NudgeListeningScreen({super.key});
  @override
  State<NudgeListeningScreen> createState() => _NudgeListeningScreenState();
}

class _NudgeListeningScreenState extends State<NudgeListeningScreen> {
  bool _listening = true;
  bool _liked = false;
  bool _muted = false;
  bool _following = false;

  void _onNudge() {
    setState(() => _listening = !_listening);
    if (_listening) {
      // After a short "listen", reveal the detected songs.
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) Navigator.pushNamed(context, '/suggestions');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SmartImage(
                        url: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCpMTYajtxpmiaomqXLI7dUCYnrmpHFXmDAVpygnTrCqq_VsT6BpHVF37BtBb2sMIRUP_LyjwXyqoIbHGbl1H5SG3nDDc9gflMjIJWagkC4DL4uCFmQDPUtHDYEep_xEijO7U_4kfnSAwgU32vOL-xz5SepmnANxqOdYVOTDwd60guIwvnY4J5ingrUhCO57xkp20V1Ig5x029reOC4sWBL5K1NGVjW946lHLnGVpU',
                        fallback: [AppColors.tertiaryContainer, Colors.black],
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0x99000000), Colors.transparent, Color(0xE6000000)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),

                    // Top navigation
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            const Text('Reels',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            Icon(Icons.expand_more, size: 18, color: Colors.white70),
                          ]),
                          Row(children: [
                            _glassIcon(Icons.photo_camera),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => setState(() => _muted = !_muted),
                              child: _glassIcon(
                                  _muted ? Icons.volume_off : Icons.volume_up),
                            ),
                          ]),
                        ],
                      ),
                    ),

                    // Floating glass nudge button
                    Positioned(
                      top: 84,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: _onNudge,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 66,
                                  height: 66,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(colors: [
                                      AppColors.primary.withValues(alpha: 0.45),
                                      Colors.transparent,
                                    ]),
                                  ),
                                ),
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(alpha: 0.42),
                                    border: Border.all(color: Colors.white38),
                                    boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 20)],
                                  ),
                                  child: Center(
                                    child: NeonBars(animate: _listening),
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary,
                                      boxShadow: const [BoxShadow(color: AppColors.primary, blurRadius: 6)],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle, color: AppColors.primary),
                              ),
                              const SizedBox(width: 6),
                              Text(_listening ? 'Listening to Reel' : 'Tap to Nudge',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                            ]),
                          ),
                        ],
                      ),
                    ),

                    // Right action rail
                    Positioned(
                      right: 12,
                      bottom: 110,
                      child: Column(
                        children: [
                          _railAction(
                            icon: Icons.favorite,
                            label: _liked ? '42.9K' : '42.8K',
                            color: _liked ? const Color(0xFFFF3040) : Colors.white,
                            filled: _liked,
                            onTap: () => setState(() => _liked = !_liked),
                          ),
                          const SizedBox(height: 18),
                          _railAction(icon: Icons.chat_bubble, label: '1.2K'),
                          const SizedBox(height: 18),
                          _railAction(icon: Icons.send, label: '8.4K'),
                          const SizedBox(height: 18),
                          const Icon(Icons.more_horiz, color: Colors.white, size: 26),
                          const SizedBox(height: 18),
                          const _SpinningVinyl(),
                        ],
                      ),
                    ),

                    // Bottom creator info
                    Positioned(
                      left: 16,
                      right: 80,
                      bottom: 28,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(colors: [
                                    Colors.amber, Colors.pink, Colors.purple,
                                  ])),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: ClipOval(
                                  child: SmartImage(
                                    url: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDl1UWL27TpEB4kBp5mRFfMt3fWGnqp7eqtByq7lZgtPb4fLVZ1bkjCLV-m_fbuAcx1WjdcssCo8gnuVP7Gvq-yEddxPyf-LI6BdxRSiC2ZS9OeRSDa1bpZ7BJV670VNU1T5WJ0hnTDP8n634qEpmTi9VoLpr2KUO1Ra30dayeUpd4rm1L3PeOYRiqaw9JP0p9p3sme4z9jeGItmRVu9pNKCKNcMDeEs-ROMtlvzVQ',
                                    fallback: [Colors.purple, Colors.black],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text('@midnight.crates',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => setState(() => _following = !_following),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _following ? Colors.white24 : Colors.black38,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white54),
                                ),
                                child: Text(_following ? 'Following' : 'Follow',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          const Text(
                            'Late night vinyl pull in Shibuya — hypnotic synth waves '
                            'echoing over the rooftop 🎧✨ #vinyl #tokyo #nightvibes',
                            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.music_note, size: 15, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Resonance · HOME',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ]),
                          ),
                        ],
                      ),
                    ),

                    // Progress scrubber
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 3,
                        color: Colors.white24,
                        child: FractionallySizedBox(
                          widthFactor: 0.4,
                          alignment: Alignment.centerLeft,
                          child: Container(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassIcon(IconData icon) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.3),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      );

  Widget _railAction({
    required IconData icon,
    required String label,
    Color color = Colors.white,
    bool filled = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Icon(icon, size: 30, color: color),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _SpinningVinyl extends StatefulWidget {
  const _SpinningVinyl();
  @override
  State<_SpinningVinyl> createState() => _SpinningVinylState();
}

class _SpinningVinylState extends State<_SpinningVinyl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 7))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _c,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white54, width: 2),
          color: Colors.black,
        ),
        child: const Center(
          child: CircleAvatar(
            radius: 7,
            backgroundColor: AppColors.primaryContainer,
            child: Icon(Icons.music_note, size: 10, color: AppColors.onPrimary),
          ),
        ),
      ),
    );
  }
}
