import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/constants.dart';

/// Cached network image with loading and error states
class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImageWidget({
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
    return ClipRRect(
      borderRadius:
          borderRadius ??
          BorderRadius.circular(AppConstants.defaultBorderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ??
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: width,
                height: height,
                color: Colors.white,
              ),
            ),
        errorWidget: (context, url, error) =>
            errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: Icon(
                Icons.broken_image_outlined,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
      ),
    );
  }
}

/// Circular avatar with cached image
class CachedAvatarImage extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Widget? placeholder;

  const CachedAvatarImage({
    super.key,
    required this.imageUrl,
    this.radius = 40,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      imageBuilder: (context, imageProvider) =>
          CircleAvatar(radius: radius, backgroundImage: imageProvider),
      placeholder: (context, url) =>
          placeholder ??
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: CircleAvatar(radius: radius, backgroundColor: Colors.white),
          ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primaryLight,
        child: Icon(Icons.person, size: radius, color: AppColors.primaryColor),
      ),
    );
  }
}

/// Bottle image with optimized caching
class BottleImageWidget extends StatelessWidget {
  final String imageUrl;
  final double size;

  const BottleImageWidget({super.key, required this.imageUrl, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return CachedImageWidget(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(12),
      errorWidget: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.recycling,
          size: size * 0.5,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }
}

/// Machine image widget
class MachineImageWidget extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;

  const MachineImageWidget({
    super.key,
    required this.imageUrl,
    this.width = 120,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return CachedImageWidget(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorWidget: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: const Icon(
          Icons.dns_outlined,
          size: 40,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
