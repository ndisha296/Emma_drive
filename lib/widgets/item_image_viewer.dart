import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';

class ItemImageViewer extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool enableLightbox;
  final String? title;

  const ItemImageViewer({
    super.key,
    required this.imageUrl,
    this.width = double.infinity,
    this.height = 180,
    this.borderRadius,
    this.enableLightbox = true,
    this.title,
  });

  Widget _buildImage() {
    if (imageUrl.startsWith('data:image')) {
      try {
        final commaIdx = imageUrl.indexOf(',');
        final base64Str = commaIdx != -1 ? imageUrl.substring(commaIdx + 1) : imageUrl;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      } catch (_) {
        return _buildFallback();
      }
    } else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AppTheme.darkCardElevated,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryGreen,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    } else {
      return _buildFallback();
    }
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: AppTheme.darkCardElevated,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded, color: AppTheme.textMuted, size: 36),
          const SizedBox(height: 8),
          Text(
            'Photo not available',
            style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _openLightbox(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title ?? 'Waste Item Inspection',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.6,
                  child: _buildImage(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pinch to zoom and inspect item details',
              style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);

    final content = ClipRRect(
      borderRadius: radius,
      child: _buildImage(),
    );

    if (!enableLightbox) return content;

    return GestureDetector(
      onTap: () => _openLightbox(context),
      child: Stack(
        children: [
          content,
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
