import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../core/errors/api_exception.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../models/checkin_model.dart';
import '../../models/user_model.dart';
import '../feed/checkins_feed_screen.dart';
import '../profile/profile_screen.dart';
import 'widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  UserModel? _currentUser;
  Position? _currentPosition;
  List<CheckinModel> _checkins = [];
  CheckinModel? _selectedCheckin;

  bool _isLoadingLocation = true;
  bool _isLoadingCheckins = true;
  bool _isSubmittingCheckin = false;
  String? _locationError;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController _locationNameCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _locationNameCtrl.dispose();
    _addressCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    _loadProfile();
    await Future.wait([
      _loadCurrentPosition(),
      _loadCheckins(),
    ]);
  }

  Future<void> _loadProfile() async {
    try {
      final cached = await StorageService.getUser();
      if (mounted && cached != null) {
        setState(() => _currentUser = cached);
      }
      final user = await ApiService.getProfile();
      if (mounted) {
        setState(() => _currentUser = user);
      }
    } catch (_) {}
  }

  Future<void> _loadCheckins() async {
    setState(() => _isLoadingCheckins = true);
    try {
      final list = await ApiService.getCheckins();
      if (mounted) {
        setState(() {
          _checkins = list;
          _isLoadingCheckins = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCheckins = false);
      }
    }
  }

  Future<void> _loadCurrentPosition() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) _showGpsServiceDialog();
        throw Exception('กรุณาเปิด GPS / บริการระบุตำแหน่ง');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) _showPermissionDeniedForeverDialog();
        throw Exception('กรุณาเปิดสิทธิ์เข้าถึง GPS ในการตั้งค่า');
      }

      if (permission == LocationPermission.denied) {
        throw Exception('แอปไม่ได้รับสิทธิ์เข้าถึงพิกัด GPS');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      _moveToLatLng(LatLng(position.latitude, position.longitude), zoom: 15.5);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
        _locationError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _moveToLatLng(LatLng target, {double zoom = 15.5}) {
    _mapController.move(target, zoom);
  }

  void _showGpsServiceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_off_rounded, color: AppTheme.accentColor),
            SizedBox(width: 8),
            Text('GPS ปิดอยู่', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('บริการระบุตำแหน่งบนอุปกรณ์ปิดอยู่ กรุณาเปิด GPS เพื่อระบุพิกัดและเช็คอิน'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openLocationSettings();
            },
            child: const Text('เปิดการตั้งค่า GPS'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: AppTheme.errorColor),
            SizedBox(width: 8),
            Text('สิทธิ์เข้าถึงพิกัด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('คุณได้ปฏิเสธสิทธิ์ GPS แบบถาวร กรุณาไปที่การตั้งค่าเพื่อเปิดสิทธิ์ตำแหน่ง'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings();
            },
            child: const Text('ไปที่การตั้งค่าแอป'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, StateSetter modalSetState) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
        modalSetState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เลือกรูปภาพไม่สำเร็จ: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog(StateSetter modalSetState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'เลือกรูปภาพสถานที่',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryColor),
                title: const Text('ถ่ายรูปจากกล้อง'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera, modalSetState);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryColor),
                title: const Text('เลือกจากแกลเลอรี'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery, modalSetState);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCheckinModal() {
    final position = _currentPosition;
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_locationError ?? 'กำลังรอรับสัญญาณ GPS กรุณารอสักครู่...'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      _loadCurrentPosition();
      return;
    }

    if (_locationNameCtrl.text.isEmpty) {
      _locationNameCtrl.text = 'เช็คอิน ณ พิกัด (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.add_location_alt_rounded, color: AppTheme.primaryColor, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'เช็คอินพิกัดตำแหน่งของคุณ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Image Preview & Upload Button
                  GestureDetector(
                    onTap: () => _showImageSourceDialog(setModalState),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedImage == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 36, color: AppTheme.primaryColor),
                                SizedBox(height: 6),
                                Text(
                                  'แตะเพื่อถ่ายรูปหรือเลือกรูปสถานที่',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                ),
                              ],
                            )
                          : Stack(
                              children: [
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Location Name
                  TextField(
                    controller: _locationNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อสถานที่ *',
                      hintText: 'เช่น คาเฟ่, ที่ทำงาน, บ้าน',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Address
                  TextField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ที่อยู่ / จุดสังเกต (ไม่บังคับ)',
                      hintText: 'เช่น ถนนสุขุมวิท ซอย 21',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextField(
                    controller: _descriptionCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'ความรู้สึก / ข้อความเช็คอิน (ไม่บังคับ)',
                      hintText: 'เช่น บรรยากาศดีมาก แวะมาทานกาแฟ...',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Submit Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmittingCheckin
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await _submitCheckin();
                            },
                      child: _isSubmittingCheckin
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'ปักหมุดเช็คอินเดี๋ยวนี้',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitCheckin() async {
    final position = _currentPosition;
    if (position == null) return;

    final locName = _locationNameCtrl.text.trim();
    if (locName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาระบุชื่อสถานที่'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isSubmittingCheckin = true);
    try {
      final newCheckin = await ApiService.createCheckin(
        lat: position.latitude,
        lng: position.longitude,
        locationName: locName,
        address: _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
        accuracy: position.accuracy,
        description: _descriptionCtrl.text.trim().isNotEmpty ? _descriptionCtrl.text.trim() : null,
        imageFile: _selectedImage,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 เช็คอิน "${newCheckin.locationName}" สำเร็จเรียบร้อย!'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _selectedImage = null;
        _locationNameCtrl.clear();
        _addressCtrl.clear();
        _descriptionCtrl.clear();
        _selectedCheckin = newCheckin;
      });

      // Reload checkins list and pan map
      await _loadCheckins();
      _moveToLatLng(LatLng(newCheckin.lat, newCheckin.lng), zoom: 16.5);
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
      if (mounted) setState(() => _isSubmittingCheckin = false);
    }
  }

  void _showCheckinDetailSheet(CheckinModel item) {
    setState(() => _selectedCheckin = item);
    _moveToLatLng(LatLng(item.lat, item.lng), zoom: 16.5);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final user = item.user;
        final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // User Header
              Row(
                children: [
                  AppAvatar(
                    imageUrl: user?.profileImage,
                    name: user?.name ?? 'U',
                    radius: 22,
                    fontSize: 16,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name.isNotEmpty == true ? user!.name : 'เพื่อนในระบบ',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        Text(
                          item.createdAt != null ? '${item.createdAt!.day}/${item.createdAt!.month}/${item.createdAt!.year} ${item.createdAt!.hour.toString().padLeft(2, '0')}:${item.createdAt!.minute.toString().padLeft(2, '0')} น.' : 'เมื่อสักครู่',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Location Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: AppTheme.accentColor, size: 22),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.locationName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ),
                ],
              ),

              if (item.address != null && item.address!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Text(
                    item.address!,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ),
              ],

              if (item.description != null && item.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    item.description!,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.4),
                  ),
                ),
              ],

              if (hasImage) ...[
                const SizedBox(height: 14),
                AppImage(
                  imageUrl: item.imageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(16),
                ),
              ],

              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CheckinsFeedScreen()),
                    );
                  },
                  icon: const Icon(Icons.dynamic_feed_outlined),
                  label: const Text('ดูฟีดเช็คอินทั้งหมด'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userPos = _currentPosition;
    final hasUserLocation = userPos != null;
    final mapCenter = hasUserLocation
        ? LatLng(userPos.latitude, userPos.longitude)
        : (_checkins.isNotEmpty
            ? LatLng(_checkins.first.lat, _checkins.first.lng)
            : const LatLng(13.7563, 100.5018)); // Bangkok

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // 1. Full-screen OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: 15.0,
              minZoom: 3.0,
              maxZoom: 19.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.followme.app',
                maxZoom: 19,
              ),

              // Markers Layer: Friends Check-ins + User GPS
              MarkerLayer(
                markers: [
                  // Friends' Checkin Pins
                  ..._checkins.map((item) {
                    final isSelected = _selectedCheckin?.id == item.id;

                    return Marker(
                      point: LatLng(item.lat, item.lng),
                      width: 70,
                      height: 70,
                      child: GestureDetector(
                        onTap: () => _showCheckinDetailSheet(item),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.accentColor : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isSelected ? AppTheme.accentColor : Colors.black).withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: AppAvatar(
                                imageUrl: item.user?.profileImage,
                                name: item.user?.name ?? '📍',
                                radius: 18,
                                backgroundColor: AppTheme.accentColor.withValues(alpha: 0.15),
                                textColor: AppTheme.accentColor,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.accentColor : Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                                ],
                              ),
                              child: Text(
                                item.locationName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Current User GPS Marker (Pulsing Pin)
                  if (hasUserLocation)
                    Marker(
                      point: LatLng(userPos.latitude, userPos.longitude),
                      width: 64,
                      height: 64,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_pin_circle_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // 2. Top Header Bar (Floating Glassmorphism)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, color: AppTheme.textPrimary, size: 26),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'followme',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          _isLoadingCheckins
                              ? 'กำลังโหลดหมุดเพื่อน...'
                              : 'หมุดเช็คอินในระบบ ${_checkins.length} จุด',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Refresh Button
                  IconButton(
                    icon: _isLoadingCheckins
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                          )
                        : const Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
                    tooltip: 'รีเฟรชแผนที่',
                    onPressed: () {
                      _loadCurrentPosition();
                      _loadCheckins();
                    },
                  ),
                  // Profile Avatar Button
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                    child: AppAvatar(
                      imageUrl: _currentUser?.profileImage,
                      name: _currentUser?.name ?? 'U',
                      radius: 18,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Right Map Controls (My Location & Feed shortcut)
          Positioned(
            right: 16,
            bottom: 210,
            child: Column(
              children: [
                // Feed list shortcut button
                Material(
                  color: Colors.white,
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CheckinsFeedScreen()),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.dynamic_feed_rounded, color: AppTheme.textPrimary, size: 22),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // My Location button
                Material(
                  color: Colors.white,
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: hasUserLocation
                        ? () => _moveToLatLng(LatLng(userPos.latitude, userPos.longitude), zoom: 16.0)
                        : _loadCurrentPosition,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.my_location_rounded,
                        color: hasUserLocation ? AppTheme.primaryColor : AppTheme.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Bottom Horizontal Quick Preview Carousel & Main Check-in CTA Card
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Horizontal Recent Friends Checkin Chips
                if (_checkins.isNotEmpty)
                  Container(
                    height: 52,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _checkins.length > 8 ? 8 : _checkins.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (ctx, idx) {
                        final item = _checkins[idx];
                        final isSelected = _selectedCheckin?.id == item.id;

                        return Material(
                          color: isSelected ? AppTheme.primaryColor : Colors.white,
                          elevation: 3,
                          borderRadius: BorderRadius.circular(26),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(26),
                            onTap: () => _showCheckinDetailSheet(item),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppAvatar(
                                    imageUrl: item.user?.profileImage,
                                    name: item.user?.name ?? 'U',
                                    radius: 14,
                                    backgroundColor: isSelected ? Colors.white24 : AppTheme.primaryColor.withValues(alpha: 0.1),
                                    textColor: isSelected ? Colors.white : AppTheme.primaryColor,
                                    fontSize: 11,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.locationName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Main Check-in Action Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppTheme.primaryColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'พร้อมเช็คอินพิกัดของคุณแล้วหรือยัง?',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isLoadingLocation
                                      ? 'กำลังค้นหาตำแหน่ง GPS ของคุณ...'
                                      : (_locationError != null
                                          ? _locationError!
                                          : 'พิกัดปัจจุบัน: (${userPos!.latitude.toStringAsFixed(4)}, ${userPos.longitude.toStringAsFixed(4)})'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _locationError != null ? AppTheme.errorColor : AppTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Check-in Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _openCheckinModal,
                          icon: const Icon(Icons.add_location_alt_rounded),
                          label: const Text(
                            'เช็คอินสถานที่ตอนนี้',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
