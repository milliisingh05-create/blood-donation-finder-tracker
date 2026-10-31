import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/router/app_router.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/app_error_widget.dart';
import 'features/notifications/data/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (FlutterErrorDetails details) => AppErrorWidget(details: details);
  runApp(
    const ProviderScope(
      child: BloodFinderApp(),
    ),
  );
}

class BloodFinderApp extends ConsumerStatefulWidget {
  const BloodFinderApp({super.key});

  @override
  ConsumerState<BloodFinderApp> createState() => _BloodFinderAppState();
}

class _BloodFinderAppState extends ConsumerState<BloodFinderApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushNotificationServiceProvider).initialize(
        onSelectNotification: (payload) {
          if (payload != null && payload.isNotEmpty) {
            final router = ref.read(appRouterProvider);
            if (payload.startsWith('/')) {
              router.push(payload);
            } else {
              router.push('/requests/$payload');
            }
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.lightTheme,
    );
  }
}
