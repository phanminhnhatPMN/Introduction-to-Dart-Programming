# Introduction to Dart Programming - SET01

A Dart order-management application built for the practical examination requirements:

- Create an `Order` model.
- Read orders from a JSON string.
- Display, add, and search orders by `ItemName`.
- Persist orders in `order.json`.
- Provide both a web interface and a console menu.

## Requirements

- Dart SDK 3.0 or later.

## Run the application

```bash
dart pub get
dart run
```

The application starts a web server at `http://localhost:8080`. If that port is already in use, it uses port `8081`.

Use the console menu to view, add, search, delete, or reset orders.

## Run tests

```bash
dart test
```

## Project structure

```text
bin/main.dart           Console menu, HTTP server, and API
lib/order.dart          Order model
lib/order_manager.dart  JSON, search, and file-persistence logic
web/index.html          Web user interface
test/order_test.dart    Unit tests
order.json              Order data
```
