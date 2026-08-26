import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/errors/api_exception.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final bool isFromRegister;

  const OtpScreen({
    super.key,
    required this.email,
    this.isFromRegister = true,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late final TextEditingController _emailCtrl;
  final _otpCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  bool _isEditingEmail = false;
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.email);
    _isEditingEmail = widget.email.isEmpty;
    if (widget.email.isNotEmpty) {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _currentEmail => _emailCtrl.text.trim();

  Future<void> _verifyOtp() async {
    final email = _currentEmail;
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาระบุอีเมลให้ถูกต้อง'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกรหัส OTP ให้ครบ 6 หลัก'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ApiService.verifyOtp(
        email: email,
        otp: otp,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'ยืนยันอีเมลสำเร็จ'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    final email = _currentEmail;
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาระบุอีเมลที่จะส่งรหัส OTP'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_countdown > 0) return;

    setState(() => _isResending = true);
    try {
      final res = await ApiService.resendOtp(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'ส่งรหัส OTP ใหม่แล้ว'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _startCountdown();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _currentEmail;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        color: AppTheme.primaryColor,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'ยืนยันรหัส OTP',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (!_isEditingEmail && email.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'ส่งรหัสไปยัง: $email',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16, color: Color(0xFF38BDF8)),
                          tooltip: 'แก้ไขอีเมล',
                          onPressed: () => setState(() => _isEditingEmail = true),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'กรอกอีเมลของคุณ',
                        prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryColor),
                        suffixIcon: email.isNotEmpty && widget.email.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.check, color: AppTheme.successColor),
                                onPressed: () => setState(() => _isEditingEmail = false),
                              )
                            : null,
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // OTP Input
                  TextField(
                    controller: _otpCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 10,
                      color: Colors.black87,
                    ),
                    decoration: const InputDecoration(
                      hintText: '000000',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Verify Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text(
                              'ยืนยัน OTP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Resend OTP Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'ไม่ได้รับรหัส? ',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                      GestureDetector(
                        onTap: (_countdown > 0 || _isResending) ? null : _resendOtp,
                        child: Text(
                          _countdown > 0
                              ? 'ส่งใหม่ใน $_countdown วิ'
                              : (_isResending ? 'กำลังส่ง...' : 'ขอรหัสใหม่'),
                          style: TextStyle(
                            color: _countdown > 0
                                ? const Color(0xFF64748B)
                                : const Color(0xFF38BDF8),
                            fontWeight: FontWeight.bold,
                            decoration: _countdown > 0
                                ? TextDecoration.none
                                : TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

