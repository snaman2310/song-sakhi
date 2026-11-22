import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets.dart';

class ConfirmationScreen extends StatelessWidget {
  final int addedCount;
  final String playlistName;
  const ConfirmationScreen({
    this.addedCount = 3,
    this.playlistName = 'Late Night Vibes',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          const GlowBackdrop(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.12),
                    boxShadow: const [BoxShadow(color: Color(0x5533E076), blurRadius: 40)],
                  ),
                  child: const Icon(Icons.check_circle,
                      color: AppColors.primary, size: 72),
                ),
                const SizedBox(height: 28),
                Text('All saved!', style: AppText.headlineLarge(AppColors.onSurface)),
                const SizedBox(height: 12),
                Text(
                  'Added $addedCount songs to "$playlistName" playlist',
                  style: AppText.bodyMedium(AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                    icon: const Icon(Icons.arrow_right_alt),
                    label: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
