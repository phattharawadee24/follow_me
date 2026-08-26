import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_image.dart';
import '../../../models/checkin_model.dart';

class CheckinCard extends StatelessWidget {
  final CheckinModel checkin;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CheckinCard({
    super.key,
    required this.checkin,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
  });

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'เมื่อสักครู่';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = checkin.user;
    final hasImage = checkin.imageUrl != null && checkin.imageUrl!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Time, and More Menu
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                AppAvatar(
                  imageUrl: user?.profileImage,
                  name: user?.name ?? 'U',
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name.isNotEmpty == true ? user!.name : 'ผู้ใช้งาน',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        _formatDateTime(checkin.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8)),
                    onSelected: (value) {
                      if (value == 'edit') onEdit?.call();
                      if (value == 'delete') onDelete?.call();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('แก้ไข'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 18),
                            SizedBox(width: 8),
                            Text('ลบ', style: TextStyle(color: AppTheme.errorColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Location Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.place_rounded, color: AppTheme.accentColor, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    checkin.locationName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (checkin.address != null && checkin.address!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 14, top: 2),
              child: Text(
                checkin.address!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],

          // Description Text
          if (checkin.description != null && checkin.description!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, top: 8),
              child: Text(
                checkin.description!,
                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.4),
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Image if attached
          if (hasImage)
            AppImage(
              imageUrl: checkin.imageUrl,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}
