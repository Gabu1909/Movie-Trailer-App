import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

class LocalPlayerScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const LocalPlayerScreen(
      {super.key, required this.filePath, required this.title});

  @override
  State<LocalPlayerScreen> createState() => _LocalPlayerScreenState();
}

class _LocalPlayerScreenState extends State<LocalPlayerScreen> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  late Future<void> _initializeVideoPlayerFuture;
  bool _isDisposed = false;
  Future<ClosedCaptionFile>? _subtitlesFuture;
  bool _areSubtitlesVisible = false;

  // Biến cho hiệu ứng animation khi tua video
  int _seekAnimationKey = 0;
  IconData? _seekIcon;

  // Biến cho cài đặt phụ đề
  double _subtitleFontSize = 16.0;
  Color _subtitleColor = Colors.white;

  // Biến trạng thái toàn màn hình
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();

    // Tự động tìm và tải tệp phụ đề nếu có
    _subtitlesFuture = _loadSubtitleFile();

    _controller = VideoPlayerController.file(File(widget.filePath));
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      // Gán phụ đề cho controller sau khi khởi tạo
      _controller.setClosedCaptionFile(_subtitlesFuture);
      _controller.play();
      _startHideControlsTimer(); // Bắt đầu đếm ngược để ẩn controls
    });

    _controller.addListener(() {
      if (!_isDisposed) {
        setState(() {});
      }
    });
  }

  // Hàm để tìm và tải tệp phụ đề (.srt)
  Future<ClosedCaptionFile>? _loadSubtitleFile() {
    final videoPath = widget.filePath;
    final srtPath = '${videoPath.substring(0, videoPath.lastIndexOf('.'))}.srt';
    final srtFile = File(srtPath);

    if (srtFile.existsSync()) {
      debugPrint('Subtitle file found: $srtPath');
      return Future.value(SubRipCaptionFile(srtFile.readAsStringSync()));
    }
    debugPrint('No subtitle file found for: $videoPath');
    return null;
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4),
        () => setState(() => _showControls = false));
  }

  @override
  void dispose() {
    // Khôi phục lại UI hệ thống khi thoát
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);

    // Trả lại các hướng màn hình mặc định khi thoát
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _hideControlsTimer?.cancel();
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Sử dụng FutureBuilder để đảm bảo video chỉ hiển thị khi đã sẵn sàng
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // Nếu video đã sẵn sàng, hiển thị VideoPlayer
            return Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    VideoPlayer(_controller),
                    _buildControlsOverlay(context),
                  ],
                ),
              ),
            );
          } else {
            // Nếu chưa, hiển thị vòng xoay chờ
            return const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent),
            );
          }
        },
      ),
    );
  }

  Widget _buildControlsOverlay(BuildContext context) {
    return Stack(
      children: [
        // Lớp GestureDetector cho việc tua video bằng double-tap
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onDoubleTap: () {
                  setState(() {
                    _seekAnimationKey++; // Thay đổi key để trigger animation
                    _seekIcon = Icons.replay_10;
                  });
                  _seekBackward();
                },
                onTap: _toggleControls,
                child: Container(color: Colors.transparent),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onDoubleTap: () {
                  setState(() {
                    _seekAnimationKey++;
                    _seekIcon = Icons.forward_10;
                  });
                  _seekForward();
                },
                onTap: _toggleControls,
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        ),

        // Hiệu ứng animation khi tua
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: _seekIcon == null
                ? const SizedBox.shrink()
                : Icon(_seekIcon,
                    key: ValueKey(_seekAnimationKey),
                    color: Colors.white,
                    size: 50),
          ),
        ),

        // Hiển thị phụ đề nếu được bật
        if (_areSubtitlesVisible && _controller.value.caption.text != null)
          Positioned(
            bottom: 80, // Đặt vị trí cho phụ đề
            left: 20,
            right: 20,
            child: Center(
              child: ClosedCaption(
                text: _controller.value.caption.text,
                textStyle: TextStyle(
                  color: _subtitleColor,
                  fontSize: _subtitleFontSize,
                  shadows: const [
                    Shadow(
                        blurRadius: 2,
                        color: Colors.black,
                        offset: Offset(1, 1))
                  ],
                ),
              ),
            ),
          ),
        // Lớp hiển thị các nút điều khiển
        IgnorePointer(
          ignoring: !_showControls,
          child: AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              color: Colors.black26,
              child: Stack(
                children: [
                  // Nút quay về
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 24),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  // Hàng chứa các nút chức năng ở trên bên phải
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Row(
                      children: [
                        // Nút Phụ đề
                        if (_subtitlesFuture != null)
                          IconButton(
                            icon: Icon(
                              _areSubtitlesVisible
                                  ? Icons.closed_caption
                                  : Icons.closed_caption_off_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: _showSubtitleSettings,
                          ),
                        // Nút Chất lượng
                        IconButton(
                          icon: const Icon(Icons.hd,
                              color: Colors.white, size: 28),
                          onPressed: _showQualityInfo,
                        ),
                        // Nút Fullscreen
                        IconButton(
                          icon: Icon(
                              _isFullScreen
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
                              color: Colors.white,
                              size: 28),
                          onPressed: _toggleFullScreen,
                        ),
                      ],
                    ),
                  ),
                  // Các nút điều khiển ở giữa
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Nút tua lại 10s
                        IconButton(
                          icon: const Icon(Icons.replay_10,
                              color: Colors.white, size: 40.0),
                          onPressed: _seekBackward,
                        ),
                        const SizedBox(width: 40),
                        // Nút Play/Pause
                        IconButton(
                          icon: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Colors.white,
                            size: 80.0,
                          ),
                          onPressed: () {
                            setState(() {
                              _controller.value.isPlaying
                                  ? _controller.pause()
                                  : _controller.play();
                              _startHideControlsTimer();
                            });
                          },
                        ),
                        const SizedBox(width: 40),
                        // Nút tua tới 10s
                        IconButton(
                          icon: const Icon(Icons.forward_10,
                              color: Colors.white, size: 40.0),
                          onPressed: _seekForward,
                        ),
                      ],
                    ),
                  ),
                  // Thanh tiến trình và thời gian ở dưới
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        Text(_formatDuration(_controller.value.position),
                            style: const TextStyle(color: Colors.white)),
                        const SizedBox(width: 10),
                        Expanded(
                          // Bọc trong Builder để lấy đúng context
                          child: Builder(builder: (context) {
                            return VideoProgressIndicator(
                              _controller,
                              allowScrubbing: true,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              colors: const VideoProgressColors(
                                playedColor: Colors.pinkAccent,
                                bufferedColor: Colors.white54,
                                backgroundColor: Colors.white24,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(width: 10),
                        Text(_formatDuration(_controller.value.duration),
                            style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _startHideControlsTimer();
      } else {
        _hideControlsTimer?.cancel();
      }
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        // Vào chế độ toàn màn hình
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        // Thoát chế độ toàn màn hình
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
            overlays: SystemUiOverlay.values);
      }
      _startHideControlsTimer();
    });
  }

  void _seekBackward() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    _controller
        .seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
    _startHideControlsTimer(); // Reset lại timer ẩn controls
  }

  void _seekForward() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition + const Duration(seconds: 10);
    final duration = _controller.value.duration;
    _controller.seekTo(newPosition > duration ? duration : newPosition);
    _startHideControlsTimer(); // Reset lại timer ẩn controls
  }

  void _showQualityInfo() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Playing from local file. Quality cannot be changed.'),
      backgroundColor: Colors.pinkAccent,
    ));
    _startHideControlsTimer();
  }

  void _showSubtitleSettings() {
    _hideControlsTimer?.cancel(); // Tạm dừng timer ẩn controls
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1D0B3C),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('Subtitles',
                        style: TextStyle(color: Colors.white)),
                    value: _areSubtitlesVisible,
                    onChanged: (bool value) {
                      setModalState(() => _areSubtitlesVisible = value);
                      setState(() {}); // Cập nhật UI chính
                    },
                    activeColor: Colors.pinkAccent,
                  ),
                  const Divider(color: Colors.white24),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Text Size',
                        style: TextStyle(color: Colors.white70)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ChoiceChip(
                        label: const Text('Small'),
                        selected: _subtitleFontSize == 14.0,
                        onSelected: (selected) =>
                            setModalState(() => _subtitleFontSize = 14.0),
                        selectedColor: Colors.pinkAccent,
                      ),
                      ChoiceChip(
                        label: const Text('Medium'),
                        selected: _subtitleFontSize == 16.0,
                        onSelected: (selected) =>
                            setModalState(() => _subtitleFontSize = 16.0),
                        selectedColor: Colors.pinkAccent,
                      ),
                      ChoiceChip(
                        label: const Text('Large'),
                        selected: _subtitleFontSize == 20.0,
                        onSelected: (selected) =>
                            setModalState(() => _subtitleFontSize = 20.0),
                        selectedColor: Colors.pinkAccent,
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Text Color',
                        style: TextStyle(color: Colors.white70)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildColorChip(setModalState, Colors.white),
                      _buildColorChip(setModalState, Colors.yellow),
                      _buildColorChip(setModalState, Colors.cyan),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _startHideControlsTimer(); // Bắt đầu lại timer khi đóng bottom sheet
    });
  }

  Widget _buildColorChip(StateSetter setModalState, Color color) {
    bool isSelected = _subtitleColor == color;
    return GestureDetector(
      onTap: () => setModalState(() => _subtitleColor = color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.pinkAccent, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return [
        twoDigits(hours),
        twoDigits(minutes),
        twoDigits(seconds),
      ].join(':');
    } else {
      return [twoDigits(minutes), twoDigits(seconds)].join(':');
    }
  }
}
