import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A drop-in replacement for [Image.network] that adds:
/// - Disk & memory caching via cached_network_image
/// - Shimmer placeholder while loading
/// - Graceful broken-image error widget
class AppNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _ShimmerPlaceholder(
        width: width,
        height: height,
        colorScheme: colorScheme,
      ),
      errorWidget: (context, url, error) =>
          errorWidget ?? _BrokenImageWidget(colorScheme: colorScheme),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

class _ShimmerPlaceholder extends StatefulWidget {
  final double? width;
  final double? height;
  final ColorScheme colorScheme;

  const _ShimmerPlaceholder({
    this.width,
    this.height,
    required this.colorScheme,
  });

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.colorScheme.surfaceContainer,
                widget.colorScheme.surfaceContainerLow
                    .withAlpha((_animation.value * 255).round()),
                widget.colorScheme.surfaceContainer,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class _BrokenImageWidget extends StatelessWidget {
  final ColorScheme colorScheme;
  const _BrokenImageWidget({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorScheme.surfaceContainer,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 40,
          color: colorScheme.onSurfaceVariant.withAlpha(128),
        ),
      ),
    );
  }
}
