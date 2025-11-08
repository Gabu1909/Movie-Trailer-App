import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class FeedbackService {
  static void playSound(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    if (settings.soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  static void lightImpact(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    if (settings.hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }
}