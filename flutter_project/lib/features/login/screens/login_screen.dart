import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/locale_service.dart';
import '../../../core/constants/config.dart';
import '../repositories/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isOtpSent = false;
  bool _isLoading = false;
  String _errorMessage = "";

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 9) {
      setState(() {
        _errorMessage = ref.read(localeProvider.notifier).translate(
          "Please enter a valid Jordanian phone number.",
          "يرجى إدخال رقم هاتف أردني صحيح.",
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final success = await ref.read(authStateProvider.notifier).sendOtpCode(phone);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _isOtpSent = true;
        } else {
          _errorMessage = ref.read(localeProvider.notifier).translate(
            "Failed to send SMS activation code. Please try again.",
            "فشل إرسال كود التحقق. يرجى المحاولة مرة أخرى.",
          );
        }
      });
    }
  }

  void _handleVerifyOtp() async {
    final phone = _phoneController.text.trim();
    final code = _otpController.text.trim();

    if (code.length < 4) {
      setState(() {
        _errorMessage = ref.read(localeProvider.notifier).translate(
          "Enter complete OTP code.",
          "يرجى إدخال كود تحقق مكتمل.",
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final success = await ref.read(authStateProvider.notifier).verifyOtpCode(phone, code);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          context.go('/home');
        } else {
          _errorMessage = ref.read(localeProvider.notifier).translate(
            "Invalid verification code. Use sandbox bypass code if testing.",
            "كود التحقق غير صحيح. يرجى استخدام الكود التجريبي عند الفحص.",
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeSvc = ref.watch(localeProvider.notifier);
    final isAr = localeSvc.isArabic;

    return Scaffold(
      backgroundColor: ArtisanalColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(localeProvider.notifier).toggleLanguage(),
            icon: const Icon(Icons.language, color: ArtisanalColors.primary),
            label: Text(
              isAr ? "English" : "العربية",
              style: const TextStyle(fontWeight: FontWeight.bold, color: ArtisanalColors.primary),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ArtisanalColors.primary.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_iphone_rounded,
                    size: 64,
                    color: ArtisanalColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                localeSvc.translate("Sign In", "تسجيل الدخول"),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ArtisanalColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localeSvc.translate(
                  "Enter Jordanian cellular details to claim reward points.",
                  "سجل بهاتفك الخلوي الأردني للبدء في تجميع نقاط الولاء والخصومات.",
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: ArtisanalColors.onSurfaceVariant),
              ),
              const SizedBox(height: 32),

              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: ArtisanalColors.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: ArtisanalColors.onErrorContainer),
                    textAlign: TextAlign.center,
                  ),
                ),

              if (!_isOtpSent) ...[
                // Phone input field
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 14,
                  decoration: InputDecoration(
                    labelText: localeSvc.translate("Mobile Phone Number", "رقم الهاتف الخلوي"),
                    hintText: "07XXXXXXXX",
                    prefixIcon: const Icon(Icons.add_call, color: ArtisanalColors.outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: ArtisanalColors.secondary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendOtp,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          localeSvc.translate("Send SMS Activation Code", "إرسال كود التفعيل"),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ] else ...[
                // OTP code input field
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: localeSvc.translate("SMS Verification Code", "رمز التحقق الثنائي"),
                    hintText: "******",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: ArtisanalColors.secondary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerifyOtp,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          localeSvc.translate("Verify and Continue", "تأكيد ومتابعة"),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading ? null : () => setState(() => _isOtpSent = false),
                  child: Text(
                    localeSvc.translate("Change Phone Number", "تغيير رقم الهاتف"),
                    style: const TextStyle(color: ArtisanalColors.secondary),
                  ),
                )
              ],

              if (AppConfig.allowOtpBypass) ...[
                const SizedBox(height: 48),
                // Sandbox bypass note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ArtisanalColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ArtisanalColors.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: ArtisanalColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            localeSvc.translate("Sandbox Testing Bypass", "نمط الفحص وتجاوز الأقفال"),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: ArtisanalColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localeSvc.translate(
                          "Demo bypass enabled for immediate verification. Enter any 10-digit number and code 000000 to authenticate instantly.",
                          "نمط التخطي مفعل لتجربة فورية مريحة. أدخل أي رقم خلوي وكود 000000 للدخول مباشرة.",
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: ArtisanalColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Optional admin bypass screen shortcut
              if (!AppConfig.isProduction)
                TextButton(
                  onPressed: () {
                    context.go('/admin');
                  },
                  child: Text(
                    localeSvc.translate("Go to Restaurant Admin Console (Web/Admin View)", "الانتقال إلى لوحة إدارة المطعم"),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: ArtisanalColors.secondary),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
