import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inoventory_ui/inventory/lists/inventory_list_overview_route.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  late MockInventoryListService mockListService;

  setUp(() {
    mockListService = MockInventoryListService();
    setupMockGetIt(mockInventoryListService: mockListService);
  });

  testWidgets('InventoryListRoute renders lists properly', (tester) async {
    when(() => mockListService.all()).thenAnswer((_) async => [
          InventoryList(1, 'Kitchen'),
          InventoryList(2, 'Open', type: 'OPEN'),
        ]);

    await tester.pumpWidget(TestWrapper(
      child: InventoryListRoute(logout: () async {}),
    ));

    // Initially loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Pump to resolve future
    await tester.pumpAndSettle();

    expect(find.text('Kitchen'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Opened items'), findsOneWidget);
    expect(find.byIcon(Icons.lock_open), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
