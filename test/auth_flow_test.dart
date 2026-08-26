import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:follow_me/core/constants/api_endpoints.dart';
import 'package:follow_me/core/errors/api_exception.dart';
import 'package:follow_me/models/checkin_model.dart';
import 'package:follow_me/models/user_model.dart';
import 'package:follow_me/screens/auth/forgot_password_screen.dart';
import 'package:follow_me/screens/auth/login_screen.dart';
import 'package:follow_me/screens/auth/otp_screen.dart';
import 'package:follow_me/screens/auth/register_screen.dart';

void main() {
  group('Models & Errors Tests', () {
    test('UserModel parse and toJson', () {
      final json = {
        'id': 1,
        'email': 'test@example.com',
        'name': 'Somchai Jaidee',
        'role': 'user',
        'isVerified': true,
      };
      final user = UserModel.fromJson(json);
      expect(user.id, 1);
      expect(user.email, 'test@example.com');
      expect(user.name, 'Somchai Jaidee');
      expect(user.isVerified, true);
      expect(user.toJson()['email'], 'test@example.com');
    });

    test('CheckinModel parse and toJson', () {
      final json = {
        'id': 10,
        'userId': 1,
        'locationName': 'Central World',
        'latitude': 13.7466,
        'longitude': 100.5393,
        'createdAt': '2026-08-26T12:00:00.000Z',
      };
      final checkin = CheckinModel.fromJson(json);
      expect(checkin.id, 10);
      expect(checkin.locationName, 'Central World');
      expect(checkin.lat, 13.7466);
      expect(checkin.lng, 100.5393);
    });

    test('ApiException holds message, statusCode, and data', () {
      const error = ApiException(
        'Email already exists',
        statusCode: 409,
        data: {'error': 'Duplicate'},
      );
      expect(error.message, 'Email already exists');
      expect(error.statusCode, 409);
      expect(error.data?['error'], 'Duplicate');
      expect(error.toString(), 'Email already exists');
    });

    test('ApiEndpoints are properly configured', () {
      expect(ApiEndpoints.baseUrl, isNotEmpty);
      expect(ApiEndpoints.register, '/api/auth/register');
      expect(ApiEndpoints.verifyOtp, '/api/auth/verify-otp');
      expect(ApiEndpoints.login, '/api/auth/login');
      expect(ApiEndpoints.forgotPassword, '/api/auth/forgot-password');
      expect(ApiEndpoints.checking, '/api/checking');
    });
  });

  group('Auth Widgets Tests', () {
    testWidgets('RegisterScreen validates required fields and PDPA', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      await tester.pump();

      expect(find.text('สมัครสมาชิก'), findsWidgets);
      expect(find.text('ชื่อ-นามสกุล'), findsOneWidget);
      expect(find.text('อีเมล'), findsOneWidget);
      expect(find.text('รหัสผ่าน'), findsOneWidget);
      expect(find.text('ยืนยันรหัสผ่าน'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);

      // Tap register without filling form
      await tester.tap(find.widgetWithText(ElevatedButton, 'สมัครสมาชิก'));
      await tester.pump();

      expect(find.text('กรุณากรอกชื่อ-นามสกุล'), findsOneWidget);
      expect(find.text('กรุณากรอกอีเมล'), findsOneWidget);
      expect(find.text('กรุณากรอกรหัสผ่าน'), findsOneWidget);
    });

    testWidgets('OtpScreen renders with email and input', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OtpScreen(email: 'user@test.com', isFromRegister: true),
        ),
      );
      await tester.pump();

      expect(find.text('ยืนยันรหัส OTP'), findsWidgets);
      expect(find.textContaining('user@test.com'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('ยืนยัน OTP'), findsOneWidget);
    });

    testWidgets('ForgotPasswordScreen renders properly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));
      await tester.pump();

      expect(find.text('ลืมรหัสผ่าน'), findsWidgets);
      expect(find.text('ขอรหัส OTP'), findsOneWidget);
    });

    testWidgets('LoginScreen renders properly with all links', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pump();

      expect(find.text('followme'), findsOneWidget);
      expect(find.text('เข้าสู่ระบบ'), findsWidgets);
      expect(find.text('สมัครสมาชิก'), findsOneWidget);
      expect(find.text('ลืมรหัสผ่าน?'), findsOneWidget);
    });
  });
}
