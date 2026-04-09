import 'dart:io';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AppTag'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '생성 이력',
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 24),
            const Text(
              'AppTag',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '앱에 QR/NFC 태그 달기',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (Platform.isAndroid) {
                    Navigator.pushNamed(context, '/app-picker');
                  } else {
                    Navigator.pushNamed(context, '/ios-input');
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('시작하기'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
