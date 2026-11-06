import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../lib/order_manager.dart';

void main(List<String> args) async {
  print(
      '======================================================================');
  print(
      '          FPT APTECH - INTRODUCTION TO DART PROGRAMMING               ');
  print(
      '                        EXAM PAPER - SET01                            ');
  print(
      '======================================================================');

  print('\n[Question 1 - 2 Marks] Create a class with the name "Order":');
  print(
      '-> Class Order defined in lib/order.dart with properties: item, itemName, price, currency, quantity, id.');

  print('\n[Question 2 - 5 Marks] Load orders from JSON storage:');
  final manager = OrderManager(filePath: 'order.json');
  await manager.init();
  print('-> Successfully loaded ${manager.orders.length} order(s):');
  manager.printOrders();

  print(
      '\n[Question 3 & 4] Use the console menu or website to insert and search orders.');

  print(
      '\n[Question 5 & Bonus UI] Starting Website Server at http://localhost:8080 ...');
  final server = await startWebServer(manager);

  await runInteractiveMenu(manager, server);
}

Future<HttpServer> startWebServer(OrderManager manager) async {
  int port = 8080;
  HttpServer? server;

  try {
    server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  } catch (e) {
    port = 8081;
    server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  }

  print(
      '\n======================================================================');
  print(' >> Website is LIVE at: http://localhost:$port');
  print(' >> Web browser has been launched to display the UI.');
  print(
      '======================================================================\n');

  try {
    if (Platform.isWindows) {
      Process.run('cmd', ['/c', 'start', 'http://localhost:$port']);
    } else if (Platform.isMacOS) {
      Process.run('open', ['http://localhost:$port']);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', ['http://localhost:$port']);
    }
  } catch (_) {}

  server.listen((HttpRequest request) {
    _handleRequest(request, manager)
        .catchError((Object error, StackTrace stack) {
      stderr.writeln('Unhandled request error: $error\n$stack');
    });
  });

  return server;
}

Future<void> runInteractiveMenu(OrderManager manager, HttpServer server) async {
  print(
      '\n----------------------------------------------------------------------');
  print(
      '          INTERACTIVE CONSOLE CONTROLLER (DUAL MODE ACTIVE)           ');
  print(
      '----------------------------------------------------------------------');

  final input = StreamIterator<String>(
      stdin.transform(utf8.decoder).transform(const LineSplitter()));
  try {
    bool running = true;
    while (running) {
      print('\n[Select an option]:');
      print('  1. View all orders in console');
      print('  2. Insert a new order (saves to order.json & syncs with web)');
      print('  3. Search order by ItemName');
      print('  4. Delete an order by Item code');
      print('  5. Re-open website in browser');
      print('  6. Reset order.json to default exam string');
      print('  7. Exit program');
      stdout.write('Choice (1-7): ');

      final choice = await _readInput(input);
      print('');

      switch (choice) {
        case '1':
          print('--- CURRENT ORDERS LIST ---');
          manager.printOrders();
          break;

        case '2':
          print('--- INSERT NEW ORDER ---');
          stdout.write('Enter Item Code (e.g. A1009): ');
          final item = await _readInput(input) ?? '';
          if (item.isEmpty) {
            print('Item code cannot be empty.');
            break;
          }

          stdout.write('Enter Item Name (e.g. Iphone 15 Pro Max): ');
          final itemName = await _readInput(input) ?? '';
          if (itemName.isEmpty) {
            print('Item Name cannot be empty.');
            break;
          }

          stdout.write('Enter Price (e.g. 1400): ');
          final priceStr = await _readInput(input) ?? '';
          final price = double.tryParse(priceStr) ?? 0.0;

          stdout.write('Enter Quantity (default 1): ');
          final qtyStr = await _readInput(input) ?? '1';
          final quantity = int.tryParse(qtyStr) ?? 1;

          stdout.write('Enter Currency (default USD): ');
          var currency = await _readInput(input) ?? 'USD';
          if (currency.isEmpty) currency = 'USD';

          final newOrder = await manager.insertOrder(
            item: item,
            itemName: itemName,
            price: price,
            currency: currency,
            quantity: quantity,
          );
          print('-> Successfully inserted order into order.json: $newOrder');
          break;

        case '3':
          print('--- SEARCH ORDER BY ITEM NAME ---');
          stdout.write('Enter search term (e.g. 15, Iphone): ');
          final term = await _readInput(input) ?? '';
          final results = manager.searchByItemName(term);
          print('Found ${results.length} matching order(s):');
          manager.printOrders(results);
          break;

        case '4':
          print('--- DELETE ORDER ---');
          stdout.write('Enter Item Code to delete (e.g. A1000): ');
          final deleteCode = await _readInput(input) ?? '';
          final deleted = await manager.deleteOrder(deleteCode);
          if (deleted) {
            print('-> Successfully deleted $deleteCode and updated order.json');
          } else {
            print('-> Item not found.');
          }
          break;

        case '5':
          final port = server.port;
          print('Opening http://localhost:$port ...');
          if (Platform.isWindows) {
            Process.run('cmd', ['/c', 'start', 'http://localhost:$port']);
          }
          break;

        case '6':
          manager.orders = manager.parseOrdersFromString(
              '[{"Item": "A1000","ItemName": "Iphone 15","Price": 1200,"Currency": "USD","Quantity":1},'
              '{"Item": "A1001","ItemName": "Iphone 16","Price": 1500,"Currency": "USD","Quantity":1}]');
          await manager.saveToFile();
          print('-> Reset order.json to default 2 exam items.');
          manager.printOrders();
          break;

        case '7':
          print('Shutting down server and exiting. Goodbye!');
          await server.close(force: true);
          running = false;
          break;

        default:
          print('Invalid option. Please enter 1-7.');
          break;
      }
    }
  } finally {
    await input.cancel();
  }
}

