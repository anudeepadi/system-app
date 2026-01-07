/// SYSTEM - Control Your Mac From Anywhere
///
/// A futuristic "Hacker Console meets Premium SaaS Dashboard" for remote Mac control.
/// Features deep space dark mode with glassmorphism aesthetic.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Core services
import 'services/system_provider.dart';
import 'services/macro_provider.dart';
import 'services/file_browser_provider.dart';
import 'services/personal_os_provider.dart';
import 'services/auth_service.dart';

// Theme
import 'theme/system_theme.dart';

// UI
import 'ui/system_app_shell.dart';
import 'ui/screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for immersive dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: SystemColors.backgroundDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Preload fonts
  GoogleFonts.config.allowRuntimeFetching = true;

  runApp(const SystemApp());
}

class SystemApp extends StatelessWidget {
  const SystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth provider (must be first)
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // System services (Mac control via WebSocket)
        ChangeNotifierProvider(create: (_) => SystemProvider()),
        ChangeNotifierProxyProvider<SystemProvider, MacroProvider>(
          create: (context) => MacroProvider(context.read<SystemProvider>()),
          update: (context, systemProvider, macroProvider) =>
              macroProvider ?? MacroProvider(systemProvider),
        ),
        ChangeNotifierProxyProvider<SystemProvider, FileBrowserProvider>(
          create: (context) =>
              FileBrowserProvider(context.read<SystemProvider>()),
          update: (context, systemProvider, fileBrowserProvider) =>
              fileBrowserProvider ?? FileBrowserProvider(systemProvider),
        ),

        // Personal OS services (Tasks/Chat via REST API)
        ChangeNotifierProvider(create: (_) => PersonalOsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          // Update system UI based on theme
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  themeProvider.isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: themeProvider.colors.background,
              systemNavigationBarIconBrightness:
                  themeProvider.isDark ? Brightness.light : Brightness.dark,
            ),
          );

          return MaterialApp(
            title: 'SYSTEM',
            debugShowCheckedModeBanner: false,
            theme: SystemTheme.light,
            darkTheme: SystemTheme.dark,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

/// Wrapper that handles authentication state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  Future<void> _initializeAuth() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    if (!_initialized) {
      // Show splash screen while initializing
      return Scaffold(
        backgroundColor: themeProvider.colors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themeProvider.colors.accent,
                      themeProvider.colors.accent.withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.colors.accent.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.bolt,
                  size: 40,
                  color: themeProvider.colors.background,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'SYSTEM',
                style: SystemTextStyles.displayLarge.copyWith(
                  color: themeProvider.colors.textPrimary,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    themeProvider.colors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoggedIn) {
          return const ConnectedAppWrapper();
        }
        return const LoginScreen();
      },
    );
  }
}

/// Wrapper that auto-connects to servers after login
class ConnectedAppWrapper extends StatefulWidget {
  const ConnectedAppWrapper({super.key});

  @override
  State<ConnectedAppWrapper> createState() => _ConnectedAppWrapperState();
}

class _ConnectedAppWrapperState extends State<ConnectedAppWrapper> {
  bool _hasAttemptedConnect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoConnect();
    });
  }

  Future<void> _autoConnect() async {
    if (_hasAttemptedConnect) return;
    _hasAttemptedConnect = true;

    final authProvider = context.read<AuthProvider>();
    final session = authProvider.session;
    if (session == null) return;

    // Connect to System-Mac WebSocket server (for Mac control tools)
    final systemProvider = context.read<SystemProvider>();
    if (!systemProvider.isConnected) {
      try {
        await systemProvider.connect(session.serverUrl, session.token);
      } catch (e) {
        debugPrint('System-Mac auto-connect failed: $e');
      }
    }

    // Connect to Personal OS REST API (for tasks and chat)
    if (session.personalOsUrl != null && session.personalOsToken != null) {
      final personalOsProvider = context.read<PersonalOsProvider>();
      if (!personalOsProvider.isConnected) {
        try {
          await personalOsProvider.connect(
            baseUrl: session.personalOsUrl,
            token: session.personalOsToken,
          );
        } catch (e) {
          debugPrint('Personal-OS auto-connect failed: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SystemAppShell();
  }
}
