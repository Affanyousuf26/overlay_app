import 'package:flutter/material.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:convert';

class WindowsDashboard extends StatefulWidget {
  const WindowsDashboard({super.key});

  @override
  State<WindowsDashboard> createState() => _WindowsDashboardState();
}

class _WindowsDashboardState extends State<WindowsDashboard> with WindowListener {
  int? overlayWindowId;

  Future<void> _startOverlay() async {
    if (overlayWindowId != null) return;
    
    // TEMPORARY: Commented out for Android compatibility test
    // final window = await DesktopMultiWindow.createWindow(jsonEncode({
    //   'args': 'overlay_window'
    // }));
    // overlayWindowId = window.windowId;
    
    debugPrint("Windows Overlay creation temporarily disabled for Android build check");
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Windows Overlay Disabled during Android Debug")));
    
    setState(() {});
  }

  Future<void> _closeOverlay() async {
    // if (overlayWindowId != null) {
      // await DesktopMultiWindow.closeWindow(overlayWindowId!);
      // setState(() => overlayWindowId = null);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Drone Operations (Windows)"), 
        backgroundColor: Colors.blueGrey,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.desktop_windows, size: 64, color: Colors.blueGrey),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _startOverlay, 
              icon: const Icon(Icons.layers),
              label: const Text("Launch Overlay"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            if (overlayWindowId != null) ...[
              Text("Overlay Active: ID $overlayWindowId", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _closeOverlay,
                child: const Text("Close Overlay"),
              )
            ] else
              const Text("Overlay Inactive", style: TextStyle(color: Colors.grey))
          ],
        ),
      ),
    );
  }
}
