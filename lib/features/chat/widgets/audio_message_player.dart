import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioMessagePlayer extends StatefulWidget {
  final String url;
  final bool isMe;

  const AudioMessagePlayer({
    super.key,
    required this.url,
    required this.isMe,
  });

  @override
  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (widget.url.startsWith('http')) {
        await _audioPlayer.play(UrlSource(widget.url));
      } else {
        await _audioPlayer.play(DeviceFileSource(widget.url));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = widget.isMe ? Colors.white : Colors.blueAccent;
    final textColor = widget.isMe ? Colors.white : (isDark ? Colors.white : Colors.black87);

    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: accentColor,
              size: 36,
            ),
            onPressed: _togglePlay,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: accentColor,
                    inactiveTrackColor: accentColor.withValues(alpha: 0.2),
                    thumbColor: accentColor,
                  ),
                  child: Slider(
                    min: 0,
                    max: _duration.inMilliseconds.toDouble() > 0 
                        ? _duration.inMilliseconds.toDouble() 
                        : 1.0,
                    value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0),
                    onChanged: (value) {
                      final duration = Duration(milliseconds: value.toInt());
                      _audioPlayer.seek(duration);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.7)),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 12,
            backgroundColor: accentColor.withValues(alpha: 0.1),
            child: Icon(Icons.mic, size: 14, color: accentColor),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String minutes = duration.inMinutes.toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
