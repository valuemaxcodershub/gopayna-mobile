import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'intro_screen.dart';
import 'app_settings.dart';
import 'login.dart';
import 'otp_verification.dart';
import 'dashboard.dart';
import 'idle_timeout_service.dart';

/// Global navigator key for accessing navigator from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppSettings _appSettings;
  late Future<_StartDestination> _startDestinationFuture;

  @override
  void initState() {
    super.initState();
    _appSettings = AppSettings();
    _appSettings.addListener(_onThemeChanged);
    _startDestinationFuture = _determineStartDestination();
  }

  @override
  void dispose() {
    _appSettings.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  Future<_StartDestination> _determineStartDestination() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');

    if (token != null && token.isNotEmpty) {
      return _StartDestination.dashboard;
    }

    return _StartDestination.onboarding;
  }

  void _handleIdleTimeout() async {
    // Clear token and navigate to login
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt');
    
    // Show message and navigate to login
    if (navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Session expired due to inactivity. Please login again.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }
    
    // Navigate to login and clear stack
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _initializeIdleTimeout() {
    IdleTimeoutService().initialize(onTimeout: _handleIdleTimeout);
  }

  @override
  Widget build(BuildContext context) {
    return IdleDetector(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'GoPayna',
        theme: _appSettings.lightTheme,
        darkTheme: _appSettings.darkTheme,
        themeMode: _appSettings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: FutureBuilder<_StartDestination>(
          future: _startDestinationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.data == _StartDestination.dashboard) {
              // Initialize idle timeout only when user is logged in
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _initializeIdleTimeout();
              });
              return const DashboardScreen();
            }

            return const GoPaynaHomePage();
          },
        ),
        debugShowCheckedModeBanner: false,
        routes: {
          '/login': (context) => LoginScreen(),
          '/otp': (context) {
            final email = ModalRoute.of(context)?.settings.arguments as String? ?? '';
            return OtpVerificationScreen(email: email, purpose: OtpPurpose.registration);
          },
          '/dashboard': (context) {
            // Initialize idle timeout when navigating to dashboard
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initializeIdleTimeout();
            });
            return const DashboardScreen();
          },
        },
      ),
    );
  }
}

enum _StartDestination { onboarding, dashboard }

class GoPaynaHomePage extends StatefulWidget {
  const GoPaynaHomePage({super.key});

  @override
  State<GoPaynaHomePage> createState() => _GoPaynaHomePageState();
}

class _GoPaynaHomePageState extends State<GoPaynaHomePage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late AnimationController _buttonController;
  
  late Animation<double> _logoScale;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _buttonSlide;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOutCubic,
    ));

    _buttonScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.elasticOut,
    ));

    // Start animations in sequence
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final brandColor = Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      backgroundColor: brandColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 60.0 : 40.0,
            vertical: isTablet ? 60.0 : 40.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScale.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        SizedBox(
                          width: isTablet ? 120 : 100,
                          height: isTablet ? 120 : 100,
                          child: Image.asset(
                            'assets/logowhite.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        
                        SizedBox(height: isTablet ? 20 : 16),
                        
                        // App Name
                        Text(
                          'GoPayna',
                          style: TextStyle(
                            fontSize: isTablet ? 32 : 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              SizedBox(height: isTablet ? 16 : 12),
              
              // Animated Tagline
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 350 : 280,
                  ),
                  child: Text(
                    'Your best Payment in seconds',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              
              const Spacer(flex: 3),
              
              // Animated Get Started button
              SlideTransition(
                position: _buttonSlide,
                child: ScaleTransition(
                  scale: _buttonScale,
                  child: Container(
                    width: isTablet ? 280 : 250,
                    height: isTablet ? 56 : 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoadingPage()),
                          );
                        },
                        child: Center(
                          child: Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w600,
                              color: brandColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: isTablet ? 60 : 50),
            ],
          ),
        ),
      ),
    );
  }
}

