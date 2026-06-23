// lib/widgets/cover_image.dart
//
// Cross-platform cover image widget.
// CachedNetworkImage silently fails on Flutter Web for Supabase storage URLs
// (known Embre learning) — use Image.network on web, CachedNetworkImage
// elsewhere for proper disk caching on mobile/desktop.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';

class CoverImage extends StatelessWidget {
  /// Filename only (as stored in works.cover_url) — NOT a full URL.
  final String? coverFilename;
  final double  width;
  final double? height;
  final BorderRadius borderRadius;

  const CoverImage({
    super.key,
    required this.coverFilename,
    required this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    final h = height ?? width / AppConfig.coverAspectRatio;

    if (coverFilename == null || coverFilename!.isEmpty) {
      return _placeholder(context, h);
    }

    final url = AppConfig.coverUrl(coverFilename!);

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: h,
        child: kIsWeb
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(context, h),
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => _placeholder(context, h),
                errorWidget: (_, __, ___) => _placeholder(context, h),
              ),
      ),
    );
  }

  Widget _placeholder(BuildContext context, double h) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: width,
        height: h,
        color: AppTheme.lightBeige,
        alignment: Alignment.center,
        child: Icon(
          Icons.menu_book_outlined,
          size: width * 0.35,
          color: AppTheme.espresso.withOpacity(0.4),
        ),
      ),
    );
  }
}
