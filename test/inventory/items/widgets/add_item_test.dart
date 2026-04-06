import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inoventory_ui/expiry_scan/controllers/expiry_scan_controller.dart';
import 'package:inoventory_ui/expiry_scan/models/expiry_scan_candidate.dart';
import 'package:inoventory_ui/expiry_scan/models/expiry_scan_detection.dart';
import 'package:inoventory_ui/inventory/items/models/item.dart';
import 'package:inoventory_ui/inventory/items/widgets/add_item.dart';
import 'package:inoventory_ui/inventory/lists/models/inventory_list.dart';
import 'package:inoventory_ui/products/product_model.dart';
import 'package:inoventory_ui/shared/widgets/expiry_date_input.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/test_wrapper.dart';

ExpiryScanDetection _testDetection(String isoDate, DateTime date,
    {String sourceText = '02.07.26', double score = 93}) {
  return ExpiryScanDetection(
    candidates: <ExpiryScanCandidate>[
      ExpiryScanCandidate(
        sourceText: sourceText,
        isoDate: isoDate,
        date: date,
        score: score,
        boundingBox: Rect.zero,
      ),
    ],
  );
}

void main() {
  late MockItemService mockItemService;
  late Product dummyProduct;
  late InventoryList dummyList;

  setUp(() {
    mockItemService = MockItemService();
    setupMockGetIt(mockItemService: mockItemService);

    dummyList = InventoryList(1, 'Test List');
    dummyProduct = Product('123', 'Milk', ean: '123', brands: 'Brand X');

    registerFallbackValue(Item(0, 1, '123', 'Milk'));
  });

  testWidgets('AddItemView increments amount and fires expected add calls',
      (tester) async {
    when(() => mockItemService.add(any()))
        .thenAnswer((_) async => Item(1, 1, '123', 'Milk'));

    await tester.pumpWidget(TestWrapper(
      child: AddItemView(
        dummyProduct,
        dummyList,
        expiryScanController: ExpiryScanController(),
      ),
    ));

    await tester.pumpAndSettle();

    // Initially 1 amount
    expect(find.byType(ExpiryDateEntry), findsOneWidget);

    // Tap increase amount
    final increaseBtn = find.byIcon(Icons.add);
    await tester.ensureVisible(increaseBtn);
    await tester.tap(increaseBtn);
    await tester.pumpAndSettle();

    // Now 2 amounts (2 expiry entries)
    expect(find.byType(ExpiryDateEntry), findsNWidgets(2));

    // Tap the FAB to save
    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();

    // add() should be called twice since amount is 2
    verify(() => mockItemService.add(any())).called(2);
  });

  testWidgets('AddItemView requires expiration date for opened items',
      (tester) async {
    final openList = InventoryList(2, 'Open', type: 'OPEN');

    await tester.pumpWidget(TestWrapper(
      child: AddItemView(
        dummyProduct,
        openList,
        expiryScanController: ExpiryScanController(),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();

    verifyNever(() => mockItemService.add(any()));
    expect(find.text('Please add an expiration date before opening an item.'),
        findsOneWidget);
  });

  testWidgets('AddItemView requires confirming scanned expiry before save',
      (tester) async {
    when(() => mockItemService.add(any()))
        .thenAnswer((_) async => Item(1, 1, '123', 'Milk'));
    final ExpiryScanController controller = ExpiryScanController();

    await tester.pumpWidget(TestWrapper(
      child: AddItemView(
        dummyProduct,
        dummyList,
        expiryScanController: controller,
      ),
    ));
    await tester.pumpAndSettle();

    controller.startScanning(targetRowIndex: 0);
    controller.publishDetection(
      _testDetection('2026-07-02', DateTime(2026, 7, 2)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Confirm expiry date'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => mockItemService.add(any()));

    controller.startScanning(targetRowIndex: 0);
    controller.publishDetection(
      _testDetection('2026-07-02', DateTime(2026, 7, 2)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('2026-07-02').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();

    final List<dynamic> secondSaveCalls =
        verify(() => mockItemService.add(captureAny())).captured;
    expect(secondSaveCalls, hasLength(1));
    expect(
      (secondSaveCalls.single as Item).expirationDate,
      '2026-07-02',
    );
  });

  testWidgets('AddItemView shows popup confirmation for scanned expiry',
      (tester) async {
    final ExpiryScanController controller = ExpiryScanController();

    await tester.pumpWidget(TestWrapper(
      child: AddItemView(
        dummyProduct,
        dummyList,
        expiryScanController: controller,
      ),
    ));
    await tester.pumpAndSettle();

    controller.startScanning(targetRowIndex: 0);
    controller.publishDetection(
      _testDetection('2026-07-02', DateTime(2026, 7, 2)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Confirm expiry date'), findsOneWidget);
    expect(find.text('Choose the scanned date before applying it.'),
        findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
  });

  testWidgets('AddItemView applies confirmed first scanned expiry to all rows',
      (tester) async {
    when(() => mockItemService.add(any()))
        .thenAnswer((_) async => Item(1, 1, '123', 'Milk'));
    final ExpiryScanController controller = ExpiryScanController();

    await tester.pumpWidget(TestWrapper(
      child: AddItemView(
        dummyProduct,
        dummyList,
        expiryScanController: controller,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    controller.startScanning(targetRowIndex: 0);
    controller.publishDetection(
      _testDetection(
        '2027-03-21',
        DateTime(2027, 3, 21),
        sourceText: '21032027',
        score: 91,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();

    final List<dynamic> savedItems =
        verify(() => mockItemService.add(captureAny())).captured;
    expect(savedItems, hasLength(2));
    expect(
      savedItems
          .map((dynamic item) => (item as Item).expirationDate)
          .toList(growable: false),
      everyElement('2027-03-21'),
    );
  });

  testWidgets('AddItemView retry capture restarts scanning for pending row',
      (tester) async {
    final ExpiryScanController controller = ExpiryScanController();

    await tester.pumpWidget(TestWrapper(
      child: AddItemView(
        dummyProduct,
        dummyList,
        expiryScanController: controller,
      ),
    ));
    await tester.pumpAndSettle();

    controller.startScanning(targetRowIndex: 0);
    controller.publishDetection(
      _testDetection('2026-07-02', DateTime(2026, 7, 2)),
    );
    await tester.pumpAndSettle();

    expect(controller.awaitingConfirmation, isTrue);
    expect(controller.isScanning, isFalse);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(controller.isScanning, isTrue);
    expect(controller.targetRowIndex, 0);
  });

  testWidgets('AddItemView can exit expiry scanning mode back to barcode',
      (tester) async {
    final ExpiryScanController controller = ExpiryScanController();

    await tester.pumpWidget(TestWrapper(
      child: AddItemView(
        dummyProduct,
        dummyList,
        expiryScanController: controller,
      ),
    ));
    await tester.pumpAndSettle();

    controller.startScanning(targetRowIndex: 0);
    await tester.pumpAndSettle();

    expect(find.text('Back to Barcode'), findsOneWidget);
    expect(controller.isActive, isTrue);

    await tester.tap(find.text('Back to Barcode'));
    await tester.pumpAndSettle();

    expect(controller.isActive, isFalse);
    expect(controller.targetRowIndex, isNull);
  });
}
