import 'package:flutter/material.dart';

import '../../core/errors/api_exception.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _acceptTerms = false;
  bool _isLoading = false;

  // Teal brand color matching there-you-are
  static const Color brandTeal = Color(0xFF2C7A7B);
  static const Color inputBg = Color(0xFFF3F5F7);
  static const Color inputBorder = Color(0xFFE2E8F0);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _showPdpaDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: brandTeal),
            SizedBox(width: 8),
            Text(
              'เงื่อนไข & นโยบาย PDPA',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'ข้อกำหนดและนโยบายความเป็นส่วนตัว (PDPA)\n\n'
            '1. เราจัดเก็บข้อมูลของท่านเพื่อการยืนยันตัวตนและการให้บริการระบบ Follow Me\n'
            '2. ข้อมูลตำแหน่ง (Location) จะถูกเก็บเมื่อท่านทำการเช็คอินเท่านั้น\n'
            '3. ข้อมูลของท่านจะได้รับการดูแลรักษาความปลอดภัยอย่างเคร่งครัดและไม่นำไปเปิดเผยแก่บุคคลภายนอกโดยไม่ได้รับอนุญาต',
            style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF475569)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('เข้าใจแล้ว', style: TextStyle(color: brandTeal, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณายอมรับเงื่อนไขการใช้งาน & นโยบาย PDPA ก่อนสมัครสมาชิก'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final email = _emailCtrl.text.trim();
    final fullName = _nameCtrl.text.trim();
    final parts = fullName.split(RegExp(r'\s+'));
    final fname = parts.isNotEmpty ? parts.first : '';
    final lname = parts.length > 1 ? parts.sublist(1).join(' ') : fname;

    try {
      final res = await ApiService.register(
        fname: fname,
        lname: lname,
        email: email,
        password: _passCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'ส่งรหัส OTP ไปยังอีเมลแล้ว'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            email: email,
            isFromRegister: true,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      final isEmailExists = error.statusCode == 409 ||
          error.message.toLowerCase().contains('exist') ||
          error.message.contains('เคยลงทะเบียน') ||
          error.message.contains('มีอยู่ในระบบ');

      if (isEmailExists) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.info_outline, color: brandTeal),
                SizedBox(width: 8),
                Text('อีเมลนี้มีอยู่ในระบบแล้ว', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'อีเมล $email ได้ลงทะเบียนไว้แล้ว หากคุณยังไม่ได้ยืนยันรหัส OTP สามารถไปที่หน้ากรอก OTP เพื่อยืนยันอีเมลได้ทันที',
              style: const TextStyle(color: Color(0xFF475569), fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ปิด', style: TextStyle(color: Color(0xFF64748B))),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: brandTeal,
                  side: const BorderSide(color: brandTeal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Go back to LoginScreen
                },
                child: const Text('เข้าสู่ระบบ'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OtpScreen(
                        email: email,
                        isFromRegister: true,
                      ),
                    ),
                  );
                },
                child: const Text('ไปกรอกรหัส OTP', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required Widget prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: brandTeal, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: brandTeal, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          'สมัครสมาชิก',
          style: TextStyle(
            color: brandTeal,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name Field (ชื่อ-นามสกุล)
                    TextFormField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
                      decoration: _buildInputDecoration(
                        hintText: 'ชื่อ-นามสกุล',
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF64748B), size: 22),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อ-นามสกุล' : null,
                    ),
                    const SizedBox(height: 14),

                    // Email Field (อีเมล)
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
                      decoration: _buildInputDecoration(
                        hintText: 'อีเมล',
                        prefixIcon: const Icon(Icons.mail_outline, color: Color(0xFF64748B), size: 22),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'กรุณากรอกอีเมล';
                        if (!v.contains('@') || !v.contains('.')) return 'รูปแบบอีเมลไม่ถูกต้อง';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Password Field (รหัสผ่าน)
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure1,
                      style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
                      decoration: _buildInputDecoration(
                        hintText: 'รหัสผ่าน',
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF64748B), size: 22),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFF64748B),
                            size: 22,
                          ),
                          onPressed: () => setState(() => _obscure1 = !_obscure1),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                        if (v.length < 6) return 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Confirm Password Field (ยืนยันรหัสผ่าน)
                    TextFormField(
                      controller: _confirmPassCtrl,
                      obscureText: _obscure2,
                      style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
                      decoration: _buildInputDecoration(
                        hintText: 'ยืนยันรหัสผ่าน',
                        prefixIcon: const Icon(Icons.history_toggle_off, color: Color(0xFF64748B), size: 22),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFF64748B),
                            size: 22,
                          ),
                          onPressed: () => setState(() => _obscure2 = !_obscure2),
                        ),
                      ),
                      validator: (v) {
                        if (v != _passCtrl.text) return 'รหัสผ่านไม่ตรงกัน';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // PDPA / Terms Checkbox Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: inputBorder),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            activeColor: brandTeal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) => setState(() => _acceptTerms = val ?? false),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _showPdpaDialog,
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
                                  children: [
                                    TextSpan(text: 'ข้าพเจ้าได้อ่านและยอมรับ '),
                                    TextSpan(
                                      text: 'เงื่อนไขการใช้งาน & นโยบาย PDPA',
                                      style: TextStyle(
                                        color: brandTeal,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Register Button (สมัครสมาชิก)
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandTeal,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                                'สมัครสมาชิก',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Direct OTP Link
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OtpScreen(
                                email: _emailCtrl.text.trim(),
                                isFromRegister: true,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.pin_outlined, size: 18, color: brandTeal),
                        label: const Text(
                          'มีรหัส OTP อยู่แล้ว? ยืนยันอีเมลที่นี่',
                          style: TextStyle(
                            color: brandTeal,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

