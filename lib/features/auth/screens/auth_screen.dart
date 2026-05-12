import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../parent/screens/parent_dashboard.dart';
import '../../teacher/screens/teacher_dashboard.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submittedOnce = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final bool isAr = appState.locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black26;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Top Bar: Language Switcher
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [_buildLanguagePortal(context, isAr)],
                  ),
                ),

                const SizedBox(height: 32),

                _buildHeader(context)
                    .animate()
                    .fadeIn(delay: 200.ms)
                    .slideY(begin: -0.2),

                const SizedBox(height: 32),

                _buildLoginForm(context)
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 0.05),

                const SizedBox(height: 80),
                Text(
                  '${AppLocalizations.of(context)!.translate('school_app_2026')} • Ikenas Technology',
                  style: TextStyle(
                      color: secondaryTextColor.withValues(alpha: 0.4),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
            color:
                isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.white.withValues(alpha: 0.7), blurRadius: 20)
              ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: _submittedOnce
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_person_rounded,
                    color: Colors.blueAccent.withValues(alpha: 0.5), size: 16),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.translate('login_uppercase'),
                    style: TextStyle(
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF1E293B).withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5)),
              ],
            ),
            const SizedBox(height: 40),

            _buildPlatinumInput(
              context,
              Icons.alternate_email_rounded,
              AppLocalizations.of(context)!.translate('login_id_hint'),
              controller: _emailController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context)!
                      .translate('login_id_required');
                }
                return null;
              },
              onChanged: (val) {
                if (_errorMessage != null) setState(() => _errorMessage = null);
              },
            ),
            const SizedBox(height: 20),
            _buildPlatinumInput(
              context,
              Icons.key_rounded,
              AppLocalizations.of(context)!.translate('login_pwd_hint'),
              obscure: _obscurePassword,
              controller: _passwordController,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: isDark ? Colors.white54 : Colors.black45,
                  size: 20,
                ),
                splashRadius: 24,
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context)!
                      .translate('login_pwd_required');
                }
                if (value.length < 4) {
                  return AppLocalizations.of(context)!
                      .translate('login_pwd_too_short');
                }
                return null;
              },
              onChanged: (val) {
                if (_errorMessage != null) setState(() => _errorMessage = null);
              },
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.redAccent, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().shake(duration: 400.ms),
            ],

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: isDark
                            ? Colors.blueAccent.withValues(alpha: 0.2)
                            : const Color(0xFF0F172A).withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: -5),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? Colors.white : const Color(0xFF0F172A),
                    foregroundColor:
                        isDark ? const Color(0xFF0F172A) : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.white,
                              strokeWidth: 3))
                      : Text(
                          AppLocalizations.of(context)!
                              .translate('access_portal'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _login() async {
    setState(() {
      _submittedOnce = true;
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final appState = Provider.of<AppState>(context, listen: false);

    try {
      await appState.login(_emailController.text, _passwordController.text);
      if (!mounted) return;

      // Redirect based on role returned by the API
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => appState.isParent
                  ? const ParentDashboard()
                  : const TeacherDashboard()),
          (route) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String errorMessage = e.toString();
      if (errorMessage.contains('401')) {
        setState(() {
          _errorMessage =
              AppLocalizations.of(context)!.translate('login_error_invalid');
        });
        return;
      } else if (errorMessage.contains('404')) {
        errorMessage = "Service d'authentification indisponible (404)";
      } else if (errorMessage.contains('SocketException') ||
          errorMessage.contains('connection')) {
        errorMessage =
            "Erreur de connexion au serveur. Vérifiez votre internet.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildPlatinumInput(BuildContext context, IconData icon, String hint,
      {bool obscure = false,
      TextEditingController? controller,
      String? Function(String?)? validator,
      void Function(String)? onChanged,
      Widget? suffixIcon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final inputBg = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.white.withValues(alpha: 0.7);

    return FormField<String>(
        validator: validator,
        builder: (state) {
          final bool hasError = state.hasError;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: hasError
                          ? Colors.redAccent.withValues(alpha: 0.5)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white),
                      width: hasError ? 1.5 : 1),
                  boxShadow: hasError
                      ? [
                          BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.1),
                              blurRadius: 10,
                              spreadRadius: 2)
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: hasError
                              ? Colors.redAccent.withValues(alpha: 0.1)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.white.withValues(alpha: 0.8)),
                          borderRadius: BorderRadius.circular(16)),
                      child: Icon(icon,
                          color: hasError
                              ? Colors.redAccent
                              : primaryTextColor.withValues(
                                  alpha: isDark ? 0.4 : 0.7),
                          size: 18),
                    ),
                    Expanded(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: TextFormField(
                                controller: controller,
                                obscureText: obscure,
                                onChanged: (value) {
                                  state.didChange(value);
                                  if (onChanged != null) onChanged(value);
                                },
                                style: TextStyle(
                                    color: primaryTextColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1),
                                decoration: InputDecoration(
                                  hintText: hint.toUpperCase(),
                                  suffixIcon: suffixIcon,
                                  hintStyle: TextStyle(
                                      color: primaryTextColor.withValues(
                                          alpha: isDark ? 0.15 : 0.4),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5),
                                  border: InputBorder.none,
                                  errorStyle: const TextStyle(
                                      height: 0, color: Colors.transparent),
                                )))),
                  ],
                ),
              ),
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Text(
                    state.errorText ?? "",
                    style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5),
                  ).animate().fadeIn().slideX(begin: -0.1),
                ),
            ],
          );
        });
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final headerBg =
        isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;

    return Column(
      children: [
        Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: headerBg,
                  border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      width: 1.5),
                  boxShadow: [
                    if (isDark)
                      BoxShadow(
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                          blurRadius: 30)
                    else
                      BoxShadow(
                          color: Colors.white.withValues(alpha: 0.7),
                          blurRadius: 20)
                  ],
                ),
                child: Center(
                    child: Image.asset('assets/images/image3.png',
                        width: 56, height: 56, fit: BoxFit.contain)))
            .animate()
            .shimmer(
                duration: 2.seconds,
                color: isDark ? Colors.white12 : Colors.white),
        const SizedBox(height: 32),
        Text(
          'SchooLine',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          AppLocalizations.of(context)!.translate('app_subtitle'),
          style: TextStyle(
              color: primaryTextColor.withValues(alpha: isDark ? 0.25 : 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2),
        ),
      ],
    );
  }

  Widget _buildLanguagePortal(BuildContext context, bool isAr) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLighContrastText = isDark ? Colors.white60 : Colors.black45;

    return Container(
      decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white)),
      child: PopupMenuButton<String>(
        onSelected: (code) => Provider.of<AppState>(context, listen: false)
            .setLocale(Locale(code)),
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language_rounded, color: isLighContrastText, size: 16),
              const SizedBox(width: 8),
              Text(
                  Provider.of<AppState>(context)
                      .locale
                      .languageCode
                      .toUpperCase(),
                  style: TextStyle(
                      color: isLighContrastText,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.5)),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded,
                  color: isLighContrastText, size: 16),
            ],
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
              value: 'fr',
              child: Text(AppLocalizations.of(context)!.translate('fr_lang'),
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w900))),
          PopupMenuItem(
              value: 'ar',
              child: Text(AppLocalizations.of(context)!.translate('ar_lang'),
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w900))),
          PopupMenuItem(
              value: 'en',
              child: Text(AppLocalizations.of(context)!.translate('en_lang'),
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w900)))
        ],
      ),
    );
  }
}
