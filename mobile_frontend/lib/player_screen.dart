import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// PUBLIC_INTERFACE
class PlayerScreen extends StatefulWidget {
  /// Path or URL to the audio file for playback.
  final String audioSource;
  /// Unique book ID (for saving position per audiobook)
  final String bookId;
  /// Cover image for the book (optionally displayed)
  final String coverImage;
  /// Title of the audiobook
  final String title;
  /// Author/other details (optional)
  final String details;

  const PlayerScreen({
    Key? key,
    required this.audioSource,
    required this.bookId,
    required this.title,
    required this.coverImage,
    required this.details,
  }) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayer _audioPlayer;
  StreamSubscription<Duration>? _positionSubscription;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _loading = true;
  bool _userSeeking = false;

  static String _positionKey(String bookId) => 'audiobook_position_$bookId';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (!_userSeeking) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _initAudio();
  }

  Future<void> _initAudio() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPosition = prefs.getInt(_positionKey(widget.bookId)) ?? 0;

    try {
      await _audioPlayer.setUrl(widget.audioSource);
      final duration = _audioPlayer.duration ?? Duration.zero;

      setState(() {
        _totalDuration = duration;
        _loading = false;
      });

      if (lastPosition > 0 && lastPosition < duration.inMilliseconds) {
        await _audioPlayer.seek(Duration(milliseconds: lastPosition));
        setState(() {
          _currentPosition = Duration(milliseconds: lastPosition);
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      // Optionally show a user error message for audio load failure
    }

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _savePlaybackPosition(Duration.zero);
      }
      setState(() {});
    });
  }

  Future<void> _togglePlayPause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
    setState(() {});
  }

  Future<void> _seekRelative(int millis) async {
    final newPosition = _currentPosition + Duration(milliseconds: millis);
    final clamped = newPosition < Duration.zero
        ? Duration.zero
        : (newPosition > _totalDuration ? _totalDuration : newPosition);
    await _audioPlayer.seek(clamped);
    setState(() {
      _currentPosition = clamped;
    });
    await _savePlaybackPosition(clamped);
  }

  Future<void> _savePlaybackPosition(Duration position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_positionKey(widget.bookId), position.inMilliseconds);
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String mins = twoDigits(d.inMinutes.remainder(60));
    String secs = twoDigits(d.inSeconds.remainder(60));
    return "${d.inHours > 0 ? '${twoDigits(d.inHours)}:' : ''}$mins:$secs";
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _seekBar() {
    return Column(
      children: [
        Slider(
          min: 0,
          max: _totalDuration.inMilliseconds.toDouble(),
          value: _currentPosition.inMilliseconds.toDouble().clamp(0.0, _totalDuration.inMilliseconds.toDouble()),
          onChangeStart: (value) {
            setState(() {
              _userSeeking = true;
            });
          },
          onChanged: (value) {
            setState(() {
              _currentPosition = Duration(milliseconds: value.toInt());
            });
          },
          onChangeEnd: (value) async {
            final position = Duration(milliseconds: value.toInt());
            await _audioPlayer.seek(position);
            await _savePlaybackPosition(position);
            setState(() {
              _userSeeking = false;
            });
          },
          activeColor: Theme.of(context).colorScheme.primary,
          thumbColor: Theme.of(context).colorScheme.secondary,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_currentPosition), style: const TextStyle(fontSize: 12)),
              Text(_formatDuration(_totalDuration), style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey[600]),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                CircleAvatar(
                  radius: 80,
                  backgroundImage: NetworkImage(widget.coverImage),
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(height: 16),
                Text(widget.title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(widget.details,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                _seekBar(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 36,
                      icon: Icon(Icons.replay_10),
                      tooltip: 'Back 15s',
                      onPressed: () => _seekRelative(-15000),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _togglePlayPause,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                        backgroundColor: theme.colorScheme.primary,
                      ),
                      child: Icon(
                        _audioPlayer.playing ? Icons.pause : Icons.play_arrow,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      iconSize: 36,
                      icon: Icon(Icons.forward_10),
                      tooltip: 'Forward 15s',
                      onPressed: () => _seekRelative(15000),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _audioPlayer.playing ? "Playing" : "Paused",
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
              ],
            ),
    );
  }
}
