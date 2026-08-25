import 'package:flutter/material.dart';

class PersonalPage extends StatefulWidget {
  const PersonalPage({super.key, this.initialName, this.initialEmail});

  final String? initialName;
  final String? initialEmail;

  @override
  State<PersonalPage> createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  late String name;
  late String email;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    name = widget.initialName?.trim().isNotEmpty == true
        ? widget.initialName!.trim()
        : 'ผู้ใช้งาน';
    email = widget.initialEmail?.trim().isNotEmpty == true
        ? widget.initialEmail!.trim()
        : 'ยังไม่ได้ระบุอีเมล';
    nameController.text = name;
    emailController.text = email;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _toggleEditing() {
    setState(() {
      isEditing = !isEditing;
      if (isEditing) {
        nameController.text = name;
        emailController.text = email;
      }
    });
  }

  void _saveProfile() {
    final newName = nameController.text.trim();
    final newEmail = emailController.text.trim();
    if (newName.isEmpty || newEmail.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรอกชื่อและอีเมลให้ครบ')));
      return;
    }
    setState(() {
      name = newName;
      email = newEmail;
      isEditing = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลแล้ว')));
  }

  void _findPhone() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ค้นหาโทรศัพท์ของฉัน'),
        content: const Text(
          'กำลังค้นหาตำแหน่งล่าสุดของโทรศัพท์\nพิกัดล่าสุด: 13.7456, 100.5348',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ส่งเสียงเรียกโทรศัพท์แล้ว')),
              );
            },
            child: const Text('ส่งเสียง'),
          ),
        ],
      ),
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
            colors: [Color(0xFFB056AC), Color(0xFFC86BCC)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'โปรไฟล์ของฉัน',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _findPhone,
                    tooltip: 'ค้นหาโทรศัพท์',
                    icon: const Icon(Icons.search, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: _toggleEditing,
                    tooltip: isEditing ? 'ยกเลิก' : 'แก้ไขโปรไฟล์',
                    icon: Icon(
                      isEditing ? Icons.close : Icons.edit,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const CircleAvatar(
                radius: 52,
                backgroundColor: Color(0xFFE8D9F0),
                child: Icon(Icons.person, size: 58, color: Colors.black54),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                email,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _ProfileStat(value: '24', label: 'รายการ'),
                  _ProfileStat(value: '12', label: 'กำลังติดตาม'),
                  _ProfileStat(value: '8', label: 'ผู้ติดตาม'),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: isEditing ? _editForm() : _profileDetails(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _findPhone,
                  icon: const Icon(Icons.phone_missed),
                  label: const Text('โทรศัพท์หาย - ค้นหาเลย'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ข้อมูลส่วนตัว',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        _infoRow(Icons.person_outline, 'ชื่อ', name),
        const SizedBox(height: 12),
        _infoRow(Icons.email_outlined, 'อีเมล', email),
        const SizedBox(height: 12),
        _infoRow(Icons.phone_outlined, 'เบอร์โทรศัพท์', 'ยังไม่ได้ระบุ'),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: _toggleEditing,
            icon: const Icon(Icons.edit),
            label: const Text('แก้ไขโปรไฟล์'),
          ),
        ),
      ],
    );
  }

  Widget _editForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'แก้ไขข้อมูลส่วนตัว',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'ชื่อ',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'อีเมล',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: _saveProfile,
            icon: const Icon(Icons.save),
            label: const Text('บันทึก'),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6C4EB0)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.black54)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}