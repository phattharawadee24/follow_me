import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'api_service.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  GoogleMapController? _mapController;
  Position? _position;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isCheckedIn = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPosition();
  }

  Future<void> _loadCurrentPosition() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('กรุณาเปิดบริการระบุตำแหน่งของเครื่อง');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('แอปยังไม่ได้รับสิทธิ์เข้าถึงตำแหน่ง');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;

      setState(() {
        _position = position;
        _isLoading = false;
      });
      _moveToCurrentPosition();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
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

  Future<void> _checkIn() async {
    final position = _position;
    if (position == null) return;
    final token = await ApiService.getToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนเช็คอิน')),
      );
      return;
    }

    try {
      await ApiService.checkin(
        token: token,
        lat: position.latitude,
        lng: position.longitude,
        locationName: 'ตำแหน่งปัจจุบัน',
      );
      if (!mounted) return;
      setState(() => _isCheckedIn = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เช็คอินสำเร็จ เพื่อนของคุณเห็นตำแหน่งนี้แล้ว'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    final hasLocation = position != null;
    final mapPosition = hasLocation
        ? LatLng(position.latitude, position.longitude)
        : const LatLng(14.9734, 102.0964);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('เช็คอิน'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF102A33),
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: mapPosition,
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: hasLocation,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: hasLocation
                ? {
                    Marker(
                      markerId: const MarkerId('current-location'),
                      position: mapPosition,
                      infoWindow: const InfoWindow(title: 'ตำแหน่งของฉัน'),
                    ),
                  }
                : const {},
          ),
          Positioned(
            top: 16,
            right: 16,
            child: _MapIconButton(
              icon: Icons.my_location_rounded,
              onPressed: hasLocation
                  ? _moveToCurrentPosition
                  : _loadCurrentPosition,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _CheckinCard(
              position: position,
              isLoading: _isLoading,
              errorMessage: _errorMessage,
              isCheckedIn: _isCheckedIn,
              onRetry: _loadCurrentPosition,
              onCheckIn: _checkIn,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MapIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: const Padding(
          padding: EdgeInsets.all(13),
          child: Icon(Icons.my_location_rounded, color: Color(0xFF087F8C)),
        ),
      ),
    );
  }
}

class _CheckinCard extends StatelessWidget {
  final Position? position;
  final bool isLoading;
  final String? errorMessage;
  final bool isCheckedIn;
  final VoidCallback onRetry;
  final VoidCallback onCheckIn;

  const _CheckinCard({
    required this.position,
    required this.isLoading,
    required this.errorMessage,
    required this.isCheckedIn,
    required this.onRetry,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final hasPosition = position != null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'ตำแหน่งปัจจุบัน',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('กำลังค้นหาตำแหน่งของคุณ...'),
              ],
            )
          else if (errorMessage != null)
            Row(
              children: [
                const Expanded(child: Text('ยังเข้าถึงตำแหน่งไม่ได้')),
                TextButton(onPressed: onRetry, child: const Text('ลองใหม่')),
              ],
            )
          else
            Text(
              '${position!.latitude.toStringAsFixed(5)}, ${position!.longitude.toStringAsFixed(5)}',
              style: const TextStyle(color: Color(0xFF687780), fontSize: 13),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: hasPosition && !isCheckedIn ? onCheckIn : null,
              icon: Icon(
                isCheckedIn
                    ? Icons.check_circle_rounded
                    : Icons.location_on_rounded,
              ),
              label: Text(isCheckedIn ? 'เช็คอินแล้ว' : 'เช็คอินที่นี่'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF087F8C),
                disabledBackgroundColor: const Color(0xFFB9C8CA),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
