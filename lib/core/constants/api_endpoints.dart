class ApiEndpoints {
  static const String baseUrl = 'https://where-am-i-silk.vercel.app';

  // Auth & Profile
  static const String register = '/api/auth/register';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String resendOtp = '/api/auth/resend-otp';
  static const String login = '/api/auth/login';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';
  static const String me = '/api/auth/me';
  static const String changePassword = '/api/auth/change-password';
  static const String logout = '/api/auth/logout';

  // Checking
  static const String checking = '/api/checking';

  // System
  static const String health = '/api/health';
  static const String testDb = '/api/test-db';
  static const String imageProxy = '/api/images';
}
