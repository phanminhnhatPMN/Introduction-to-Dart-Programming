class Order {
  int? id;
  String item;
  String itemName;
  double price;
  String currency;
  int quantity;

  Order({
    this.id,
    required this.item,
    required this.itemName,
    required this.price,
    required this.currency,
    required this.quantity,
  });

  factory Order.fromJson(Map<String, dynamic> json, [int? id]) {
    double parsedPrice = 0.0;
    final rawPrice = json['Price'] ?? json['price'];
    if (rawPrice != null) {
      if (rawPrice is num) {
        parsedPrice = rawPrice.toDouble();
      } else {
        parsedPrice = double.tryParse(rawPrice.toString()) ?? 0.0;
      }
    }

    int parsedQuantity = 1;
    final rawQuantity = json['Quantity'] ?? json['quantity'];
    if (rawQuantity != null) {
      if (rawQuantity is int) {
        parsedQuantity = rawQuantity;
      } else {
        parsedQuantity = int.tryParse(rawQuantity.toString()) ?? 1;
      }
    }

    int? parsedId = id;
    if (parsedId == null && (json['Id'] != null || json['id'] != null)) {
      final rawId = json['Id'] ?? json['id'];
      parsedId = rawId is int ? rawId : int.tryParse(rawId.toString());
    }

    return Order(
      id: parsedId,
      item: (json['Item'] ?? json['item'] ?? '').toString().trim(),
      itemName: (json['ItemName'] ?? json['itemName'] ?? '').toString().trim(),
      price: parsedPrice,
      currency:
          (json['Currency'] ?? json['currency'] ?? 'USD').toString().trim(),
      quantity: parsedQuantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'Id': id,
      'Item': item,
      'ItemName': itemName,
      'Price': price % 1 == 0 ? price.toInt() : price,
      'Currency': currency,
      'Quantity': quantity,
    };
  }

  String get formattedPrice {
    final absolutePrice = price.abs();
    final intPrice = absolutePrice.toInt();
    if (absolutePrice == intPrice.toDouble()) {
      final s = intPrice.toString();
      final buffer = StringBuffer();
      int count = 0;
      for (int i = s.length - 1; i >= 0; i--) {
        buffer.write(s[i]);
        count++;
        if (count % 3 == 0 && i > 0) {
          buffer.write('.');
        }
      }
      final formatted = buffer.toString().split('').reversed.join('');
      return price.isNegative ? '-$formatted' : formatted;
    }
    return price.toStringAsFixed(2);
  }

  @override
  String toString() {
    return 'Order(Id: $id, Item: $item, ItemName: $itemName, Quantity: $quantity, Price: $formattedPrice, Currency: $currency)';
  }
}
