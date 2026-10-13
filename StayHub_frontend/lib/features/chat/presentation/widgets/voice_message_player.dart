import 'package:flutter/cupertino.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class VoiceMessagePlayer extends StatefulWidget {
  final String url;
  final bool isMe;

  const VoiceMessagePlayer({super.key, required this.url, required this.isMe});

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isInit = false;
  bool _hasError = false;

  // BUGFIX (Bug 47): giữ tham chiếu các subscription để huỷ trong dispose,
  // tránh rò rỉ và callback bắn sau khi widget đã bị huỷ.
  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _subs.add(
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state == PlayerState.playing;
          });
        }
      }),
    );

    _subs.add(
      _audioPlayer.onDurationChanged.listen((newDuration) {
        if (mounted) {
          setState(() {
            _duration = newDuration;
          });
        }
      }),
    );

    _subs.add(
      _audioPlayer.onPositionChanged.listen((newPosition) {
        if (mounted) {
          setState(() {
            _position = newPosition;
          });
        }
      }),
    );

    _subs.add(
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
      }),
    );

    unawaited(_initAudio());
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setSourceUrl(widget.url);
      if (!mounted) return;
      // BUGFIX (Bug 108): trước đây gán `_isInit = true` mà không gọi setState
      // → UI không được rebuild sau khi init thành công (icon/trạng thái lỗi
      // không cập nhật). Gộp vào một setState duy nhất.
      setState(() {
        _isInit = true;
        _hasError = false;
      });
    } catch (e) {
      // BUGFIX (Bug 49): báo lỗi thay vì nuốt lỗi âm thầm (tap không phản hồi).
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    // BUGFIX (Bug 47): huỷ toàn bộ subscription trước khi dispose player.
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
    unawaited(_audioPlayer.dispose());
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.toString().padLeft(2, '0');
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isMe ? CupertinoColors.white : CupertinoColors.black;
    final bgColor = widget.isMe
        ? const Color(0xFFFF8C00).withValues(alpha: 0.2)
        : CupertinoColors.systemGrey5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(maxWidth: 220),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () async {
              // BUGFIX (Bug 48): chặn thao tác trên player đã bị huỷ sau await.
              if (!_isInit) {
                await _initAudio();
                if (!mounted) return;
              }
              if (!_isInit) return; // init thất bại → không phát
              try {
                if (_isPlaying) {
                  await _audioPlayer.pause();
                } else {
                  await _audioPlayer.play(UrlSource(widget.url));
                }
              } catch (e) {
                if (mounted) setState(() => _hasError = true);
              }
            },
            child: Icon(
              // BUGFIX (Bug 49): hiển thị trạng thái lỗi để người dùng biết.
              _hasError
                  ? CupertinoIcons.exclamationmark_circle
                  : (_isPlaying
                        ? CupertinoIcons.pause_circle_fill
                        : CupertinoIcons.play_circle_fill),
              color: _hasError ? CupertinoColors.systemRed : color,
              size: 32,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _duration.inMilliseconds > 0
                        ? (_position.inMilliseconds / _duration.inMilliseconds)
                              .clamp(0.0, 1.0)
                        : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(
                    _position.inMilliseconds > 0 ? _position : _duration,
                  ),
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
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
