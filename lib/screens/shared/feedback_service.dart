import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class FeedbackService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // Hàm tạo rung nhẹ
  static void lightImpact(BuildContext context) {
    HapticFeedback.lightImpact();
  }

  // Hàm phát âm thanh (giả sử bạn có file 'sounds/ui_tap.mp3' trong assets)
  static void playSound(BuildContext context) {
    // Bạn có thể thay đổi đường dẫn file âm thanh tại đây
    _audioPlayer.play(AssetSource('sounds/ui_tap.mp3'));
  }
}