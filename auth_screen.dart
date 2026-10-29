import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'database_helper.dart';
import 'main.dart' show WelcomeScreen;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool obscurePin = true;
  bool obscureConfirmPin = true;
  bool agreeToTerms = false;
  bool _loading = false;

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final pinController = TextEditingController();
  final confirmPinController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    pinController.dispose();
    confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!isLogin && !agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Privacy Policy'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      final AuthResult result;
      if (isLogin) {
        result = await AuthService.login(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      } else {
        result = await AuthService.register(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text,
          pin: pinController.text,
        );
      }

      await DatabaseHelper.instance.saveAuthSession(
        token: result.accessToken,
        parentId: result.parentId,
        name: result.name,
        email: emailController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _switchMode(bool login) {
    setState(() {
      isLogin = login;
      agreeToTerms = false;
    });

    _formKey.currentState?.reset();
  }

  void _showForgotPassword() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _ResetSheet(
          title: 'Reset Password',
          description:
              'Enter your registered email address and we will help you reset your password.',
          icon: Icons.lock_reset_rounded,
          isPin: false,
        );
      },
    );
  }

  void _showForgotPin() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _ResetSheet(
          title: 'Reset PIN',
          description:
              'Enter your registered email address to reset your security PIN.',
          icon: Icons.pin_outlined,
          isPin: true,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 28),
                  _buildAuthCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.22),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 38,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Learn & Grow',
          style: TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172033),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isLogin
              ? 'Welcome back! Let’s continue learning.'
              : 'Create your account and start learning.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14.5, color: Color(0xFF737B8C)),
        ),
      ],
    );
  }

  Widget _buildAuthCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE9ECF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModeSelector(),

            const SizedBox(height: 28),

            if (!isLogin) ...[
              _buildLabel('Full Name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: nameController,
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 17),
            ],

            _buildLabel('Email'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: emailController,
              hint: 'Enter your email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }

                final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Please enter a valid email';
                }

                return null;
              },
            ),

            const SizedBox(height: 17),

            _buildLabel('Password'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: passwordController,
              hint: 'Enter your password',
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF8B93A3),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }

                if (!isLogin && value.length < 6) {
                  return 'Password must be at least 6 characters';
                }

                return null;
              },
            ),

            if (isLogin) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPassword,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFF5B55E8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

            if (!isLogin) ...[
              const SizedBox(height: 17),

              _buildLabel('Confirm Password'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: confirmPasswordController,
                hint: 'Confirm your password',
                icon: Icons.lock_reset_outlined,
                obscureText: obscureConfirmPassword,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      obscureConfirmPassword = !obscureConfirmPassword;
                    });
                  },
                  icon: Icon(
                    obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF8B93A3),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }

                  if (value != passwordController.text) {
                    return 'Passwords do not match';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 17),

              _buildLabel('Security PIN'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: pinController,
                hint: 'Enter 4-digit PIN',
                icon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
                obscureText: obscurePin,
                maxLength: 4,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      obscurePin = !obscurePin;
                    });
                  },
                  icon: Icon(
                    obscurePin
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF8B93A3),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a PIN';
                  }

                  if (!RegExp(r'^\d{4}$').hasMatch(value)) {
                    return 'PIN must be exactly 4 digits';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 17),

              _buildLabel('Confirm PIN'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: confirmPinController,
                hint: 'Confirm your PIN',
                icon: Icons.pin_end_outlined,
                keyboardType: TextInputType.number,
                obscureText: obscureConfirmPin,
                maxLength: 4,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      obscureConfirmPin = !obscureConfirmPin;
                    });
                  },
                  icon: Icon(
                    obscureConfirmPin
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF8B93A3),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your PIN';
                  }

                  if (value != pinController.text) {
                    return 'PINs do not match';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              _buildTerms(),
            ],

            if (isLogin) ...[
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: _showForgotPin,
                  icon: const Icon(Icons.pin_outlined, size: 18),
                  label: const Text('Forgot PIN?'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF5B55E8),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            _buildMainButton(),

            const SizedBox(height: 22),

            _buildBottomSwitch(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeButton(
              title: 'Login',
              selected: isLogin,
              onTap: () => _switchMode(true),
            ),
          ),
          Expanded(
            child: _modeButton(
              title: 'Register',
              selected: !isLogin,
              onTap: () => _switchMode(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFF4F46E5) : const Color(0xFF7A8292),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF303849),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: Color(0xFF202738),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFA1A8B6), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF8B93A3), size: 21),
        suffixIcon: suffixIcon,
        counterText: '',
        filled: true,
        fillColor: const Color(0xFFF9FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E8EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E8EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF655EEA), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTerms() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: agreeToTerms,
            activeColor: const Color(0xFF5B55E8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            onChanged: (value) {
              setState(() {
                agreeToTerms = value ?? false;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              'I agree to the Terms of Service and Privacy Policy.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: Color(0xFF747C8C),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5B55E8),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                isLogin ? 'Login' : 'Create Account',
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildBottomSwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isLogin ? "Don't have an account?" : 'Already have an account?',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF7B8392)),
        ),
        TextButton(
          onPressed: () => _switchMode(!isLogin),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.only(left: 5),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            isLogin ? 'Register' : 'Login',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5B55E8),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResetSheet extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isPin;

  const _ResetSheet({
    required this.title,
    required this.description,
    required this.icon,
    required this.isPin,
  });

  @override
  State<_ResetSheet> createState() => _ResetSheetState();
}

