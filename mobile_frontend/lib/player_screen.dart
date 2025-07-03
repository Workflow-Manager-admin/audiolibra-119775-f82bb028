import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// PUBLIC_INTERFACE
class PlayerScreen extends StatefulWidget {
  final String bookId;
  final String title;
  final String author;
  final String coverUrl;
  final String audioUrl;
  final bool isOwned; // Only owned books can play 

  /// PUBLIC_INTERFACE
  /// Creates the PlayerScreen for a specific audiobook.
  /// [bookId] - unique identifier for the audiobook, used to persist position.
  /// [title] - book title.
  /// [author] - book author.
  /// [coverUrl] - cover image URL.
  /// [audioUrl] - audio file URL.
  /// [isOwned] - whether the current user owns this book.
  const PlayerScreen({
    super.key,
    required this.bookId,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.audioUrl,
    required this.isOwned,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayer _audioPlayer;
  Duration _currentPosition = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = true;
  late SharedPreferences _prefs;

  // Constants for seeking intervals
  static const Duration skipInterval = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initPlayer();
    _listenToEvents();
  }

  @override
  void dispose() {
    _savePosition();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    _prefs = await SharedPreferences.getInstance();

    try {
      await _audioPlayer.setUrl(widget.audioUrl);
      _duration = _audioPlayer.duration ?? Duration.zero;
      Duration? resumePos = _getSavedPosition();
      if (resumePos != null && resumePos < _duration && resumePos > Duration(seconds: 4)) {
        await _audioPlayer.seek(resumePos);
        _currentPosition = resumePos;
      }
    } catch (e) {
      // Handle audio load failure
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Failed to load audio."),
          backgroundColor: Colors.red,
        ));
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _listenToEvents() {
    _audioPlayer.positionStream.listen((pos) {
      if (mounted) {
        setState(() {
          _currentPosition = pos;
        });
      }
    });
    _audioPlayer.playerStateStream.listen((playerState) {
      if (mounted) {
        setState(() {
          _isPlaying = playerState.playing;
          if (playerState.processingState == ProcessingState.completed) {
            _audioPlayer.seek(Duration.zero);
            _audioPlayer.pause();
          }
        });
      }
    });
    _audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _duration = duration;
        });
      }
    });
  }

  Duration? _getSavedPosition() {
    final intMillis = _prefs.getInt('pos_${widget.bookId}');
    if (intMillis != null) {
      return Duration(milliseconds: intMillis);
    }
    return null;
  }

  Future<void> _savePosition() async {
    final int pos = _currentPosition.inMilliseconds;
    await _prefs.setInt('pos_${widget.bookId}', pos);
  }

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes % 60)}:${twoDigits(d.inSeconds % 60)}";
    } else {
      return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds % 60)}";
    }
  }

  void _onSeek(double value) async {
    final pos = Duration(milliseconds: value.toInt());
    await _audioPlayer.seek(pos);
    setState(() {
      _currentPosition = pos;
    });
  }

  // Accessibility: Focus nodes & semantics for key controls
  final FocusNode _playPauseFocusNode = FocusNode();
  final FocusNode _seekBackFocusNode = FocusNode();
  final FocusNode _seekFwdFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Prevent unowned users from playing
    if (!widget.isOwned) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Audiobook Player"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text("You must purchase this book\nto access playback.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(); // Go back to store
                  },
                  icon: const Icon(Icons.store),
                  label: const Text("Go to Store"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: theme.colorScheme.primary,
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Cover art
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        widget.coverUrl,
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          width: 180,
                          height: 180,
                          color: Colors.grey[300],
                          child: const Icon(Icons.headphones, size: 64),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Book details
                  Text(
                    widget.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.author,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Seek bar
                  Semantics(
                    label: "Seek bar",
                    child: Column(
                      children: [
                        Slider(
                          value: _currentPosition.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble()),
                          min: 0.0,
                          max: _duration.inMilliseconds.toDouble() > 0
                              ? _duration.inMilliseconds.toDouble()
                              : 1.0,
                          onChanged: (value) => _onSeek(value),
                          activeColor: theme.colorScheme.primary,
                          // Fix deprecated .withOpacity by using .withAlpha
                          inactiveColor: theme.colorScheme.primary.withAlpha((0.25 * 255).toInt()),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatTime(_currentPosition),
                                style: const TextStyle(fontSize: 14)),
                            Text(_formatTime(_duration),
                                style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  // Playback controls (skip, play/pause, skip)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Skip back 15s
                      Semantics(
                        button: true,
                        label: "Skip backward 15 seconds",
                        child: IconButton(
                          focusNode: _seekBackFocusNode,
                          icon: Icon(Icons.replay_10, size: 38), // fallback: replay_10
                          splashRadius: 28,
                          color: theme.colorScheme.primary,
                          tooltip: "Rewind 15 seconds",
                          onPressed: () async {
                            final newPos = _currentPosition - skipInterval;
                            await _audioPlayer.seek(
                              newPos < Duration.zero ? Duration.zero : newPos,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 21),
                      // Play/Pause
                      Semantics(
                        button: true,
                        label: _isPlaying ? "Pause" : "Play",
                        child: FloatingActionButton(
                          focusNode: _playPauseFocusNode,
                          heroTag: "playpause_btn",
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          onPressed: () async {
                            if (_isPlaying) {
                              await _audioPlayer.pause();
                            } else {
                              await _audioPlayer.play();
                            }
                            _savePosition();
                          },
                          tooltip: _isPlaying ? "Pause" : "Play",
                          child: Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 42,
                          ),
                        ),
                      ),
                      const SizedBox(width: 21),
                      // Skip forward 15s
                      Semantics(
                        button: true,
                        label: "Skip forward 15 seconds",
                        child: IconButton(
                          focusNode: _seekFwdFocusNode,
                          icon: Icon(Icons.forward_10, size: 38), // fallback: forward_10
                          splashRadius: 28,
                          color: theme.colorScheme.primary,
                          tooltip: "Forward 15 seconds",
                          onPressed: () async {
                            final newPos = _currentPosition + skipInterval;
                            await _audioPlayer.seek(newPos > _duration ? _duration : newPos);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Resume/persisted position info
                  if (_currentPosition > Duration(seconds: 0))
                    Text(
                      "Position saved at ${_formatTime(_currentPosition)}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                  const Spacer(),
                  // Back/close button or nav
                  ElevatedButton.icon(
                    onPressed: () {
                      _savePosition();
                      Navigator.of(context).maybePop();
                    },
                    icon: Icon(Icons.arrow_back),
                    label: const Text("Back"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }
}
