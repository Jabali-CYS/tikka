enum AppEnvironment { development, production }

class AppConfig {
  // Toggle this constant to transition of the modes
  static const AppEnvironment environment = AppEnvironment.production;

  static bool get isProduction => environment == AppEnvironment.production;
  static bool get isDevelopment => environment == AppEnvironment.development;

  /// Debug logging allowed only in Development
  static bool get enableDebugLogging => isDevelopment;

  /// OTP bypass with code "000000" allowed only in Development
  static bool get allowOtpBypass => isDevelopment;

  /// Hardcoded test phone verification details (for Development sandbox only)
  static const String sandboxOtp = "000000";
}
