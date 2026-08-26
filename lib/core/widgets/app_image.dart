import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../constants/api_endpoints.dart';
import '../theme/app_theme.dart';

class AppImageHelper {
  /// Resolves any image URL or Data URI into a valid ImageProvider.
  /// Supports:
  /// - Base64 Data URI ("data:image/jpeg;base64,...")
  /// - Direct HTTP/HTTPS URLs ("https://storage.googleapis.com/...")
  /// - Relative URLs ("/uploads/...")
  /// - Pure Base64 strings
  static ImageProvider? getImageProvider(String? source) {
    if (source == null || source.trim().isEmpty) return null;
    final cleaned = source.trim();

    // 1. Data URI with Base64
    if (cleaned.startsWith('data:image/') || cleaned.startsWith('data:application/')) {
      try {
        final commaIdx = cleaned.indexOf(',');
        if (commaIdx != -1) {
          final base64Data = cleaned.substring(commaIdx + 1);
          final bytes = base64Decode(base64Data);
          return MemoryImage(bytes);
        }
      } catch (_) {}
    }

    // 2. Full HTTP or HTTPS URL
    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return NetworkImage(cleaned);
    }

    // 3. Relative path from Backend
    if (cleaned.startsWith('/')) {
      return NetworkImage('${ApiEndpoints.baseUrl}$cleaned');
    }

    // 4. Fallback: Try decoding as pure Base64 if long enough
    if (cleaned.length > 100 && !cleaned.contains(' ')) {
      try {
        final bytes = base64Decode(cleaned);
        return MemoryImage(bytes);
      } catch (_) {}
    }

    return null;
  }

  /// Extracts Uint8List bytes if the source is a Base64 string
  static Uint8List? getBytesIfBase64(String? source) {
    if (source == null || source.trim().isEmpty) return null;
    final cleaned = source.trim();

    if (cleaned.startsWith('data:image/') || cleaned.startsWith('data:application/')) {
      try {
        final commaIdx = cleaned.indexOf(',');
        if (commaIdx != -1) {
          return base64Decode(cleaned.substring(commaIdx + 1));
        }
      } catch (_) {}
    }

    if (cleaned.length > 100 && !cleaned.contains(' ') && !cleaned.startsWith('http')) {
      try {
        return base64Decode(cleaned);
      } catch (_) {}
    }

    return null;
  }

  /// Returns full HTTP URL if applicable
  static String? getResolvedUrl(String? source) {
    if (source == null || source.trim().isEmpty) return null;
    final cleaned = source.trim();
    if (cleaned.startsWith('http://') || cleaned.startsWith('https://')) {
      return cleaned;
    }
    if (cleaned.startsWith('/')) {
      return '${ApiEndpoints.baseUrl}$cleaned';
    }
    return null;
  }
}

/// A versatile widget to display images from Network, Base64 Data URI, or Relative URLs with smooth loading and error handling.
class AppImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _buildErrorWidget();
    }

    final bytes = AppImageHelper.getBytesIfBase64(imageUrl);
    final resolvedUrl = AppImageHelper.getResolvedUrl(imageUrl);

    Widget imageWidget;
    if (bytes != null) {
      imageWidget = Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else if (resolvedUrl != null) {
      imageWidget = Image.network(
        resolvedUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return placeholder ??
              Container(
                width: width,
                height: height,
                color: const Color(0xFFF1F5F9),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else {
      imageWidget = _buildErrorWidget();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildErrorWidget() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Color(0xFF94A3B8),
              size: 28,
            ),
          ),
        );
  }
}

/// A circular avatar that supports Base64, Network, and fallbacks to User initials.
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;

  const AppAvatar({
    super.key,
    required this.imageUrl,
    this.name = 'User',
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final imageProvider = AppImageHelper.getImageProvider(imageUrl);
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

    final bgColor = backgroundColor ?? AppTheme.primaryColor.withValues(alpha: 0.12);
    final txtColor = textColor ?? AppTheme.primaryColor;
    final fSize = fontSize ?? (radius * 0.85);

    if (imageProvider != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        backgroundImage: imageProvider,
        onBackgroundImageError: (exception, stackTrace) {
          // Handled automatically by fallback child
        },
        child: null,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: fSize,
          fontWeight: FontWeight.bold,
          color: txtColor,
        ),
      ),
    );
  }
}
