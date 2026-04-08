import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class GalleryMediaCard extends StatefulWidget {
  final String url;
  final String type;
  final String title;
  final String description;
  final VoidCallback onOpen;

  const GalleryMediaCard({
    super.key,
    required this.url,
    required this.type,
    required this.title,
    required this.description,
    required this.onOpen,
  });

  @override
  State<GalleryMediaCard> createState() => _GalleryMediaCardState();
}

class _GalleryMediaCardState extends State<GalleryMediaCard> {
  VideoPlayerController? _controller;
  bool _isMuted = true;

  bool get _isVideo => widget.type == 'video';

  @override
  void initState() {
    super.initState();
    if (_isVideo) {
      _controller = VideoPlayerController.network(widget.url)
        ..initialize().then((_) {
          _controller!.setLooping(true);
          _controller!.setVolume(0);
          if (mounted) {
            setState(() {});
          }
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() {
      _isMuted = !_isMuted;
      controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: AspectRatio(
              aspectRatio: 1.12,
              child: _isVideo ? _buildVideoPreview() : _buildImagePreview(),
            ),
          ),
          if (widget.title.isNotEmpty || widget.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.title.isNotEmpty)
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF183020),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  if (widget.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onOpen,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFE8E1D5),
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported_outlined, size: 36),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _OverlayActionButton(
                icon: Icons.open_in_full_rounded,
                onPressed: widget.onOpen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    final controller = _controller;
    final isReady = controller != null && controller.value.isInitialized;
    final isPlaying = isReady && controller.value.isPlaying;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (isReady)
          GestureDetector(
            onTap: _togglePlayback,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          )
        else
          Container(
            color: const Color(0xFFE8E1D5),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: Color(0xFF2F6A3E)),
          ),
        Positioned(
          top: 12,
          right: 12,
          child: _OverlayActionButton(
            icon: Icons.open_in_full_rounded,
            onPressed: widget.onOpen,
          ),
        ),
        Positioned.fill(
          child: Center(
            child: _OverlayPlayButton(
              icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              onPressed: _togglePlayback,
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 16,
          child: _OverlayActionButton(
            icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            onPressed: _toggleMute,
          ),
        ),
        if (isReady)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: Colors.black.withOpacity(0.18),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Color(0xB3FFFFFF),
                  backgroundColor: Color(0x66FFFFFF),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OverlayActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _OverlayActionButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.36),
        borderRadius: BorderRadius.circular(999),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        splashRadius: 20,
      ),
    );
  }
}

class _OverlayPlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _OverlayPlayButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 34, color: const Color(0xFF2F6A3E)),
        iconSize: 34,
        padding: const EdgeInsets.all(14),
        splashRadius: 28,
      ),
    );
  }
}
