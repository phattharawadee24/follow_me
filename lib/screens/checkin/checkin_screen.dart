import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/errors/api_exception.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  GoogleMapController? _mapController;
  Position? _position;
  String? _errorMessage;
  bool _isLoadingLocation = true;
  bool _isSubmitting = false;

  File? _selectedImage;
  final _locationNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCurrentPosition();
  }

  @override
  void dispose() {
    _locationNameCtrl.dispose();
    _addressCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentPosition() async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('กรุณาเปิด GPS/บริการระบุตำแหน่งบนอุปกรณ์');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('แอปไม่ได้รับสิทธิ์เข้าถึงพิกัด GPS');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        _position = position;
        _isLoadingLocation = false;
      });
      _moveToCurrentPosition();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _moveToCurrentPosition() {
    final position = _position;
    if (position == null) return;

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        16,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเลือกรูปภาพได้: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
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
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryColor),
                title: const Text('เลือกจากแกลเลอรี'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCheckinDialog() {
    final position = _position;
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่ได้รับพิกัดตำแหน่ง กรุณารอสักครู่')),
      );
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
                      const Text(
                        'บันทึกการเช็คอิน',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
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
                    onTap: () async {
                      Navigator.pop(ctx);
                      _showImageSourceDialog();
                    },
                    child: Container(
                      height: 160,
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
                                Icon(Icons.add_a_photo_outlined,
                                    size: 38, color: AppTheme.primaryColor),
                                SizedBox(height: 8),
                                Text(
                                  'แตะเพื่อถ่ายภาพหรือเลือกรูป',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
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
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 16,
                                    ),
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
                      hintText: 'เช่น สยามพารากอน, บ้าน',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Address
                  TextField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ที่อยู่ / จุดสังเกต (ไม่บังคับ)',
                      hintText: 'เช่น ถ.พระราม 1 แขวงปทุมวัน',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextField(
                    controller: _descriptionCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'คำอธิบาย (ไม่บังคับ)',
                      hintText: 'เช่น มาเที่ยวกับเพื่อน...',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await _performCheckin();
                            },
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'ยืนยันการเช็คอิน',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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

  Future<void> _performCheckin() async {
    final position = _position;
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

    setState(() => _isSubmitting = true);
    try {
      final checkin = await ApiService.createCheckin(
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
          content: Text('เช็คอิน "${checkin.locationName}" สำเร็จเรียบร้อย!'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _selectedImage = null;
        _locationNameCtrl.clear();
        _addressCtrl.clear();
        _descriptionCtrl.clear();
      });
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    final hasLocation = position != null;
    final mapCenter = hasLocation
        ? LatLng(position.latitude, position.longitude)
        : const LatLng(13.7563, 100.5018); // Default Bangkok

    return Scaffold(
      appBar: AppBar(
        title: const Text('เช็คอินพิกัดตำแหน่ง'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'รีเฟรชพิกัด',
            onPressed: _loadCurrentPosition,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map View
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: mapCenter,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: hasLocation,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: hasLocation
                ? {
                    Marker(
                      markerId: const MarkerId('current-user-pos'),
                      position: mapCenter,
                      infoWindow: const InfoWindow(title: 'ตำแหน่งของคุณในขณะนี้'),
                    ),
                  }
                : const {},
          ),

          // Top action buttons
          Positioned(
            top: 16,
            right: 16,
            child: Material(
              color: Colors.white,
              elevation: 4,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: hasLocation ? _moveToCurrentPosition : _loadCurrentPosition,
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.my_location_rounded,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
          ),

          // Bottom card
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(18),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_pin,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ตำแหน่งของคุณในปัจจุบัน',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (_isLoadingLocation)
                              const Text(
                                'กำลังจับสัญญาณ GPS...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              )
                            else if (_errorMessage != null)
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.errorColor,
                                ),
                              )
                            else
                              Text(
                                'ละติจูด: ${position!.latitude.toStringAsFixed(5)}, ลองจิจูด: ${position.longitude.toStringAsFixed(5)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Button to trigger check in
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: hasLocation && !_isSubmitting ? _openCheckinDialog : null,
                      icon: const Icon(Icons.add_location_alt_rounded),
                      label: Text(_isSubmitting ? 'กำลังบันทึก...' : 'เช็คอินสถานที่นี้'),
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
          ),
        ],
      ),
    );
  }
}
