import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../constants/texts.dart';
import '../../services/auth_service.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import 'register_screen.dart';
import '../onboarding_screen.dart';
import '../main_navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.login(_emailController.text, _passwordController.text);
      
      if (!mounted) return;

      if (user != null) {
        // Check onboarding status
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!mounted) return;

        final isCompleted = userDoc.exists && (userDoc.data()?['onboardingCompleted'] ?? false);

        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => isCompleted ? const MainNavigation() : const OnboardingScreen())
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Giriş Hatası: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, _) {
        final isDark = themeProvider.isDark;
        final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
        final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        
        return Scaffold(
          body: Stack(
            children: [
              // Background Gradient or Color
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark 
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                      : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
                  ),
                ),
              ),
              
              // Toggles at top right
              Positioned(
                top: 50,
                right: 20,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => themeProvider.toggleTheme(),
                      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                      tooltip: "Tema Değiştir",
                    ),
                    TextButton(
                      onPressed: () {
                        languageProvider.toggleLanguage();
                        AppTexts.isEnglish = languageProvider.isEnglish;
                        // Force rebuild to update texts immediately if needed, 
                        // though Consumer should handle it if AppTexts was a provider or if we call setState
                        setState(() {}); 
                      },
                      child: Text(languageProvider.isEnglish ? "TR" : "EN"),
                    ),
                  ],
                ),
              ),

              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_rounded, 
                        size: 64, 
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Yuvam",
                        style: TextStyle(
                          fontSize: 28, 
                          fontWeight: FontWeight.bold, 
                          color: textColor,
                          letterSpacing: 1.2
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      Card(
                        elevation: 4,
                        shadowColor: Colors.black12,
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                AppTexts.loginTitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24, 
                                  fontWeight: FontWeight.bold, 
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppTexts.loginSubtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: subtitleColor, fontSize: 14),
                              ),
                              const SizedBox(height: 32),
                              
                              TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: AppTexts.emailHint,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: AppTexts.passwordHint,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  child: _isLoading 
                                    ? const SizedBox(
                                        height: 24, 
                                        width: 24, 
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                      )
                                    : Text(
                                        AppTexts.loginBtn,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (_) => const RegisterScreen())
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: subtitleColor),
                            children: [
                              TextSpan(text: "${AppTexts.noAccount} "),
                              TextSpan(
                                text: AppTexts.registerBtn,
                                style: TextStyle(
                                  color: AppColors.primary, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
