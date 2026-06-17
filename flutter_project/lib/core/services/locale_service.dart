import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LanguageCode { en, ar }

class LocaleService extends StateNotifier<LanguageCode> {
  LocaleService() : super(LanguageCode.en);

  void toggleLanguage() {
    state = state == LanguageCode.en ? LanguageCode.ar : LanguageCode.en;
  }

  void setLanguage(LanguageCode lang) {
    state = lang;
  }

  bool get isArabic => state == LanguageCode.ar;

  String translate(String en, String ar) {
    return isArabic ? ar : en;
  }
}

final localeProvider = StateNotifierProvider<LocaleService, LanguageCode>((ref) {
  return LocaleService();
});
