import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'main.dart';

// ======================== AUTH SERVICE จำลอง ========================
class AuthService {
  static Future<void> saveAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('name', name);
    await p.setString('email', email);
    await p.setString('password', password);
    await p.setBool('hasAccount', true);
  }

  static Future<Map<String, String>> getAccount() async {
    final p = await SharedPreferences.getInstance();
    return {
      'name': p.getString('name') ?? '',
      'email': p.getString('email') ?? '',
      'password': p.getString('password') ?? '',
    };
  }

  static Future<bool> hasAccount() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('hasAccount') ?? false;
  }
}

// ======================== LOGIN PAGE ========================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool obscure = true;
  bool isLoading = false;

  void _login() async {
    if (emailCtrl.text.trim().isEmpty || passCtrl.text.isEmpty) {
      _showError('กรุณากรอกอีเมลและรหัสผ่าน');
      return;
    }
    setState(() => isLoading = true);
    try {
      final data = await ApiService.login(
        email: emailCtrl.text,
        password: passCtrl.text,
      );
      await ApiService.saveSession(data);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _goSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 88, 135, 184),
              Color.fromARGB(255, 125, 159, 197),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFF7043),
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .https, //www.pinterest.com/pin/601512094024464881/,
                        color: Color(0xFF2196F3),
                        size: 38,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      "followme",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _glassField(
                  controller: emailCtrl,
                  hint: 'อีเมล',
                  icon: Icons.email,
                ),
                const SizedBox(height: 14),
                _glassField(
                  controller: passCtrl,
                  hint: 'รหัสผ่าน',
                  icon: Icons.lock,
                  isPass: true,
                  obscure: obscure,
                  onToggle: () => setState(() => obscure = !obscure),
                ),
                const SizedBox(height: 22),
                _mainButton(
                  text: isLoading ? 'กำลังเข้าสู่ระบบ...' : 'เข้าสู่ระบบ',
                  onTap: isLoading ? null : _login,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "ยังไม่มีบัญชี? ",
                      style: TextStyle(color: Colors.white),
                    ),
                    GestureDetector(
                      onTap: _goSignup,
                      child: const Text(
                        "สมัครบัญชี",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPass = false,
    bool obscure = false,
    VoidCallback? onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPass ? obscure : false,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: isPass
              ? IconButton(
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: onToggle,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _mainButton({required String text, required VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ======================== SIGNUP PAGE ========================
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class OtpPage extends StatefulWidget {
  const OtpPage({super.key, required this.email});

  final String email;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final otpCtrl = TextEditingController();
  bool isLoading = false;

  Future<void> _verify() async {
    if (otpCtrl.text.trim().length != 6) {
      _showError('กรุณากรอกรหัส OTP 6 หลัก');
      return;
    }
    setState(() => isLoading = true);
    try {
      final data = await ApiService.verifyOtp(
        email: widget.email,
        otp: otpCtrl.text,
      );
      await ApiService.saveSession(data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยืนยันอีเมลสำเร็จ กรุณาเข้าสู่ระบบ')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } on ApiException catch (error) {
      if (mounted) _showError(error.message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ยืนยันอีเมล')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('กรอกรหัส OTP ที่ส่งไปยัง ${widget.email}'),
            const SizedBox(height: 20),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'รหัส OTP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: isLoading ? null : _verify,
                child: Text(isLoading ? 'กำลังตรวจสอบ...' : 'ยืนยัน OTP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignupPageState extends State<SignupPage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  bool obscure1 = true, obscure2 = true;

  void _signup() async {
    if (nameCtrl.text.isEmpty ||
        emailCtrl.text.isEmpty ||
        passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรอกข้อมูลให้ครบ')));
      return;
    }
    if (passCtrl.text != confirmCtrl.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('รหัสผ่านไม่ตรงกัน')));
      return;
    }
    if (passCtrl.text.length < 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('รหัสผ่านต้อง 6 ตัวขึ้นไป')));
      return;
    }
    try {
      await ApiService.register(
        name: nameCtrl.text,
        email: emailCtrl.text,
        password: passCtrl.text,
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => OtpPage(email: emailCtrl.text.trim())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 86, 137, 176),
              Color.fromARGB(255, 107, 162, 204),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'สร้างบัญชีใหม่',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'สมัครก่อนถึงจะเข้าใช้งานได้',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 30),
                _field(nameCtrl, 'ชื่อของคุณ', Icons.person),
                const SizedBox(height: 14),
                _field(emailCtrl, 'อีเมล', Icons.email),
                const SizedBox(height: 14),
                _field(
                  passCtrl,
                  'รหัสผ่าน',
                  Icons.lock,
                  isPass: true,
                  obscure: obscure1,
                  toggle: () => setState(() => obscure1 = !obscure1),
                ),
                const SizedBox(height: 14),
                _field(
                  confirmCtrl,
                  'ยืนยันรหัสผ่าน',
                  Icons.lock_outline,
                  isPass: true,
                  obscure: obscure2,
                  toggle: () => setState(() => obscure2 = !obscure2),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'สมัครบัญชี',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    bool isPass = false,
    bool obscure = false,
    VoidCallback? toggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: c,
        obscureText: isPass ? obscure : false,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: isPass
              ? IconButton(
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: toggle,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
