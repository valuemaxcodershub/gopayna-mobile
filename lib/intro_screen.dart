import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'onboard_screen.dart';
import 'login.dart';

// Consolidated onboarding screens: LoadingPage, IntroScreenOne, IntroScreenTwo
const Color _brandColor = Color.fromARGB(255, 4, 219, 58);

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progressAnim;
  late final Animation<double> _orbitRotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 6000));
    _progressAnim =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _orbitRotation = Tween<double>(begin: 0, end: 4 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const IntroScreenOne()));
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 48 : 24,
            vertical: isTablet ? 32 : 24,
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'GoPayna',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    fontSize: isTablet ? 18 : 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _orbitRotation,
                    builder: (context, child) {
                      final orbitSize = isTablet ? 280.0 : 220.0;
                      final radius = orbitSize / 2 - 20;
                      final angle = _orbitRotation.value;
                      final dx = radius * math.cos(angle);
                      final dy = radius * math.sin(angle);

                      return SizedBox(
                        width: orbitSize,
                        height: orbitSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: orbitSize,
                              height: orbitSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _brandColor.withValues(alpha: 0.25),
                                  width: 2,
                                ),
                              ),
                            ),
                            Container(
                              width: orbitSize * 0.75,
                              height: orbitSize * 0.75,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    _brandColor.withValues(alpha: 0.25),
                                    _brandColor.withValues(alpha: 0.05),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _brandColor.withValues(alpha: 0.25),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: orbitSize * 0.45,
                              height: orbitSize * 0.45,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: _brandColor.withValues(alpha: 0.25),
                                    blurRadius: 30,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                                border: Border.all(
                                  color: _brandColor.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                              ),
                              padding: EdgeInsets.all(isTablet ? 24 : 18),
                              child: Image.asset(
                                'assets/logogreen.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            Transform.translate(
                              offset: Offset(dx, dy),
                              child: Container(
                                width: isTablet ? 26 : 22,
                                height: isTablet ? 26 : 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _brandColor.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        _brandColor,
                                        _brandColor.withValues(alpha: 0.6),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _progressAnim,
                builder: (context, _) {
                  final percent = (_progressAnim.value * 100).clamp(0, 100);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      IgnorePointer(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: isTablet ? 10 : 8,
                            activeTrackColor: _brandColor,
                            inactiveTrackColor:
                                _brandColor.withValues(alpha: 0.2),
                            thumbShape: RoundSliderThumbShape(
                                enabledThumbRadius: isTablet ? 10 : 8),
                            overlayShape: SliderComponentShape.noOverlay,
                          ),
                          child: Slider(
                            value: _progressAnim.value,
                            min: 0,
                            max: 1,
                            onChanged: (_) {},
                          ),
                        ),
                      ),
                      SizedBox(height: isTablet ? 20 : 12),
                      Text(
                        'Loading ${percent.toStringAsFixed(0)}%',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Setting up your dashboard experience',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: isTablet ? 16 : 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IntroScreenOne extends StatefulWidget {
  const IntroScreenOne({super.key});

  @override
  State<IntroScreenOne> createState() => _IntroScreenOneState();
}

class _IntroScreenOneState extends State<IntroScreenOne>
    with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _imageController;
  late final AnimationController _textController;
  late final AnimationController _buttonController;

  late final Animation<double> _backgroundScale;
  late final Animation<double> _backgroundRotation;
  late final Animation<double> _imageScale;
  late final Animation<Offset> _imageSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _descriptionFade;
  late final Animation<Offset> _descriptionSlide;
  late final Animation<double> _buttonsFade;
  late final Animation<Offset> _buttonsSlide;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with staggered timing
    _backgroundController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _imageController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _textController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _buttonController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));

    // Background animations
    _backgroundScale = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(
            parent: _backgroundController, curve: Curves.easeOutCubic));
    _backgroundRotation = Tween<double>(begin: -0.3, end: 0.2).animate(
        CurvedAnimation(
            parent: _backgroundController, curve: Curves.easeOutCubic));

    // Image animations (start immediately)
    _imageScale = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(
        parent: _imageController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)));
    _imageSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _imageController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)));

    // Text animations (delayed start)
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut)));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _textController,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic)));

    _descriptionFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _textController,
            curve: const Interval(0.4, 0.9, curve: Curves.easeOut)));
    _descriptionSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _textController,
                curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic)));

    // Button animations (latest start)
    _buttonsFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _buttonController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut)));
    _buttonsSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _buttonController,
            curve: const Interval(0.6, 1.0, curve: Curves.elasticOut)));

    // Start animations immediately
    _backgroundController.forward();
    _imageController.forward();
    _textController.forward();
    _buttonController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _imageController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Animated diagonal green curved background from top-left
            AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return Positioned(
                  top: -100,
                  left: -150,
                  child: Transform.rotate(
                    angle: _backgroundRotation.value, // Animated rotation
                    child: Transform.scale(
                      scale: _backgroundScale.value, // Animated scale
                      child: Container(
                        width: size.width * 1.2,
                        height: size.height * 0.7,
                        decoration: BoxDecoration(
                          color: _brandColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(size.width * 0.6),
                            topRight: Radius.circular(size.width * 0.3),
                            bottomLeft: Radius.circular(size.width * 0.4),
                            bottomRight: Radius.circular(size.width * 1.0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _brandColor.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Main content
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 24, vertical: isTablet ? 24 : 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: isTablet ? 32 : 24),

                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: _goToLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _brandColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 24 : 18,
                                  vertical: isTablet ? 14 : 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.flash_on),
                              label: Text(
                                'Fast Start',
                                style: TextStyle(
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isTablet ? 24 : 20),

                          // Animated Phone Image
                          SlideTransition(
                            position: _imageSlide,
                            child: ScaleTransition(
                              scale: _imageScale,
                              child: SizedBox(
                                width: isTablet ? 300 : 280,
                                height: isTablet ? 350 : 320,
                                child: Image.asset(
                                  'assets/handsheldphones.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isTablet ? 32 : 24),

                          // Animated Title
                          SlideTransition(
                            position: _titleSlide,
                            child: FadeTransition(
                              opacity: _titleFade,
                              child: Text(
                                'Get Fast Data',
                                style: TextStyle(
                                  fontSize: isTablet ? 32 : 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),

                          SizedBox(height: isTablet ? 20 : 16),

                          // Animated Description
                          SlideTransition(
                            position: _descriptionSlide,
                            child: FadeTransition(
                              opacity: _descriptionFade,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: isTablet ? 350 : 300,
                                ),
                                child: Text(
                                  'Running low on data? Recharge instantly with GoPayna. Whether it\'s MTN, Airtel, Glo, or 9mobile, you\'ll get connected in seconds without stress or delay.',
                                  style: TextStyle(
                                    fontSize: isTablet ? 16 : 15,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey.shade600,
                                    height: 1.5,
                                    letterSpacing: 0.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isTablet ? 32 : 24),

                          // Animated Buttons
                          SlideTransition(
                            position: _buttonsSlide,
                            child: FadeTransition(
                              opacity: _buttonsFade,
                              child: Row(
                                children: [
                                  // Back/Skip Button
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      height: isTablet ? 56 : 52,
                                      decoration: BoxDecoration(
                                        color: _brandColor,
                                        borderRadius: BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _brandColor.withValues(
                                                alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(28),
                                          onTap: () =>
                                              Navigator.of(context).pop(),
                                          child: const Center(
                                            child: Icon(
                                              Icons.arrow_back_rounded,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  // Next Button
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      height: isTablet ? 56 : 52,
                                      decoration: BoxDecoration(
                                        color: _brandColor,
                                        borderRadius: BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _brandColor.withValues(
                                                alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(28),
                                          onTap: () => Navigator.of(context)
                                              .push(MaterialPageRoute(
                                                  builder: (_) =>
                                                      const IntroScreenTwo())),
                                          child: const Center(
                                            child: Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: isTablet ? 32 : 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IntroScreenTwo extends StatefulWidget {
  const IntroScreenTwo({super.key});

  @override
  State<IntroScreenTwo> createState() => _IntroScreenTwoState();
}

class _IntroScreenTwoState extends State<IntroScreenTwo>
    with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _imageController;
  late final AnimationController _textController;
  late final AnimationController _buttonController;

  late final Animation<double> _backgroundFlip;
  late final Animation<double> _backgroundSlide;
  late final Animation<double> _imageScale;
  late final Animation<Offset> _imageSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _descriptionFade;
  late final Animation<Offset> _descriptionSlide;
  late final Animation<double> _buttonsFade;
  late final Animation<Offset> _buttonsSlide;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _backgroundController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _imageController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _textController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _buttonController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    // Background flip animation (green flips from left to right with rotation)
    _backgroundFlip = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _backgroundController,
            curve: const Interval(0.0, 0.7, curve: Curves.easeInOutCubic)));

    _backgroundSlide = Tween<double>(begin: -1.5, end: 0.0).animate(
        CurvedAnimation(
            parent: _backgroundController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)));

    // Image animations
    _imageScale = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(
        parent: _imageController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut)));
    _imageSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _imageController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)));

    // Text animations
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut)));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _textController,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic)));

    _descriptionFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _textController,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));
    _descriptionSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _textController,
                curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic)));

    // Button animations
    _buttonsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _buttonController, curve: Curves.easeOut));
    _buttonsSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _buttonController, curve: Curves.elasticOut));

    // Start animations immediately
    _backgroundController.forward();
    _imageController.forward();
    _textController.forward();
    _buttonController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _imageController.dispose();
    _textController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Animated diagonal green curved background (flipped from left to right)
            AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return Positioned(
                  top: -100 + (_backgroundSlide.value * 50),
                  right: -150 + (_backgroundSlide.value * 100),
                  child: Transform.rotate(
                    angle:
                        -0.2 + (_backgroundFlip.value * 0.4), // Flip rotation
                    child: Transform.scale(
                      scale: 0.8 + (_backgroundFlip.value * 0.2),
                      child: Container(
                        width: size.width * 1.2,
                        height: size.height * 0.7,
                        decoration: BoxDecoration(
                          color: _brandColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(size.width * 1.0),
                            topRight: Radius.circular(size.width * 0.6),
                            bottomLeft: Radius.circular(size.width * 0.3),
                            bottomRight: Radius.circular(size.width * 0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _brandColor.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Main content
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 24, vertical: isTablet ? 24 : 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: isTablet ? 32 : 24),

                          // Animated Illustration Image
                          SlideTransition(
                            position: _imageSlide,
                            child: ScaleTransition(
                              scale: _imageScale,
                              child: SizedBox(
                                width: isTablet ? 300 : 280,
                                height: isTablet ? 350 : 320,
                                child: kIsWeb
                                    ? Image.network(
                                        'assets/illustration2.png',
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Image.asset(
                                            'assets/illustration2.png',
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    size: 64,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      )
                                    : Image.asset(
                                        'assets/illustration2.png',
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                size: 64,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ),

                          SizedBox(height: isTablet ? 32 : 24),

                          // Animated Title
                          SlideTransition(
                            position: _titleSlide,
                            child: FadeTransition(
                              opacity: _titleFade,
                              child: Text(
                                'Payments Made Easy',
                                style: TextStyle(
                                  fontSize: isTablet ? 32 : 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),

                          SizedBox(height: isTablet ? 20 : 16),

                          // Animated Description
                          SlideTransition(
                            position: _descriptionSlide,
                            child: FadeTransition(
                              opacity: _descriptionFade,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: isTablet ? 350 : 300,
                                ),
                                child: Text(
                                  'Enjoy stress-free transactions with GoPayna. Fast, secure, and designed to make every payment effortless.',
                                  style: TextStyle(
                                    fontSize: isTablet ? 16 : 15,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey.shade600,
                                    height: 1.5,
                                    letterSpacing: 0.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: isTablet ? 32 : 24),

                          // Animated Buttons
                          SlideTransition(
                            position: _buttonsSlide,
                            child: FadeTransition(
                              opacity: _buttonsFade,
                              child: Row(
                                children: [
                                  // Back Button
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      height: isTablet ? 56 : 52,
                                      decoration: BoxDecoration(
                                        color: _brandColor,
                                        borderRadius: BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _brandColor.withValues(
                                                alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(28),
                                          onTap: () =>
                                              Navigator.of(context).pop(),
                                          child: const Center(
                                            child: Icon(
                                              Icons.arrow_back_rounded,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  // Get Started Button
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      height: isTablet ? 56 : 52,
                                      decoration: BoxDecoration(
                                        color: _brandColor,
                                        borderRadius: BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _brandColor.withValues(
                                                alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(28),
                                          onTap: () {
                                            Navigator.of(context).pushReplacement(
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        const OnboardScreen()));
                                          },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Get Started',
                                                style: TextStyle(
                                                  fontSize: isTablet ? 18 : 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons.arrow_forward_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: isTablet ? 32 : 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
