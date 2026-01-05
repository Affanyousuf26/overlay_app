import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'overlay_content.dart';

class OverlayLayout extends StatefulWidget {
  const OverlayLayout({super.key});

  @override
  State<OverlayLayout> createState() => _OverlayLayoutState();
}

class _OverlayLayoutState extends State<OverlayLayout> {
  // State
  bool isMinimized = false;
  
  // Size Management
  double currentWidth = 400.0;
  double currentHeight = 250.0;
  double screenWidth = 1080.0; // Default fallback
  double screenHeight = 1920.0;

  @override
  void initState() {
    super.initState();
    // 1. Force the window to match our expected initial size
    // Use a delay to ensure the platform channel is ready
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        await FlutterOverlayWindow.resizeOverlay(currentWidth.toInt(), currentHeight.toInt(), true);
      } catch (e) {
        debugPrint("Error resizing overlay on init: $e");
      }
    });
    
    // Request screen size from main app
    FlutterOverlayWindow.shareData('get_screen_size');
    
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (mounted) {
        setState(() {
          if (event is Map) {
            if (event.containsKey('screen_width')) screenWidth = (event['screen_width'] as num).toDouble();
            if (event.containsKey('screen_height')) screenHeight = (event['screen_height'] as num).toDouble();
          }
        });
      }
    });
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  // --- Actions ---

  Future<void> _launchYouTube() async {
    debugPrint("🔴 OVERLAY: Launching YouTube via Intent");
    try {
      // Using AndroidIntent directly bypasses the "Foreground Activity" requirement of url_launcher
      const intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: 'https://www.youtube.com/watch?v=kYJyrbGYoN4',
        package: 'com.google.android.youtube', // Target YouTube App directly
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    } catch (e) {
      debugPrint("🔴 Error launching YouTube App: $e");
      // Fallback to Browser
      try {
        const browserIntent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'https://www.youtube.com/watch?v=kYJyrbGYoN4',
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await browserIntent.launch();
      } catch (e2) {
        debugPrint("🔴 Error launching Browser Fallback: $e2");
      }
    }
  }

  Future<void> _openGallery() async {
    debugPrint("🔴 OVERLAY: Opening Gallery Direct");
    try {
      const intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        type: 'image/*',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK], // Required when launching from Service
      );
      await intent.launch();
    } catch (e) {
      debugPrint("Error launching Gallery: $e");
    }
  }

  // --- Actions ---


  // --- Resize & Docking Logic ---

  // --- Actions ---


  // --- Resize & Docking Logic ---

  void _minimizeToTab() async {
    // 1. Trigger Animation to "Icon Mode"
    setState(() => isMinimized = true);
    
    // 2. Wait for animation to finish (optional, but looks better if we shrink window after)
    // However, resizing window is instant, so we usually just do it.
    
    // 3. Resize Window to small square
    await FlutterOverlayWindow.resizeOverlay(90, 90, true);
    
    // 4. Move to Bottom Right (Safe Zone)
    // Using a fixed offset from the top-left if screen dimensions are unreliable
    // But let's try a safer calculation:
    // If screenWidth is default 1080, -100 is 980.
    await FlutterOverlayWindow.moveOverlay(
      OverlayPosition(screenWidth > 0 ? screenWidth - 120 : 200, screenHeight > 0 ? screenHeight - 300 : 400),
    );
  }

  void _expandFromTab() async {
    // 1. Resize Window to Previous Panel Size
    await FlutterOverlayWindow.resizeOverlay(currentWidth.toInt(), currentHeight.toInt(), true);
    
    // 2. Move to Center safely
    double centerX = (screenWidth - currentWidth) / 2;
    double centerY = (screenHeight - currentHeight) / 2;
    if (centerX < 0) centerX = 50;
    if (centerY < 0) centerY = 100;

    await FlutterOverlayWindow.moveOverlay(
       OverlayPosition(centerX, centerY)
    );

    // 3. Trigger Animation
    setState(() => isMinimized = false);
  }

  void _changeSize(bool increase) async {
    double step = 50.0;
    
    double newW = currentWidth + (increase ? step : -step);
    double newH = currentHeight + (increase ? step : -step);
    if (newW < 200) newW = 200;
    if (newH < 200) newH = 200;
    
    setState(() {
      currentWidth = newW;
      currentHeight = newH;
    });
    await FlutterOverlayWindow.resizeOverlay(currentWidth.toInt(), currentHeight.toInt(), true);
  }

  // --- Input Handling ---


  @override
  Widget build(BuildContext context) {
    return OverlayContent(
      isMinimized: isMinimized,
      onMinimize: _minimizeToTab,
      onExpand: _expandFromTab,
      onClose: () async => await FlutterOverlayWindow.closeOverlay(),
      onResize: _changeSize,
      onAction: (action) {
        if (action == 'youtube') _launchYouTube();
        if (action == 'gallery') _openGallery();
      },
    );
  }

  // Helper removed as it is now in OverlayContent
}
