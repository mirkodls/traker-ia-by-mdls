// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';

import 'package:traker_ia/domain/info_app.dart';
import 'package:traker_ia/ui/app.dart';

void main() {
  testWidgets('l\'app parte e mostra il nome', (WidgetTester tester) async {
    await tester.pumpWidget(const TrakerApp());
    expect(find.text(nomeApp), findsOneWidget);
  });
}
