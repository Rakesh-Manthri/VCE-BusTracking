import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MapScreen(),
  ));
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    // Initialize the webview controller
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // REQUIRED for Leaflet
      ..setBackgroundColor(const Color(0x00000000))
    // This loads the file you registered in pubspec.yaml
      ..loadFlutterAsset('assets/map.html');
  }

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Navigation Tracker"),
        backgroundColor: Colors.blueAccent,
      ),
      body: WebViewWidget(controller: controller),

      // Adding the interactive button here
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // This is the "Bridge": Sending data from Dart to JS
          controller.runJavaScript("centerMap(17.3850, 78.4867);");
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}