import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Wiederverwendbare Bild-Slideshow / PageView.
class ImageSlideshow extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final BoxFit fit;
  final Widget? emptyPlaceholder;

  const ImageSlideshow({
    super.key,
    required this.imageUrls,
    this.height = 250,
    this.fit = BoxFit.cover,
    this.emptyPlaceholder,
  });

  @override
  State<ImageSlideshow> createState() => _ImageSlideshowState();
}

class _ImageSlideshowState extends State<ImageSlideshow> {
  final PageController _controller = PageController();
  int _current = 0;
  late final bool _autoPlay;

  @override
  void initState() {
    super.initState();
    _autoPlay = widget.imageUrls.length > 1;
    if (_autoPlay) _startAutoPlay();
  }

  void _startAutoPlay() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      final next = (_current + 1) % widget.imageUrls.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _startAutoPlay();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return widget.emptyPlaceholder ??
          Container(
            height: widget.height,
            width: double.infinity,
            color: PommesTheme.surfaceDark,
            child: const Center(
              child: Text('🍟', style: TextStyle(fontSize: 60)),
            ),
          );
    }

    if (widget.imageUrls.length == 1) {
      return ClipRRect(
        child: Image.network(
          widget.imageUrls.first,
          height: widget.height,
          width: double.infinity,
          fit: widget.fit,
          errorBuilder: (_, __, ___) => Container(
            height: widget.height,
            color: PommesTheme.surfaceDark,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.white38, size: 40),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) => Image.network(
              widget.imageUrls[index],
              width: double.infinity,
              fit: widget.fit,
              errorBuilder: (_, __, ___) => Container(
                color: PommesTheme.surfaceDark,
                child: const Center(
                  child:
                      Icon(Icons.broken_image, color: Colors.white38, size: 40),
                ),
              ),
            ),
          ),
          // Dot indicators
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.imageUrls.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _current == i ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _current == i
                        ? PommesTheme.pommesYellow
                        : Colors.white54,
                  ),
                ),
              ),
            ),
          ),
          // Counter
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_current + 1}/${widget.imageUrls.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
