import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/shell/home_shell.dart';
import 'state/posture_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  runApp(const ProviderScope(child: PostureApp()));
}

class PostureApp extends StatelessWidget {
  const PostureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Posture Trainer',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const RootPage(),
    );
  }
}

class RootPage extends ConsumerWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paired = ref.watch(postureControllerProvider.select((s) => s.paired));
    return paired ? const HomeShell() : const OnboardingPage();
  }
}
