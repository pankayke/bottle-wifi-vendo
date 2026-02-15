import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Shimmer-style skeleton placeholder for loading states.
class LoadingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12,
  });

  /// Convenience constructor for a card-shaped skeleton.
  const LoadingSkeleton.card({
    super.key,
    this.width = double.infinity,
    this.height = 120,
    this.borderRadius = 20,
  });

  /// Convenience constructor for a text-line skeleton.
  const LoadingSkeleton.text({
    super.key,
    this.width = 160,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: BWColors.divider,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

/// A full card skeleton placeholder used in list loading states.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: BWColors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BWSpacing.cardRadius),
      ),
      child: const Padding(
        padding: EdgeInsets.all(BWSpacing.md),
        child: Row(
          children: [
            LoadingSkeleton(width: 48, height: 48, borderRadius: 12),
            SizedBox(width: BWSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingSkeleton.text(width: 140, height: 14),
                  SizedBox(height: BWSpacing.sm),
                  LoadingSkeleton.text(width: 200, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
