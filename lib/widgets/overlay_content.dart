import 'package:flutter/material.dart';

// Callback definitions for abstracting platform specific actions
typedef OnMinimize = void Function();
typedef OnClose = void Function();
typedef OnResize = void Function(bool increase);
typedef OnAction = void Function(String action);

class OverlayContent extends StatefulWidget {
  final OnMinimize onMinimize;
  final OnClose onClose;
  final OnResize onResize;
  final OnAction onAction;
  final bool isMinimized;
  final VoidCallback onExpand;

  const OverlayContent({
    super.key,
    required this.onMinimize,
    required this.onClose,
    required this.onResize,
    required this.onAction,
    required this.isMinimized,
    required this.onExpand,
  });

  @override
  State<OverlayContent> createState() => _OverlayContentState();
}

class _OverlayContentState extends State<OverlayContent> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: widget.isMinimized
          ? _buildMinimizedTab()
          : GestureDetector(
              key: const ValueKey("Panel"),
              // Optional: Add drag/scale handling here if not handled by platform shell
              child: _buildExpandedPanel(),
            ),
    );
  }

  Widget _buildMinimizedTab() {
    return GestureDetector(
      key: const ValueKey("Icon"),
      onTap: widget.onExpand,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6), // Semi-transparent black
          shape: BoxShape.circle,
          border: Border.all(color: Colors.greenAccent, width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.greenAccent.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2)
          ],
        ),
        child: const Center(
          child: Icon(Icons.webhook, color: Colors.greenAccent, size: 40),
        ),
      ),
    );
  }

  Widget _buildExpandedPanel() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24, width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)
            ]),
        child: Column(
          children: [
            // Header
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.drag_indicator,
                      color: Colors.white54, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Quick Tools",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.minimize, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: widget.onMinimize,
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: widget.onClose,
                        child: const Icon(Icons.close,
                            color: Colors.redAccent, size: 24),
                      ),
                    ],
                  )
                ],
              ),
            ),

            // Content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton("YouTube", Icons.play_circle_fill,
                          Colors.red, () => widget.onAction('youtube')),
                      const SizedBox(width: 20),
                      _buildActionButton("Gallery", Icons.photo_library,
                          Colors.blue, () => widget.onAction('gallery')),
                    ],
                  ),
                ),
              ),
            ),

            // Footer (Resize)
            Container(
              height: 40,
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => widget.onResize(false),
                    child: const Icon(Icons.remove_circle_outline,
                        color: Colors.white54, size: 20),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("Resize",
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                  GestureDetector(
                    onTap: () => widget.onResize(true),
                    child: const Icon(Icons.add_circle_outline,
                        color: Colors.white54, size: 20),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ],
    );
  }
}
