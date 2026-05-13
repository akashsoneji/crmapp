import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import 'package:crm_app/flavor_config.dart';
import '../../../main.dart';

class GoldenfxVideoSplashScreen extends StatefulWidget {
  const GoldenfxVideoSplashScreen({super.key});

  @override
  State<GoldenfxVideoSplashScreen> createState() => _GoldenfxVideoSplashScreenState();
}

class _GoldenfxVideoSplashScreenState extends State<GoldenfxVideoSplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  void _initVideoPlayer() {
    // We strictly use this only for goldenwolffx, but check just to be safe.
    _controller = VideoPlayerController.asset(
      'lib/clients/goldenwolffx/assets/goldenfx_splash_portrait.mp4',
    )..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _controller.play();
        
        // Listen for the video to complete
        _controller.addListener(_videoListener);
      }).catchError((error) {
        print("Error initializing video player: $error");
        // Fallback: if video fails, navigate immediately
        _navigateToNextScreen();
      });
  }

  void _videoListener() {
    if (_controller.value.isInitialized &&
        _controller.value.position >= _controller.value.duration &&
        !_controller.value.isPlaying) {
      _controller.removeListener(_videoListener);
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    // Navigate to AuthCheckScreen to determine the correct next screen based on login status
    Get.offAll(() => const AuthCheckScreen());
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isVideoInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const SizedBox(), // Black screen while initializing
      ),
    );
  }
}
