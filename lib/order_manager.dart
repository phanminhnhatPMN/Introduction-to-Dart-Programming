import 'dart:convert';
import 'dart:io';
import 'order.dart';

class OrderManager {
  static const String defaultJsonString =
      '[{"Item": "A1000","ItemName": "Iphone 15","Price": 1200,"Currency": "USD","Quantity":1},'
      '{"Item": "A1001","ItemName": "Iphone 16","Price": 1500,"Currency": "USD","Quantity":1}]';

  final String filePath;
  List<Order> orders = [];

  OrderManager({this.filePath = 'order.json'});

  List<Order> parseOrdersFromString(String jsonString) {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! List) {
        throw const FormatException('Orders must be a JSON array.');
      }
      final usedIds = <int>{};
      var nextId = 1;

      return decoded.map((value) {
        if (value is! Map) {
          throw const FormatException('Each order must be a JSON object.');
        }
        final map = Map<String, dynamic>.from(value);
        final order = Order.fromJson(map);
        var id = order.id;
        if (id == null || id <= 0 || usedIds.contains(id)) {
          while (usedIds.contains(nextId)) {
            nextId++;
          }
          id = nextId;
        }
        usedIds.add(id);
        nextId = id >= nextId ? id + 1 : nextId;
        order.id = id;
        return order;
      }).toList();
    } on FormatException {
      rethrow;
    }
  }

  Future<void> init() async {
    final file = File(filePath);
    if (!await file.exists()) {
      orders = parseOrdersFromString(defaultJsonString);
      await saveToFile();
    } else {
      try {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          orders = parseOrdersFromString(content);
        } else {
          orders = parseOrdersFromString(defaultJsonString);
          await saveToFile();
        }
      } catch (e) {
        orders = parseOrdersFromString(defaultJsonString);
        await saveToFile();
      }
    }
  }

  Future<Order> insertOrder({
    required String item,
    required String itemName,
    required double price,
    required String currency,
    required int quantity,
    int? id,
  }) async {
    final newOrder = Order(
      id: id ?? _nextId(),
      item: item,
      itemName: itemName,
      price: price,
      currency: currency.isEmpty ? 'USD' : currency,
      quantity: quantity <= 0 ? 1 : quantity,
    );

    orders.add(newOrder);
    await saveToFile();
    return newOrder;
  }

  List<Order> searchByItemName(String query) {
    if (query.trim().isEmpty) {
      return List.unmodifiable(orders);
    }
    final lowerQuery = query.trim().toLowerCase();
    return orders
        .where((order) => order.itemName.toLowerCase().contains(lowerQuery))
        .toList();
  }

  Future<bool> deleteOrder(String itemCode) async {
    final index = orders.indexWhere(
      (order) => order.item.toLowerCase() == itemCode.toLowerCase(),
    );
    return deleteOrderByIndex(index);
  }

  Future<bool> deleteOrderByIndex(int index) async {
    if (index >= 0 && index < orders.length) {
      orders.removeAt(index);
      await saveToFile();
      return true;
    }
    return false;
  }

  Future<void> saveToFile() async {
    final file = File(filePath);
    final jsonList = orders.map((o) => o.toJson()).toList();
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(jsonList));
  }

  int _nextId() {
    final highestId = orders.fold<int>(
      0,
      (highest, order) =>
          order.id != null && order.id! > highest ? order.id! : highest,
    );
    return highestId + 1;
  }

  String toJsonString() {
    return jsonEncode(orders.map((o) => o.toJson()).toList());
  }

  void printOrders([List<Order>? listToPrint]) {
    final list = listToPrint ?? orders;
    print(
        '--------------------------------------------------------------------------------------');
    print(String.fromEnvironment('header',
        defaultValue: 'Id\tItem\tItem Name\t\tQuantity\tPrice\tCurrency'));
    print(
        '--------------------------------------------------------------------------------------');
    for (final o in list) {
      print(
          '${o.id ?? 1}\t${o.item}\t${o.itemName.padRight(16)}\t${o.quantity}\t\t${o.formattedPrice}\t${o.currency}');
    }
    print(
        '--------------------------------------------------------------------------------------');
    print('Total items: ${list.length}');
  }
}