Future<String?> _readInput(StreamIterator<String> input) async {
  if (await input.moveNext()) {
    return input.current.trim();
  }
  return null;
}

Future<void> _handleRequest(HttpRequest request, OrderManager manager) async {
  final path = request.uri.path;
  final method = request.method;

  try {
    if (path == '/' || path == '/index.html') {
      final htmlFile = File('web/index.html');
      if (await htmlFile.exists()) {
        request.response.headers.contentType = ContentType.html;
        await htmlFile.openRead().pipe(request.response);
        return;
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('web/index.html not found');
        await request.response.close();
        return;
      }
    }

    if (path == '/api/orders' && method == 'GET') {
      final query = request.uri.queryParameters['search'] ?? '';
      final list = manager.searchByItemName(query);
      final jsonResponse = jsonEncode(list.map((o) => o.toJson()).toList());
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonResponse);
      await request.response.close();
      return;
    }

    if (path == '/api/orders' && method == 'POST') {
      final bodyString = await utf8.decoder.bind(request).join();
      final decodedBody = jsonDecode(bodyString);
      if (decodedBody is! Map) {
        throw const FormatException('Request body must be a JSON object.');
      }
      final data = Map<String, dynamic>.from(decodedBody);

      if (data['action'] == 'load_demo') {
        manager.orders.clear();
        for (int i = 0; i <= 8; i++) {
          await manager.insertOrder(
            item: 'A100$i',
            itemName: 'Iphone 15',
            price: 1200,
            currency: 'USD',
            quantity: 1,
          );
        }
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response
            .write(jsonEncode(manager.orders.map((o) => o.toJson()).toList()));
        await request.response.close();
        return;
      }

      if (data['action'] == 'reset_default') {
        manager.orders = manager.parseOrdersFromString(
            '[{"Item": "A1000","ItemName": "Iphone 15","Price": 1200,"Currency": "USD","Quantity":1},'
            '{"Item": "A1001","ItemName": "Iphone 16","Price": 1500,"Currency": "USD","Quantity":1}]');
        await manager.saveToFile();
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response
            .write(jsonEncode(manager.orders.map((o) => o.toJson()).toList()));
        await request.response.close();
        return;
      }

      final item = (data['Item'] ?? data['item'] ?? '').toString().trim();
      final itemName =
          (data['ItemName'] ?? data['itemName'] ?? '').toString().trim();
      final rawPrice = data['Price'] ?? data['price'];
      final price = rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice?.toString() ?? '');
      final currency =
          (data['Currency'] ?? data['currency'] ?? 'USD').toString().trim();
      final quantity = (data['Quantity'] ?? data['quantity'] ?? 1) is int
          ? (data['Quantity'] ?? data['quantity'] ?? 1)
          : int.tryParse(
                  (data['Quantity'] ?? data['quantity'] ?? 1).toString()) ??
              1;

      if (item.isEmpty ||
          itemName.isEmpty ||
          price == null ||
          !price.isFinite ||
          price < 0) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'error': 'Item, ItemName, and a non-negative Price are required.',
        }));
        await request.response.close();
        return;
      }

      final newOrder = await manager.insertOrder(
        item: item,
        itemName: itemName,
        price: price,
        currency: currency,
        quantity: quantity,
      );

      print(
          '[Web Action] Inserted new order into order.json: ${newOrder.item} - ${newOrder.itemName}');

      request.response.statusCode = HttpStatus.created;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(newOrder.toJson()));
      await request.response.close();
      return;
    }

    if (path.startsWith('/api/orders/') && method == 'DELETE') {
      final itemCode =
          Uri.decodeComponent(path.substring('/api/orders/'.length));
      final success = await manager.deleteOrder(itemCode);
      if (success) {
        print('[Web Action] Deleted order: $itemCode and updated order.json');
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response
            .write(jsonEncode({'success': true, 'message': 'Item deleted'}));
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'error': 'Item not found'}));
      }
      await request.response.close();
      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    request.response.write('Not Found');
    await request.response.close();
  } catch (e, stack) {
    print('Error processing request: $e\n$stack');
    try {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': e.toString()}));
      await request.response.close();
    } catch (_) {}
  }
}