class _ResetSheetState extends State<_ResetSheet> {
  final emailController = TextEditingController();
  final tokenController = TextEditingController();
  final newValueController = TextEditingController();
  bool requested = false;
  bool loading = false;
  String? devToken;

  @override
  void dispose() {
    emailController.dispose();
    tokenController.dispose();
    newValueController.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    if (emailController.text.trim().isEmpty) return;
    setState(() => loading = true);
    try {
      devToken = widget.isPin
          ? await AuthService.forgotPin(emailController.text.trim())
          : await AuthService.forgotPassword(emailController.text.trim());
      setState(() => requested = true);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reset token created.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _reset() async {
    final token = tokenController.text.trim();
    final value = newValueController.text;
    if (token.isEmpty || value.isEmpty) return;

    setState(() => loading = true);
    try {
      if (widget.isPin) {
        if (!RegExp(r'^\d{4,6}$').hasMatch(value)) {
          throw Exception('PIN must be 4 to 6 digits.');
        }
        await AuthService.resetPin(token: token, newPin: value);
      } else {
        if (value.length < 6) {
          throw Exception('Password must be at least 6 characters.');
        }
        await AuthService.resetPassword(token: token, newPassword: value);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${widget.title} successful.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF8B93A3)),
      filled: true,
      fillColor: const Color(0xFFF9FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E8EF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E8EF)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE1E8),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EFFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.icon,
                    color: const Color(0xFF5B55E8),
                    size: 25,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF202738),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              widget.description,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: Color(0xFF747C8C),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _decoration('Enter your email', Icons.email_outlined),
            ),
            const SizedBox(height: 18),
            if (!requested)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : _request,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B55E8),
                    foregroundColor: Colors.white,
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Reset Token'),
                ),
              )
            else ...[
              if (devToken != null) ...[
                const Text(
                  'Development reset token:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                SelectableText(devToken!, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: tokenController,
                decoration: _decoration(
                  'Enter reset token',
                  Icons.key_outlined,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: newValueController,
                obscureText: true,
                keyboardType: widget.isPin
                    ? TextInputType.number
                    : TextInputType.text,
                maxLength: widget.isPin ? 6 : null,
                decoration: _decoration(
                  widget.isPin ? 'New PIN' : 'New password',
                  widget.isPin ? Icons.pin_outlined : Icons.lock_outline,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : _reset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B55E8),
                    foregroundColor: Colors.white,
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.title),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
