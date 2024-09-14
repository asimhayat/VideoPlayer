import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isDragging = false;
  bool _isPlaying = false;
  bool _isFullScreen = false;
  bool _areControlsVisible = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network('')
      ..initialize().then((_) {
        setState(() {
          _duration = _controller.value.duration;
          _isPlaying = _controller.value.isPlaying;
        });
        _controller.addListener(_updatePosition);
      });
  }

  void _updatePosition() {
    if (!_isDragging) {
      setState(() {
        _position = _controller.value.position;
        if (_position > _duration) {
          _position = _duration;
        }
      });
    }
  }

  Future<void> pickFile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        _controller.dispose();
        _controller = VideoPlayerController.file(File(path))
          ..initialize().then((_) {
            setState(() {
              _duration = _controller.value.duration;
              _isPlaying = _controller.value.isPlaying;
            });
            _controller.addListener(_updatePosition);
          }).catchError((error) {
            setState(() {
              _hasError = true;
            });
          });
      }
    } catch (e, stackTrace) {
      print("Error picking file: $e");
      print(stackTrace);
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller.removeListener(_updatePosition);
    _controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '${d.inHours > 0 ? '${twoDigits(d.inHours)}:' : ''}$minutes:$seconds';
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
      _isPlaying = !_isPlaying;
    });
    _showControls();
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      if (_isFullScreen) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeRight,
          DeviceOrientation.landscapeLeft,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      }
      _showControls();
    });
  }

  void _showControls() {
    setState(() {
      _areControlsVisible = true;
    });

    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 1), () {
      if (!_isDragging) {
        setState(() {
          _areControlsVisible = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final minimizedHeight = screenHeight / 1.5;
    final fullScreenHeight = screenHeight;
    final fullScreenWidth = screenWidth;

    return Scaffold(
      backgroundColor: Colors.black, // Change Scaffold background to black
      appBar: !_isFullScreen
          ? AppBar(
              centerTitle: true,
              backgroundColor: Colors.black,
              title: const Text(
                "VideoPlayer created by Asim",
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            )
          : null,
      body: GestureDetector(
        onTap: _showControls,
        child: Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  const CircularProgressIndicator(
                    color: Colors.orange,
                  ),
                if (_hasError)
                  const Text(
                    'An error occurred. Please try again.',
                    style: TextStyle(color: Colors.red),
                  ),
                if (!_isLoading &&
                    !_hasError &&
                    _controller.value.isInitialized)
                  Stack(
                    children: [
                      Container(
                        color:
                            Colors.black, // Set the background color to black
                        height:
                            _isFullScreen ? fullScreenHeight : minimizedHeight,
                        width:
                            _isFullScreen ? fullScreenWidth : double.infinity,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _controller.value.size.width,
                            height: _controller.value.size.height,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      ),
                      if (_areControlsVisible)
                        Positioned(
                          bottom: 39.5,
                          left: 0,
                          right: 0,
                          child: Container(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.replay_10,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          Duration newPosition = _position -
                                              const Duration(seconds: 10);
                                          if (newPosition < Duration.zero) {
                                            newPosition = Duration.zero;
                                          }
                                          _controller.seekTo(newPosition);
                                          _showControls();
                                        },
                                        iconSize: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          _isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: _togglePlayPause,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.forward_10,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          Duration newPosition = _position +
                                              const Duration(seconds: 10);
                                          if (newPosition > _duration) {
                                            newPosition = _duration;
                                          }
                                          _controller.seekTo(newPosition);
                                          _showControls();
                                        },
                                        iconSize: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          _isFullScreen
                                              ? Icons.fullscreen_exit
                                              : Icons.fullscreen,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: _toggleFullScreen,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_duration != Duration.zero)
                                  Column(
                                    children: [
                                      Slider(
                                        min: 0.0,
                                        max: _duration.inSeconds.toDouble(),
                                        value: _position.inSeconds
                                            .toDouble()
                                            .clamp(0.0,
                                                _duration.inSeconds.toDouble()),
                                        onChanged: (value) {
                                          setState(() {
                                            _isDragging = true;
                                            _position = Duration(
                                                seconds: value.toInt());
                                          });
                                          _showControls();
                                        },
                                        onChangeEnd: (value) {
                                          _controller.seekTo(
                                              Duration(seconds: value.toInt()));
                                          setState(() {
                                            _isDragging = false;
                                          });
                                          _showControls();
                                        },
                                        activeColor: Colors.orange,
                                        inactiveColor:
                                            Colors.orange.withOpacity(0.3),
                                        thumbColor: Colors.orange,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 25.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0,
                                                      vertical: 4.0),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withOpacity(0.5),
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                              ),
                                              child: Text(
                                                formatDuration(_position),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0,
                                                      vertical: 4.0),
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withOpacity(0.5),
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                              ),
                                              child: Text(
                                                formatDuration(
                                                    _duration - _position),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: pickFile,
                  child: const Text(
                    "Pick Video File",
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
