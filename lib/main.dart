import 'dart:isolate';
import 'dart:ui';
import 'dart:io' as io;
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:overlay_app/widgets/overlay_layout.dart';
import 'package:overlay_app/widgets/windows_overlay_wrapper.dart';
import 'package:overlay_app/screens/windows_dashboard.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:window_manager/window_manager.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Windows Overlay Entry Point ---
  /*
  if (args.isNotEmpty && args.first == 'multi_window') {
    // The library desktop_multi_window might be used inside WindowsOverlayWrapper
    runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WindowsOverlayWrapper(),
    ));
    return;
  }

  // --- Main App Entry Point ---
  if (io.Platform.isWindows) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(800, 600),
      center: true,
      title: 'Drone Control Hub',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  */

  runApp(const MyApp());
}

// Entry point for the overlay (Android)
@pragma("vm:entry-point")
void overlayMain() {
  debugPrint("🔨 OVERLAY ENTRY POINT STARTED");
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("🔨 OVERLAY BINDING INITIALIZED");
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayLayout(),
    ),
  );
  debugPrint("🔨 OVERLAY RUNAPP CALLED");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Drone Overlay Controller',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AndroidDashboard(), // Force Android Dashboard for now
    );
  }
}

// [WindowsDashboard class moved to screens/windows_dashboard.dart]

// --- Android Dashboard (Existing Logic) ---
class AndroidDashboard extends StatefulWidget {
  const AndroidDashboard({super.key});

  @override
  State<AndroidDashboard> createState() => _AndroidDashboardState();
}

class _AndroidDashboardState extends State<AndroidDashboard> {
  // ... (Existing Android Logic)
  // Re-pasting the exact logic from previous HomePage to ensure no regression
  // But for brevity in this tool call, I will assume Replace Content replaces the whole file 
  // or I need to be careful. I am replacing the WHOLE FILE CONTENT from Main down?
  // No, I am replacing lines 1-280. So I need to provide the FULL implementation of AndroidDashboard too.
  
  String _latestMessageFromOverlay = "No data yet";
  String _receivedUdpData = "No UDP received";
  String _deviceIp = "Fetching IP...";
  io.RawDatagramSocket? _udpSocket;
  Timer? _telemetryTimer;

  @override
  void initState() {
    super.initState();
    _getDeviceIp();
    _setupUdpListener();
    
    // Listen for messages from the overlay
    FlutterOverlayWindow.overlayListener.listen((event) {
      debugPrint("MAIN: Received Overlay Event: $event");
      if (event is Map) {
        // Handle Map actions
        final action = event['action'];
        
        if (action == 'open_youtube') {
          debugPrint("MAIN: Launching YouTube...");
          // _launchUrl('https://www.youtube.com/watch?v=kYJyrbGYoN4');
        }
         else if (action == 'open_gallery') {
          debugPrint("MAIN: Opening Gallery...");
          _openGallery();
        }
      } else if (event == 'get_screen_size') {
           final screenSize = MediaQuery.of(context).size;
           FlutterOverlayWindow.shareData({
             'screen_width': screenSize.width,
             'screen_height': screenSize.height,
           });
      }
    });
  }

  // Future<void> _launchUrl(String url) async { ... } // Defined below
  
  Future<void> _openGallery() async {
    const intent = AndroidIntent(
      action: 'android.intent.action.VIEW',
      type: 'image/*',
    );
    await intent.launch();
  }

  Future<void> _getDeviceIp() async {
    try {
      List<io.NetworkInterface> interfaces = await io.NetworkInterface.list(
        type: io.InternetAddressType.IPv4,
      );
      for (var interface in interfaces) {
        // Usually wlan0 or similar on Android
        for (var addr in interface.addresses) {
           if (!addr.isLoopback) {
             setState(() => _deviceIp = addr.address);
             return; 
           }
        }
      }
      setState(() => _deviceIp = "No Network Found");
    } catch (e) {
      setState(() => _deviceIp = "Error: $e");
    }
  }

  Future<void> _setupUdpListener() async {
    try {
      debugPrint("Binding UDP port 12346...");
      _udpSocket = await io.RawDatagramSocket.bind(io.InternetAddress.anyIPv4, 12346);
      _udpSocket!.listen((event) {
        if (event == io.RawSocketEvent.read) {
          io.Datagram? datagram = _udpSocket!.receive();
          if (datagram != null) {
            String received = utf8.decode(datagram.data).trim();
            debugPrint("UDP Received: $received");
            
            setState(() => _receivedUdpData = received);
            // Forward to Overlay (optional, but keeps sync)
            FlutterOverlayWindow.shareData({'udp_received': received});
          }
        }
      });
      debugPrint("UDP bound successfully.");
      setState(() {}); // refresh UI if needed
    } catch (e) {
      debugPrint("UDP bind error: $e");
    }
  }

  @override
  void dispose() {
    _udpSocket?.close();
    _telemetryTimer?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    debugPrint("Requesting permissions...");
    bool status = await FlutterOverlayWindow.isPermissionGranted();
    debugPrint("Permission status: $status");
    if (!status) {
      bool? granted = await FlutterOverlayWindow.requestPermission();
      debugPrint("Permission granted result: $granted");
      if (granted != true) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Permission denied! Overlay won't work.")),
           );
         }
      }
    }
  }

  Future<void> _showOverlay() async {
    debugPrint("Attempting to show overlay...");
    if (await FlutterOverlayWindow.isActive()) {
        debugPrint("Overlay is already active! Closing to restart...");
        await FlutterOverlayWindow.closeOverlay();
        // Give it a moment to close
        await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // We start with a default size, but the overlay will manage resizing itself
    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: "Drone Control",
      overlayContent: "Control Panel",
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.auto,
      height: 600,
      width: 500,
      startPosition: const OverlayPosition(0, 0),
    );
    debugPrint("Show overlay command sent.");
  }

  Future<void> _closeOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drone Control Hub'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.amberAccent.withOpacity(0.2),
                child: Text(
                   "Device IP: $_deviceIp\nPort: 14550",
                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const SizedBox(height: 20),
              
              const Text(
                'Overlay Status:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                "Last Msg: $_latestMessageFromOverlay",
                textAlign: TextAlign.center,
              ),
               Text(
                "UDP Data: $_receivedUdpData",
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _requestPermissions,
                child: const Text("1. Request Permissions"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _showOverlay,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text("2. Start/Reset Overlay"),
              ),
               const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _closeOverlay,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: const Text("3. Stop Overlay"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
