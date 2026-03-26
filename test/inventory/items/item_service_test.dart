import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inoventory_ui/inventory/items/item_service.dart';
import 'package:inoventory_ui/inventory/items/models/item.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late ItemServiceImpl itemService;
  late MockDio mockDio;

  setUpAll(() {
    registerFallbackValue(Item(0, 0, '', ''));
    registerFallbackValue(RequestOptions(path: ''));
  });

  setUp(() {
    mockDio = MockDio();
    itemService = ItemServiceImpl(mockDio);
  });

  group('ItemServiceImpl Tests', () {
    test('add() should successfully add an item', () async {
      final itemToAdd = Item(0, 1, '123456', 'Test Product', expirationDate: '2024-12-31');
      
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: HttpStatus.created,
            data: {
              'id': 1,
              'listId': 1,
              'productEan': '123456',
              'displayName': 'Test Product',
              'expirationDate': '2024-12-31'
            },
          ));

      final addedItem = await itemService.add(itemToAdd);

      expect(addedItem.id, 1);
      expect(addedItem.productEan, '123456');
    });

    test('all() should parse items into ItemWrappers', () async {
      when(() => mockDio.get(any())).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: HttpStatus.ok,
            data: {
              '123456': [
                {
                  'id': 1,
                  'listId': 1,
                  'productEan': '123456',
                  'displayName': 'Test Product 1',
                  'expirationDate': '2024-12-31'
                },
                {
                  'id': 2,
                  'listId': 1,
                  'productEan': '123456',
                  'displayName': 'Test Product 1',
                  'expirationDate': '2025-01-01'
                }
              ]
            },
          ));

      final items = await itemService.all(1);

      expect(items.length, 1);
      expect(items.first.productEan, '123456');
      expect(items.first.items.length, 2);
    });

    test('delete() correctly updates state', () async {
      when(() => mockDio.delete(any())).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: HttpStatus.ok,
            data: {
              'id': 1,
              'listId': 1,
              'productEan': '123456',
              'displayName': 'Test Product',
            },
          ));

      await itemService.delete(1, 1);

      expect(itemService.lastDeletedItem, isNotNull);
      expect(itemService.lastDeletedItem!.id, 1);
    });
  });
}
