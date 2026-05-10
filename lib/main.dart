import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web/web.dart' as web;
import 'pages/map_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  if (apiKey.isNotEmpty && apiKey != 'YOUR_API_KEY_HERE') {
    await _injectMapsScript(apiKey);
  }

  runApp(const FoodFinderApp());
}

Future<void> _injectMapsScript(String apiKey) {
  final completer = Completer<void>();
  final script =
      web.document.createElement('script') as web.HTMLScriptElement;
  script.src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey';
  script.async = true;
  script.onload = (web.Event _) {
    completer.complete();
  }.toJS;
  script.onerror = (web.Event _) {
    completer.complete();
  }.toJS;
  web.document.head!.append(script);
  return completer.future;
}

class FoodFinderApp extends StatelessWidget {
  const FoodFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food & Drink Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A73E8),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MapPage(),
    );
  }
}
