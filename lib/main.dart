import 'package:flutter/material.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B5B)),
        useMaterial3: true,
      ),
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
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_rounded,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Fondea',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
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
