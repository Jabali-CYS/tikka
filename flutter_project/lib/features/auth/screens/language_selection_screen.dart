import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/locale_service.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCode = ref.watch(localeProvider);
    final localeSvc = ref.read(localeProvider.notifier);

    return Scaffold(
      backgroundColor: ArtisanalColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Center(
                child: Icon(
                  Icons.translate_rounded,
                  size: 72,
                  color: ArtisanalColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Choose Your Language",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: ArtisanalColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "اختر اللغة لبدء تصفح قائمة الطهي تندوري الشهية",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ArtisanalColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              
              // English Card Selection
              _LanguageCard(
                title: "English",
                subtitle: "Tandoori Grill Menu & Orders",
                isSelected: activeCode == LanguageCode.en,
                onTap: () => localeSvc.setLanguage(LanguageCode.en),
              ),
              const SizedBox(height: 16),
              
              // Arabic Card Selection
              _LanguageCard(
                title: "العربية",
                subtitle: "قائمة المشاوي والطلب المباشر",
                isSelected: activeCode == LanguageCode.ar,
                onTap: () => localeSvc.setLanguage(LanguageCode.ar),
              ),
              
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  context.go('/login');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      activeCode == LanguageCode.ar ? "استمر" : "Continue",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      activeCode == LanguageCode.ar 
                          ? Icons.arrow_back_rounded 
                          : Icons.arrow_forward_rounded,
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? ArtisanalColors.primaryContainer 
              : ArtisanalColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? ArtisanalColors.secondary 
                : ArtisanalColors.outlineVariant,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? ArtisanalColors.secondary.withOpacity(0.1) 
                  : Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? ArtisanalColors.secondary 
                    : ArtisanalColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: isSelected ? Colors.white : Colors.transparent,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : ArtisanalColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected 
                          ? ArtisanalColors.onPrimaryFixedVariant 
                          : ArtisanalColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
