import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFAF9F7),
        fontFamily: 'Georgia',
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF1A1A1A),
          surface: const Color(0xFFFAF9F7),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────

class _MinimalTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType keyboardType;

  const _MinimalTextField({
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_MinimalTextField> createState() => _MinimalTextFieldState();
}

class _MinimalTextFieldState extends State<_MinimalTextField> {
  bool _focused = false;
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _focused
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFFD4D0CC),
              width: _focused ? 1.5 : 1.0,
            ),
          ),
        ),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.obscure && !_showPassword,
          keyboardType: widget.keyboardType,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1A1A1A),
            letterSpacing: 0.2,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              fontSize: 13,
              color: _focused
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFF9E9993),
              letterSpacing: 1.2,
              fontFamily: 'Georgia',
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            suffixIcon: widget.obscure
                ? GestureDetector(
                    onTap: () => setState(() => _showPassword = !_showPassword),
                    child: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: const Color(0xFF9E9993),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final bool loading;

  const _PrimaryButton({
    required this.onPressed,
    required this.label,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 1.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Georgia',
                ),
              ),
      ),
    );
  }
}

// ─── Minimal Page Shell ───────────────────────────────────────────

class _PageShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  const _PageShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      appBar: showBack
          ? AppBar(
              backgroundColor: const Color(0xFFFAF9F7),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF1A1A1A),
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: showBack ? 16 : 72),
              // Logo mark
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9993),
                  letterSpacing: 0.1,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Login Screen ─────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _loading = false;

  Future<void> login() async {
    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse("http://localhost:8000/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text,
          "password": passwordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPScreen(email: emailController.text),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Incorrect email or password."),
            backgroundColor: const Color(0xFF1A1A1A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("ERROR: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      title: "Welcome\nback.",
      subtitle: "Sign in to continue.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MinimalTextField(
            controller: emailController,
            label: "EMAIL",
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 28),
          _MinimalTextField(
            controller: passwordController,
            label: "PASSWORD",
            obscure: true,
          ),
          const SizedBox(height: 40),
          _PrimaryButton(
            onPressed: login,
            label: "CONTINUE",
            loading: _loading,
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text(
                "Forgot password?",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9E9993),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF9E9993),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── OTP Screen ───────────────────────────────────────────────────

class OTPScreen extends StatefulWidget {
  final String email;

  const OTPScreen({super.key, required this.email});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final otpController = TextEditingController();
  bool _loading = false;

  Future<void> verifyOTP() async {
    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse("http://localhost:8000/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email,
          "otp_code": otpController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(email: widget.email),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Invalid code. Please try again."),
            backgroundColor: const Color(0xFF1A1A1A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("ERROR: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mask email for privacy display
    final parts = widget.email.split('@');
    final masked = parts.length == 2
        ? '${parts[0].substring(0, (parts[0].length / 2).floor())}···@${parts[1]}'
        : widget.email;

    return _PageShell(
      title: "Check your\nemail.",
      subtitle: "We sent a 6-digit code to $masked",
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MinimalTextField(
            controller: otpController,
            label: "VERIFICATION CODE",
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 40),
          _PrimaryButton(
            onPressed: verifyOTP,
            label: "VERIFY",
            loading: _loading,
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text(
                "Resend code",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9E9993),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF9E9993),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dashboard Screen ─────────────────────────────────────────────

class DashboardScreen extends StatelessWidget {
  final String email;

  const DashboardScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 64),

              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Georgia',
                  ),
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                "You're in.",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Signed in as $email",
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9993),
                  letterSpacing: 0.1,
                ),
              ),

              const SizedBox(height: 48),

              // Divider card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEAE7E3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F0EC),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Authentication complete",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Your session is active and secure.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9E9993),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Log out
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A1A),
                    side: const BorderSide(color: Color(0xFFD4D0CC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    "SIGN OUT",
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Georgia',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}