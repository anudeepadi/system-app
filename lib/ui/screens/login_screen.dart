/// Login Screen
///
/// Beautiful glassmorphism login screen for SYSTEM app.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/system_theme.dart';
import '../widgets/glass_container.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _tokenController = TextEditingController();
  final _personalOsUrlController = TextEditingController();
  final _personalOsTokenController = TextEditingController();

  bool _rememberMe = true;
  bool _showAdvanced = false;
  bool _obscureToken = true;
  bool _isConnecting = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();

    // Load saved values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedValues();
    });
  }

  void _loadSavedValues() {
    final authProvider = context.read<AuthProvider>();
    final savedServerUrl = authProvider.getSavedServerUrl();
    final savedPersonalOsUrl = authProvider.getSavedPersonalOsUrl();

    if (savedServerUrl != null) {
      _serverUrlController.text = savedServerUrl;
    } else {
      // Default values for development
      _serverUrlController.text = ConnectionConfig.defaults.serverUrl;
      _tokenController.text = ConnectionConfig.defaults.token;
      _personalOsUrlController.text =
          ConnectionConfig.defaults.personalOsUrl ?? '';
      _personalOsTokenController.text =
          ConnectionConfig.defaults.personalOsToken ?? '';
    }

    if (savedPersonalOsUrl != null) {
      _personalOsUrlController.text = savedPersonalOsUrl;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _serverUrlController.dispose();
    _tokenController.dispose();
    _personalOsUrlController.dispose();
    _personalOsTokenController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isConnecting = true);

    final authProvider = context.read<AuthProvider>();
    final config = ConnectionConfig(
      serverUrl: _serverUrlController.text.trim(),
      token: _tokenController.text.trim(),
      personalOsUrl: _personalOsUrlController.text.trim().isNotEmpty
          ? _personalOsUrlController.text.trim()
          : null,
      personalOsToken: _personalOsTokenController.text.trim().isNotEmpty
          ? _personalOsTokenController.text.trim()
          : null,
      rememberMe: _rememberMe,
    );

    final success = await authProvider.login(config);

    if (mounted) {
      setState(() => _isConnecting = false);

      if (!success && authProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error!),
            backgroundColor: SystemColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: themeProvider.colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.08),

                  // Logo and branding
                  _buildHeader(themeProvider),
                  const SizedBox(height: 48),

                  // Login form
                  _buildLoginForm(themeProvider),
                  const SizedBox(height: 24),

                  // Quick connect button (uses defaults)
                  _buildQuickConnectButton(themeProvider),
                  const SizedBox(height: 32),

                  // Footer
                  _buildFooter(themeProvider),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    return Column(
      children: [
        // Animated logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeProvider.colors.accent,
                themeProvider.colors.accent.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: themeProvider.colors.accent.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            LucideIcons.activity,
            size: 50,
            color: themeProvider.colors.background,
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          'SYSTEM',
          style: SystemTextStyles.displayLarge.copyWith(
            color: themeProvider.colors.textPrimary,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Control Your Mac From Anywhere',
          style: SystemTextStyles.uiMedium.copyWith(
            color: themeProvider.colors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(ThemeProvider themeProvider) {
    return Form(
      key: _formKey,
      child: GlassContainer(
        backgroundColor: themeProvider.colors.glassBackground,
        borderColor: themeProvider.colors.glassBorder,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Icon(
                  LucideIcons.server,
                  color: themeProvider.colors.accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'CONNECTION',
                  style: SystemTextStyles.monoSmall.copyWith(
                    color: themeProvider.colors.textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Server URL
            _buildTextField(
              controller: _serverUrlController,
              label: 'WebSocket Server URL',
              hint: 'ws://192.168.x.x:3001',
              icon: LucideIcons.globe,
              themeProvider: themeProvider,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Server URL is required';
                }
                if (!value.startsWith('ws://') && !value.startsWith('wss://')) {
                  return 'URL must start with ws:// or wss://';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Token
            _buildTextField(
              controller: _tokenController,
              label: 'Authentication Token',
              hint: 'Enter your token',
              icon: LucideIcons.key,
              themeProvider: themeProvider,
              obscureText: _obscureToken,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureToken ? LucideIcons.eye : LucideIcons.eyeOff,
                  color: themeProvider.colors.textMuted,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscureToken = !_obscureToken),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Token is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Advanced options toggle
            GestureDetector(
              onTap: () => setState(() => _showAdvanced = !_showAdvanced),
              child: Row(
                children: [
                  Icon(
                    _showAdvanced
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronRight,
                    color: themeProvider.colors.textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Personal OS API (Optional)',
                    style: SystemTextStyles.uiSmall.copyWith(
                      color: themeProvider.colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Advanced options
            if (_showAdvanced) ...[
              const SizedBox(height: 16),
              _buildTextField(
                controller: _personalOsUrlController,
                label: 'Personal OS API URL',
                hint: 'http://192.168.x.x:8765',
                icon: LucideIcons.brain,
                themeProvider: themeProvider,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _personalOsTokenController,
                label: 'Personal OS Token',
                hint: 'Enter API token',
                icon: LucideIcons.keyRound,
                themeProvider: themeProvider,
              ),
            ],

            const SizedBox(height: 20),

            // Remember me
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _rememberMe
                          ? themeProvider.colors.accent
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _rememberMe
                            ? themeProvider.colors.accent
                            : themeProvider.colors.textMuted,
                        width: 2,
                      ),
                    ),
                    child: _rememberMe
                        ? Icon(
                            LucideIcons.check,
                            size: 14,
                            color: themeProvider.colors.background,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Remember my credentials',
                  style: SystemTextStyles.uiSmall.copyWith(
                    color: themeProvider.colors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Connect button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isConnecting ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.colors.accent,
                  foregroundColor: themeProvider.colors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isConnecting
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            themeProvider.colors.background,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.plug, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'CONNECT',
                            style: SystemTextStyles.monoMedium.copyWith(
                              color: themeProvider.colors.background,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeProvider themeProvider,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: SystemTextStyles.labelSmall.copyWith(
            color: themeProvider.colors.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          style: SystemTextStyles.uiMedium.copyWith(
            color: themeProvider.colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: SystemTextStyles.uiMedium.copyWith(
              color: themeProvider.colors.textMuted.withOpacity(0.5),
            ),
            prefixIcon: Icon(
              icon,
              color: themeProvider.colors.textMuted,
              size: 18,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: themeProvider.colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: themeProvider.colors.surfaceElevated,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: themeProvider.colors.surfaceElevated,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: themeProvider.colors.accent,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: themeProvider.colors.error,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickConnectButton(ThemeProvider themeProvider) {
    return TextButton(
      onPressed: () {
        // Fill with defaults
        _serverUrlController.text = ConnectionConfig.defaults.serverUrl;
        _tokenController.text = ConnectionConfig.defaults.token;
        _personalOsUrlController.text =
            ConnectionConfig.defaults.personalOsUrl ?? '';
        _personalOsTokenController.text =
            ConnectionConfig.defaults.personalOsToken ?? '';
        setState(() {});
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.zap,
            size: 16,
            color: themeProvider.colors.accentSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            'Use Development Defaults',
            style: SystemTextStyles.uiSmall.copyWith(
              color: themeProvider.colors.accentSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeProvider themeProvider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PulsingDot(size: 6, color: themeProvider.colors.accent),
            const SizedBox(width: 8),
            Text(
              'Secure WebSocket Connection',
              style: SystemTextStyles.monoSmall.copyWith(
                color: themeProvider.colors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'v1.0.0',
          style: SystemTextStyles.monoSmall.copyWith(
            color: themeProvider.colors.textMuted.withOpacity(0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
