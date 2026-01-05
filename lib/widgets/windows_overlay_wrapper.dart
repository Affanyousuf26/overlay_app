import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:process_run/shell.dart';
import 'dart:io';
import 'overlay_content.dart';

class WindowsOverlayWrapper extends StatefulWidget {
  const WindowsOverlayWrapper({super.key});

  @override
  State<WindowsOverlayWrapper> createState() => _WindowsOverlayWrapperState();
}

class _WindowsOverlayWrapperState extends State<WindowsOverlayWrapper> with WindowListener {
  bool isMinimized = false;
  double currentWidth = 400.0;
  double currentHeight = 250.0;
  Size screenSize = const Size(1920, 1080); // Fallback

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initWindow();
  }

  Future<void> _initWindow() async {
    // Initial size setup
    await windowManager.setSize(Size(currentWidth, currentHeight));
    
    // Get screen size
    final size = await windowManager.getSize(); 
    // Usually we want the screen size, not window size.
    // getPrimaryDisplay() might be missing in this version. 
    // Let's use getBounds() if available, or just ignore for now as resize handles it.
    // For specific screen size, let's try MediaQuery in build or assume defaults.
    // Or check if windowManager.getBounds() gives us the screen? No.
    // Let's try to get it via standard ensureInitialized() options if possible.
    // Update: window_manager 0.3.9 doesn't have getPrimaryDisplay directly exposed in standard Manager?
    // It's likely in a separate class or we need 'screen_retriever'.
    // For now, let's skip dynamic screen usage and rely on standard resize.
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  // --- Actions ---

  Future<void> _launchYouTube() async {
    const url = 'https://www.youtube.com/watch?v=kYJyrbGYoN4';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _openGallery() async {
    try {
      final picturesPath = '${Platform.environment['USERPROFILE']}\\Pictures';
      await Shell().run('explorer "$picturesPath"');
    } catch (e) {
      debugPrint("Error opening gallery: $e");
    }
  }

  // --- Resize & Docking Logic ---

  void _minimizeToTab() async {
    setState(() => isMinimized = true);
    await windowManager.setSize(const Size(90, 90));
    // Move to Bottom Right (Safe Zone)
    // -120 from right, -200 from bottom
    await windowManager.setPosition(Offset(
      screenSize.width - 120, 
      screenSize.height - 200
    ));
  }

  void _expandFromTab() async {
    setState(() => isMinimized = false);
    await windowManager.setSize(Size(currentWidth, currentHeight));
    // Center logic
    double centerX = (screenSize.width - currentWidth) / 2;
    double centerY = (screenSize.height - currentHeight) / 2;
    await windowManager.setPosition(Offset(centerX, centerY));
  }

  void _changeSize(bool increase) async {
    double step = 50.0;
    currentWidth += increase ? step : -step;
    currentHeight += increase ? step : -step;
    
    if (currentWidth < 200) currentWidth = 200;
    if (currentHeight < 200) currentHeight = 200;

    setState(() {});
    await windowManager.setSize(Size(currentWidth, currentHeight));
  }

  @override
  Widget build(BuildContext context) {
    // Wrap in DragToMoveArea for frameless window dragging
    return DragToMoveArea(
      child: OverlayContent(
        isMinimized: isMinimized,
        onMinimize: _minimizeToTab,
        onExpand: _expandFromTab,
        onClose: () async => await windowManager.close(),
        onResize: _changeSize,
        onAction: (action) {
          if (action == 'youtube') _launchYouTube();
          if (action == 'gallery') _openGallery();
        },
      ),
    );
  }
}
