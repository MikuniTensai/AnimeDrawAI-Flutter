import 'package:flutter/material.dart';

/// A widget that allows pinch-to-zoom and pan on any child widget.
/// Equivalent to Android's ZoomableImage composable.
class ZoomableImage extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;

  const ZoomableImage({
    super.key,
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 4.0,
  });

  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage>
    with SingleTickerProviderStateMixin {
  final TransformationController _controller = TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        )..addListener(() {
          if (_animation != null) {
            _controller.value = _animation!.value;
          }
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    final currentScale = _controller.value.getMaxScaleOnAxis();
    final isZoomedIn = currentScale > 1.5;

    final target = isZoomedIn
        ? Matrix4.identity()
        : Matrix4.diagonal3Values(2.5, 2.5, 1.0);

    _animation = Matrix4Tween(begin: _controller.value, end: target).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: widget.minScale,
        maxScale: widget.maxScale,
        child: widget.child,
      ),
    );
  }
}
