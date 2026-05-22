import 'package:crowdsync/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CrowdSyncApp is constructible', (tester) async {
    expect(const CrowdSyncApp(), isA<CrowdSyncApp>());
  });
}
