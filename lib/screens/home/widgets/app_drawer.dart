import 'package:flutter/material.dart';

import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_model.dart';
import '../../auth/login_screen.dart';
import '../../checkin/checkin_screen.dart';
import '../../feed/checkins_feed_screen.dart';
import '../../profile/profile_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await StorageService.getUser();
    if (mounted && user != null) {
      setState(() => _user = user);
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  void _showHealthCheck() async {
    showDialog(
      context: context,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final res = await ApiService.checkHealth();
      if (!mounted) return;
      Navigator.pop(context); // close loader
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.successColor),
              SizedBox(width: 8),
              Text('API Status'),
            ],
          ),
          content: Text('Server Status: ${res['status'] ?? 'Operational'}\nConnected to followme Backend.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ปิด'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loader
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Health Check Failed'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ปิด'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final hasAvatar = user?.profileImage != null && user!.profileImage!.isNotEmpty;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), AppTheme.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: hasAvatar ? NetworkImage(user.profileImage!) : null,
              child: !hasAvatar
                  ? Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : null,
            ),
            accountName: Text(
              user?.name.isNotEmpty == true ? user!.name : 'ผู้ใช้งาน',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(
              user?.email.isNotEmpty == true ? user!.email : 'กำลังโหลด...',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined, color: AppTheme.primaryColor),
            title: const Text('หน้าหลัก'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined, color: AppTheme.primaryColor),
            title: const Text('เช็คอิน (Check-in)'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CheckinScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.dynamic_feed_outlined, color: AppTheme.primaryColor),
            title: const Text('ฟีดเช็คอิน (Check-ins Feed)'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CheckinsFeedScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
            title: const Text('โปรไฟล์ของฉัน (Profile)'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.speed_outlined, color: AppTheme.primaryColor),
            title: const Text('สถานะเซิร์ฟเวอร์ (API Health)'),
            onTap: () {
              Navigator.pop(context);
              _showHealthCheck();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorColor),
            title: const Text(
              'ออกจากระบบ',
              style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600),
            ),
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }
}
