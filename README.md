# Introduction to Dart Programming - SET01

Ứng dụng quản lý đơn hàng bằng Dart, thực hiện các yêu cầu của bài thực hành:

- Tạo model `Order`.
- Đọc danh sách đơn hàng từ chuỗi JSON.
- Hiển thị, thêm và tìm kiếm đơn hàng theo `ItemName`.
- Lưu dữ liệu vào `order.json`.
- Cung cấp giao diện web và menu console.

## Yêu cầu

- Dart SDK 3.0 trở lên.

## Chạy ứng dụng

```bash
dart pub get
dart run
```

Ứng dụng khởi động web server tại `http://localhost:8080`. Nếu cổng này đang được sử dụng, server sẽ dùng cổng `8081`.

Trong terminal, chọn một trong các chức năng để xem, thêm, tìm kiếm, xóa hoặc khôi phục danh sách đơn hàng.

## Chạy kiểm thử

```bash
dart test
```

## Cấu trúc project

```text
bin/main.dart           Console menu, HTTP server và API
lib/order.dart          Model Order
lib/order_manager.dart  Xử lý JSON, tìm kiếm và lưu file
web/index.html          Giao diện web
test/order_test.dart    Unit tests
order.json              Dữ liệu đơn hàng
```
