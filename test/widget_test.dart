import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:follow_me/screens/auth/login_screen.dart';

void main() {
  testWidgets('Login screen renders and can open signup page', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump();

    expect(find.text('เข้าสู่ระบบ'), findsWidgets);
    expect(find.text('followme'), findsOneWidget);
    expect(find.text('สมัครสมาชิก'), findsOneWidget);

    await tester.tap(find.text('สมัครสมาชิก'));
    await tester.pumpAndSettle();
    expect(find.text('ชื่อ-นามสกุล'), findsOneWidget);
    expect(find.text('สมัครสมาชิก'), findsWidgets);
  });
}
