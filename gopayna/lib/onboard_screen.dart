import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'register.dart';
import 'login.dart';

class OnboardScreen extends StatefulWidget {
  const OnboardScreen({super.key});

  @override
  State<OnboardScreen> createState() => _OnboardScreenState();
}

class _OnboardScreenState extends State<OnboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _buttonController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _taglineFade;
  late Animation<Offset> _buttonsSlide;
  late Animation<double> _buttonsFade;
  late Animation<double> _buttonScale;

  final Color _brandColor = const Color(0xFF00CA44);

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    // Setup animations with staggered timing
    _logoFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuart),
    ));

    _logoScale = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
    ));

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    ));

    _titleFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    ));

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
    ));

    _taglineFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.5, 0.9, curve: Curves.easeOut),
    ));

    _buttonsSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOutBack),
    ));

    _buttonsFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _buttonScale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
    ));

    // Start animations with delay
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    _scaleController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
    
    await Future.delayed(const Duration(milliseconds: 400));
    _buttonController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFF8F9FA),
                const Color(0xFFF1F3F4).withValues(alpha: 0.8),
                const Color(0xFFE8F5E8).withValues(alpha: 0.3),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
          child: Column(
            children: [
              // Top spacing
              SizedBox(height: statusBarHeight + (isTablet ? 80 : 60)),
              
              // Logo Section
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          width: isTablet ? 120 : 100,
                          height: isTablet ? 120 : 100,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _brandColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _brandColor.withValues(alpha: 0.3),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/logowhite.png',
                              fit: BoxFit.contain,
                              width: isTablet ? 80 : 68,
                              height: isTablet ? 80 : 68,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 32 : 24),
                    
                    // Animated App Name
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: Text(
                          'GoPayna',
                          style: TextStyle(
                            fontSize: isTablet ? 42 : 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 16 : 12),
                    
                    // Animated Tagline
                    SlideTransition(
                      position: _taglineSlide,
                      child: FadeTransition(
                        opacity: _taglineFade,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: isTablet ? 400 : 280,
                          ),
                          child: Text(
                            'Nigeria\'s Trusted Fintech App',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Buttons Section
              Expanded(
                flex: 2,
                child: SlideTransition(
                  position: _buttonsSlide,
                  child: FadeTransition(
                    opacity: _buttonsFade,
                    child: ScaleTransition(
                      scale: _buttonScale,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 48 : 32,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Create Account Button
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 300),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: 1.0,
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: isTablet ? 58 : 54,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(27),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _brandColor.withValues(alpha: 0.4),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          // Add haptic feedback
                                          if (!kIsWeb) {
                                            // HapticFeedback.lightImpact();
                                          }
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _brandColor,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(27),
                                          ),
                                        ),
                                        child: Text(
                                          'Create a new account',
                                          style: TextStyle(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            SizedBox(height: isTablet ? 20 : 16),
                            
                            // Login Button
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 400),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: 1.0,
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: isTablet ? 58 : 54,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        // Add haptic feedback
                                        if (!kIsWeb) {
                                          // HapticFeedback.lightImpact();
                                        }
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _brandColor,
                                        side: BorderSide(
                                          color: _brandColor,
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(27),
                                        ),
                                      ),
                                      child: Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Bottom spacing
              SizedBox(height: isTablet ? 60 : 40),
            ],
          ),
        ),
      ),
    );
  }
}


