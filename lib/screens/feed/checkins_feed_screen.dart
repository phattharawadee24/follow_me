import 'package:flutter/material.dart';

import '../../core/errors/api_exception.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/checkin_model.dart';
import '../../models/user_model.dart';
import '../checkin/checkin_screen.dart';
import 'widgets/checkin_card.dart';

class CheckinsFeedScreen extends StatefulWidget {
  const CheckinsFeedScreen({super.key});

  @override
  State<CheckinsFeedScreen> createState() => _CheckinsFeedScreenState();
}

class _CheckinsFeedScreenState extends State<CheckinsFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();

  List<CheckinModel> _allCheckins = [];
  List<CheckinModel> _myCheckins = [];
  UserModel? _currentUser;

  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      _currentUser = await StorageService.getUser();
      final all = await ApiService.getCheckins();
      final my = await ApiService.getCheckins(myOnly: true);
      if (mounted) {
        setState(() {
          _allCheckins = all;
          _myCheckins = my;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    try {
      if (_tabController.index == 0) {
        final all = await ApiService.getCheckins();
        if (mounted) setState(() => _allCheckins = all);
      } else {
        final my = await ApiService.getCheckins(myOnly: true);
        if (mounted) setState(() => _myCheckins = my);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โหลดข้อมูลไม่สำเร็จ: $e')),
        );
      }
    }
  }

  void _showEditDialog(CheckinModel checkin) {
    final nameCtrl = TextEditingController(text: checkin.locationName);
    final descCtrl = TextEditingController(text: checkin.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('แก้ไขข้อมูลเช็คอิน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'ชื่อสถานที่'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'คำอธิบาย'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final updated = await ApiService.updateCheckin(
                  id: checkin.id,
                  locationName: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('แก้ไขเช็คอินเรียบร้อย')),
                );
                setState(() {
                  _allCheckins = _allCheckins
                      .map((c) => c.id == checkin.id ? updated : c)
                      .toList();
                  _myCheckins = _myCheckins
                      .map((c) => c.id == checkin.id ? updated : c)
                      .toList();
                });
              } on ApiException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message), backgroundColor: AppTheme.errorColor),
                  );
                }
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(CheckinModel checkin) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบเช็คอิน "${checkin.locationName}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('ลบรายการ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteCheckin(checkin.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบเช็คอินเรียบร้อย')),
        );
        setState(() {
          _allCheckins.removeWhere((c) => c.id == checkin.id);
          _myCheckins.removeWhere((c) => c.id == checkin.id);
        });
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: AppTheme.errorColor),
          );
        }
      }
    }
  }

  List<CheckinModel> _filterList(List<CheckinModel> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((c) {
      final loc = c.locationName.toLowerCase();
      final desc = (c.description ?? '').toLowerCase();
      final uName = (c.user?.name ?? '').toLowerCase();
      return loc.contains(q) || desc.contains(q) || uName.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentList = _tabController.index == 0 ? _allCheckins : _myCheckins;
    final filtered = _filterList(currentList);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ฟีดการเช็คอิน'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          indicatorColor: AppTheme.primaryColor,
          unselectedLabelColor: const Color(0xFF64748B),
          tabs: [
            Tab(text: 'ทั้งหมด (${_allCheckins.length})'),
            Tab(text: 'ของฉัน (${_myCheckins.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'ค้นหาตามชื่อสถานที่, ข้อความ, ชื่อคน...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),

          // Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: filtered.isEmpty
                        ? ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 80),
                                child: Center(
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.place_outlined,
                                        size: 56,
                                        color: Color(0xFFCBD5E1),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _searchQuery.isEmpty
                                            ? (_tabController.index == 0
                                                ? 'ยังไม่มีรายการเช็คอิน'
                                                : 'คุณยังไม่เคยเช็คอิน')
                                            : 'ไม่พบรายการที่ค้นหา',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80, top: 4),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, index) {
                              final item = filtered[index];
                              final isOwner = _currentUser != null &&
                                  (item.userId == _currentUser!.id ||
                                      item.user?.id == _currentUser!.id);

                              return CheckinCard(
                                checkin: item,
                                isOwner: isOwner,
                                onEdit: () => _showEditDialog(item),
                                onDelete: () => _confirmDelete(item),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CheckinScreen()),
          );
          _refresh();
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('เช็คอินใหม่'),
      ),
    );
  }
}
