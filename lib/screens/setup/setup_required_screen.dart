import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sahayak/services/firebase_bootstrap.dart';
import 'package:sahayak/theme.dart';

class SetupRequiredScreen extends ConsumerWidget {
  const SetupRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(firebaseBootstrapProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Setup required')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Text(
              'Firebase is not configured for this build.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'To enable authentication, SOS, and notifications, add Firebase config files and re-run.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.surfaceLight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                bootstrap.error?.toString() ?? 'Unknown initialization error',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Expected files:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '- android/app/google-services.json\n'
              '- ios/Runner/GoogleService-Info.plist',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

