import 'package:flutter_test/flutter_test.dart';
import 'package:tnc_cafe_mobile_app/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const NativeCloudCafeApp());
    await tester.pump();
  });
}
