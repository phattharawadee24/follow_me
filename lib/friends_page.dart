import 'package:flutter/material.dart';

/// ==========================================================
/// โมเดลข้อมูลเพื่อน (ปรับ field ให้ตรงกับ backend ของพี่)
/// ==========================================================
class Friend {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastCheckinAt;
  final String? lastCheckinPlace;
  final double? lat;
  final double? lng;

  Friend({
    required this.id,
    required  this.name,
    this.avatarUrl,
    this.isOnline = false,
    this.lastCheckinAt,
    this.lastCheckinPlace,
    this.lat,
    this.lng,
  });
}

/// คำขอเป็นเพื่อนที่ยังไม่ได้ตอบรับ
class FriendRequest {
  final String id;
  final String name;
  final String? avatarUrl;

  FriendRequest({required this.id, required this.name, this.avatarUrl});
}

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  // TODO: แทนที่ mock data นี้ด้วยการดึงจาก Firestore/API จริง
  List<Friend> _friends = [
    Friend(
      id: '1',
      name: 'น้องพลอย',
      isOnline: true,
      lastCheckinAt: DateTime.now().subtract(const Duration(minutes: 5)),
      lastCheckinPlace: 'เซ็นทรัลเวิลด์',
      lat: 13.7466,
      lng: 100.5393,
    ),
    Friend(
      id: '2',
      name: 'พี่บอส',
      isOnline: false,
      lastCheckinAt: DateTime.now().subtract(const Duration(hours: 3)),
      lastCheckinPlace: 'มหาวิทยาลัยศรีสะเกษ',
      lat: 15.1186,
      lng: 104.3220,
    ),
    Friend(
      id: '3',
      name: 'แนน',
      isOnline: true,
      lastCheckinAt: DateTime.now().subtract(const Duration(days: 1)),
      lastCheckinPlace: 'ตลาดนัดจตุจักร',
      lat: 13.7999,
      lng: 100.5500,
    ),
  ];

  List<FriendRequest> _requests = [FriendRequest(id: 'r1', name: 'เจมส์')];

  List<Friend> get _filteredFriends {
    if (_searchQuery.isEmpty) return _friends;
    return _friends
        .where((f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    // TODO: เรียก API/Firestore เพื่อโหลดรายชื่อเพื่อนใหม่
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _isLoading = false);
  }

  void _openAddFriendSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddFriendSheet(
        onAddByUsername: (username) {
          // TODO: เรียก API เพื่อส่งคำขอเป็นเพื่อนด้วย username
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ส่งคำขอเป็นเพื่อนไปยัง $username แล้ว')),
          );
        },
      ),
    );
  }

  void _acceptRequest(FriendRequest request) {
    setState(() {
      _requests.removeWhere((r) => r.id == request.id);
      _friends.add(Friend(id: request.id, name: request.name, isOnline: false));
    });
    // TODO: เรียก API เพื่อยืนยันรับเป็นเพื่อนจริง
  }

  void _declineRequest(FriendRequest request) {
    setState(() {
      _requests.removeWhere((r) => r.id == request.id);
    });
    // TODO: เรียก API เพื่อปฏิเสธคำขอ
  }

  void _viewOnMap(Friend friend) {
    if (friend.lat == null || friend.lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เพื่อนคนนี้ยังไม่มีตำแหน่งล่าสุด')),
      );
      return;
    }
    // TODO: เชื่อมกับหน้า MapPage จริง เช่น
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (_) => MapPage(focusLat: friend.lat, focusLng: friend.lng),
    // ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ไปที่ตำแหน่งของ ${friend.name} บนแผนที่')),
    );
  }

  String _formatLastSeen(DateTime? dt) {
    if (dt == null) return 'ยังไม่เคยเช็คอิน';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'เมื่อสักครู่';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    return '${diff.inDays} วันที่แล้ว';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพื่อน'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'เพิ่มเพื่อน',
            onPressed: _openAddFriendSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // ช่องค้นหา
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหาเพื่อน',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),

            // คำขอเป็นเพื่อน
            if (_requests.isNotEmpty) ...[
              Text(
                'คำขอเป็นเพื่อน (${_requests.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._requests.map(
                (req) => _RequestTile(
                  request: req,
                  onAccept: () => _acceptRequest(req),
                  onDecline: () => _declineRequest(req),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // รายชื่อเพื่อน
            Text(
              'เพื่อนทั้งหมด (${_friends.length})',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filteredFriends.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'ยังไม่มีเพื่อน ลองเพิ่มเพื่อนดูสิ'
                        : 'ไม่พบเพื่อนที่ค้นหา',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ..._filteredFriends.map(
                (friend) => _FriendTile(
                  friend: friend,
                  lastSeenText: _formatLastSeen(friend.lastCheckinAt),
                  onTap: () => _viewOnMap(friend),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ==========================================================
/// การ์ดแสดงเพื่อนแต่ละคน
/// ==========================================================
class _FriendTile extends StatelessWidget {
  final Friend friend;
  final String lastSeenText;
  final VoidCallback onTap;

  const _FriendTile({
    required this.friend,
    required this.lastSeenText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: friend.avatarUrl != null
                  ? NetworkImage(friend.avatarUrl!)
                  : null,
              child: friend.avatarUrl == null
                  ? Text(friend.name.isNotEmpty ? friend.name[0] : '?')
                  : null,
            ),
            if (friend.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          friend.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          friend.lastCheckinPlace != null
              ? '${friend.lastCheckinPlace} · $lastSeenText'
              : lastSeenText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.map_outlined),
      ),
    );
  }
}

/// ==========================================================
/// การ์ดแสดงคำขอเป็นเพื่อน
/// ==========================================================
class _RequestTile extends StatelessWidget {
  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestTile({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundImage: request.avatarUrl != null
              ? NetworkImage(request.avatarUrl!)
              : null,
          child: request.avatarUrl == null
              ? Text(request.name.isNotEmpty ? request.name[0] : '?')
              : null,
        ),
        title: Text(request.name),
        subtitle: const Text('ต้องการเป็นเพื่อนกับคุณ'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: onAccept,
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: onDecline,
            ),
          ],
        ),
      ),
    );
  }
}

/// ==========================================================
/// Bottom sheet สำหรับเพิ่มเพื่อนด้วย username
/// ==========================================================
class _AddFriendSheet extends StatefulWidget {
  final void Function(String username) onAddByUsername;

  const _AddFriendSheet({required this.onAddByUsername});

  @override
  State<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<_AddFriendSheet> {
  final TextEditingController _usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'เพิ่มเพื่อน',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username ของเพื่อน',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: เปิดกล้องสแกน QR code เพื่อเพิ่มเพื่อน
              Navigator.pop(context);
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('สแกน QR code'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              final username = _usernameController.text.trim();
              if (username.isEmpty) return;
              widget.onAddByUsername(username);
              Navigator.pop(context);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('ส่งคำขอเป็นเพื่อน'),
            ),
          ),
        ],
      ),
    );
  }
}
