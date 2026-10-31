import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_constants.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F7),
      appBar: AppBar(
        title: const Text('Page Not Found'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Color(0xFFFF4B5C),
              ),
              const SizedBox(height: 16),
              const Text(
                '404 - Page Not Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B1A1C),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The requested page does not exist or has been moved.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF7A5C60)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutePaths.dashboard),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4B5C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Return Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
