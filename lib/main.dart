import 'package:flutter/material.dart';
import 'package:fondea/design_system/fondea_colors.dart';
import 'package:fondea/design_system/fondea_spacing.dart';
import 'package:fondea/design_system/fondea_theme.dart';

void main() {
  runApp(const FondeaApp());
}

class FondeaApp extends StatelessWidget {
  const FondeaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fondea',
      debugShowCheckedModeBanner: false,
      theme: FondeaTheme.light,
      home: const _WelcomePage(),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(FondeaSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_rounded,
                  size: 56,
                  color: FondeaColors.primary,
                ),
                const SizedBox(height: FondeaSpacing.md),
                Text(
                  'Fondea',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: FondeaSpacing.xs),
                Text(
                  'La base de tu próximo proyecto empieza aquí.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
