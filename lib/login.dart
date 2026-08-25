import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void _login() async {
    final acc = await AuthService.getAccount();
    if (!await AuthService.hasAccount()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่มีบัญชี กรุณาสมัครก่อน')),
      );
      _goSignup();
      return;
    }
    if (emailCtrl.text == acc['email'] && passCtrl.text == acc['password']) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PersonalPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อีเมลหรือรหัสผ่านไม่ถูกต้อง'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                _mainButton(text: "เข้าสู่ระบบ", onTap: _login),
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

  Widget _mainButton({required String text, required VoidCallback onTap}) {
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
    await AuthService.saveAccount(
      name: nameCtrl.text,
      email: emailCtrl.text,
      password: passCtrl.text,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('สมัครสำเร็จ! กรุณาเข้าสู่ระบบ'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context); // เด้งกลับไปหน้า Login ตามที่ขอ
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

// ======================== PERSONAL PAGE - ใส่รูป ตั้งชื่อ เปลี่ยนรหัส ========================
class PersonalPage extends StatefulWidget {
  const PersonalPage({super.key});
  @override
  State<PersonalPage> createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  String name = '', email = '';
  File? imageFile;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final acc = await AuthService.getAccount();
    final p = await SharedPreferences.getInstance();
    setState(() {
      name = acc['name'] ?? '';
      email = acc['email'] ?? '';
      final path = p.getString('imagePath');
      if (path != null) imageFile = File(path);
    });
  }

  Future<void> _pickImage() async {
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final p = await SharedPreferences.getInstance();
      await p.setString('imagePath', picked.path);
      setState(() => imageFile = File(picked.path));
    }
  }

  void _editName() {
    final ctrl = TextEditingController(text: name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ตั้งชื่อใหม่'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pref = await SharedPreferences.getInstance();
              await pref.setString('name', ctrl.text);
              setState(() => name = ctrl.text);
              Navigator.pop(context);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('เปลี่ยนรหัสผ่าน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'รหัสเก่า',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'รหัสใหม่',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final acc = await AuthService.getAccount();
              if (oldCtrl.text != acc['password']) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('รหัสเก่าไม่ถูก')));
                return;
              }
              final pref = await SharedPreferences.getInstance();
              await pref.setString('password', newCtrl.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('เปลี่ยนรหัสแล้ว'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('เปลี่ยน'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
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
              Color.fromARGB(255, 176, 86, 172),
              Color.fromARGB(255, 179, 92, 198),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'โปรไฟล์ของฉัน',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFFE8D9F0),
                      backgroundImage: imageFile != null
                          ? FileImage(imageFile!)
                          : null,
                      child: imageFile == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.black54,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(email, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('ตั้งชื่อเรา'),
                        subtitle: Text(name),
                        onTap: _editName,
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.lock),
                        title: const Text('เปลี่ยนรหัสผ่าน'),
                        onTap: _changePassword,
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.image),
                        title: const Text('เปลี่ยนรูปโปรไฟล์'),
                        onTap: _pickImage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}