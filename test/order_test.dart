import 'dart:convert';
import 'dart:io';

import 'package:dart_exam_set01/order.dart';
import 'package:dart_exam_set01/order_manager.dart';
import 'package:test/test.dart';

void main() {
  group('Order', () {
    test('maps JSON values and formats whole-number prices', () {
      final order = Order.fromJson({
        'Id': '7',
        'Item': ' A1000 ',
        'ItemName': ' Iphone 15 ',
        'Price': '1200',
        'Currency': 'USD',
        'Quantity': '2',
      });

      expect(order.id, 7);
      expect(order.item, 'A1000');
      expect(order.itemName, 'Iphone 15');
      expect(order.price, 1200);
      expect(order.quantity, 2);
      expect(order.formattedPrice, '1.200');
      expect(order.toJson()['Price'], 1200);
    });
  });

  group('OrderManager', () {
    late Directory temporaryDirectory;
    late OrderManager manager;

    setUp(() async {
      temporaryDirectory =
          await Directory.systemTemp.createTemp('dart_order_test_');
      manager = OrderManager(
        filePath:
            '${temporaryDirectory.path}${Platform.pathSeparator}orders.json',
      );
    });

    tearDown(() async {
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    });

    test('parses JSON and assigns sequential IDs when they are absent', () {
      final orders =
          manager.parseOrdersFromString(OrderManager.defaultJsonString);

      expect(orders, hasLength(2));
      expect(orders.map((order) => order.id), [1, 2]);
      expect(orders.map((order) => order.item), ['A1000', 'A1001']);
    });

    test('repairs missing or duplicate IDs while loading persisted data', () {
      final orders = manager.parseOrdersFromString('[\n'
          '  {"Id": 1, "Item": "A1000", "ItemName": "Phone 1"},\n'
          '  {"Id": 1, "Item": "A1001", "ItemName": "Phone 2"},\n'
          '  {"Item": "A1002", "ItemName": "Phone 3"}\n'
          ']');

      expect(orders.map((order) => order.id), [1, 2, 3]);
    });

    test('initializes missing storage with default orders', () async {
      await manager.init();

      expect(manager.orders, hasLength(2));
      final saved = jsonDecode(await File(manager.filePath).readAsString())
          as List<dynamic>;
      expect(saved, hasLength(2));
      expect(saved[0]['Id'], 1);
      expect(saved[1]['Id'], 2);
    });

    test('restores default orders when persisted JSON is invalid', () async {
      await File(manager.filePath).writeAsString('{not valid JSON');

      await manager.init();

      expect(manager.orders, hasLength(2));
      expect(
          jsonDecode(await File(manager.filePath).readAsString()), isA<List>());
    });

    test('inserts an order with a unique ID and persists it', () async {
      await manager.init();
      final inserted = await manager.insertOrder(
        item: 'A1002',
        itemName: 'Iphone 16 Pro',
        price: 1350,
        currency: 'USD',
        quantity: 2,
      );

      expect(inserted.id, 3);
      final saved = jsonDecode(await File(manager.filePath).readAsString())
          as List<dynamic>;
      expect(saved.last, containsPair('Item', 'A1002'));
      expect(saved.last, containsPair('Id', 3));
    });

    test('searches case-insensitively and deletes one matching item', () async {
      await manager.init();
      await manager.insertOrder(
        item: 'A1000',
        itemName: 'Iphone 15 Pro',
        price: 1300,
        currency: 'USD',
        quantity: 1,
      );

      expect(manager.searchByItemName('iphone 15'), hasLength(2));
      expect(await manager.deleteOrder('a1000'), isTrue);
      expect(
          manager.orders.where((order) => order.item == 'A1000'), hasLength(1));
    });
  });
}
