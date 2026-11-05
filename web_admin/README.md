# Trang Web Admin Quản Lý • LOWLAND Coffee

Trang Web Quản trị trung tâm dành cho Quản lý & Nhân viên quán café "LOWLAND Coffee", kết nối trực tiếp với cùng hệ thống Firebase (Authentication, Cloud Firestore, Cloud Storage) của ứng dụng Mobile.

## Các tính năng đã hoàn thiện:
1. **Xác thực & Phân quyền (Auth & RBAC)**:
   - Đăng nhập chỉ dành riêng cho tài khoản có quyền `role == 'admin'` trong Firestore collection `users`.
   - Chặn người dùng thường và tài khoản bị vô hiệu hóa (`isBlocked == true`).
2. **Tổng quan KPI (Dashboard Overview)**:
   - 4 Thẻ KPI: Doanh thu thực tế, Số đơn thành công, Số lượng món thực đơn, Số lượng khách hàng.
   - Biểu đồ Doanh thu 7 ngày gần nhất (Chart.js phong cách Nâu / Kem).
   - Bảng đơn hàng mới nhất phát sinh trong ngày.
3. **Quản lý Thực đơn & Sản phẩm (Product CRUD - Quan trọng)**:
   - Bảng danh sách món ăn, đồ uống (ảnh, tên, danh mục, đơn giá, trạng thái Còn hàng / Hết hàng).
   - Form Thêm món mới: Chọn ảnh từ máy tính -> tự động upload lên Firebase Storage và lưu URL vào Firestore.
   - Chỉnh sửa thông tin, giá bán, tùy chọn Size (S/M/L) và Topping.
   - Chuyển trạng thái Còn hàng / Hết hàng bằng 1 click.
   - Xóa món khỏi thực đơn.
4. **Quản lý Đơn hàng Realtime (Order Processing)**:
   - Tự động nhận đơn hàng mới theo thời gian thực (Realtime Stream).
   - Xem chi tiết từng món, size, đường, đá, topping, voucher giảm giá.
   - Duyệt và cập nhật nhanh trạng thái đơn: *Mới nhận -> Đang chế biến -> Đang giao -> Hoàn thành / Đã hủy*.
5. **Quản lý Khách hàng & Mã giảm giá (Users & Vouchers)**:
   - Xem danh sách thành viên đăng ký trên app.
   - Nút Chặn / Mở khóa tài khoản khách hàng (`isBlocked: true/false`).
   - Tạo mã voucher khuyến mãi mới (theo % hoặc số tiền cố định).

## Cách mở & chạy Web Admin:
- **Cách 1**: Mở trực tiếp file `web_admin/index.html` bằng trình duyệt Chrome / Edge (hoặc dùng tiện ích *Live Server* trong VS Code).
- **Cách 2**: Chạy máy chủ tĩnh cục bộ bằng terminal:
  ```bash
  cd web_admin
  npx serve .
  # hoặc: python -m http.server 8080
  ```
- **Tài khoản đăng nhập Quản trị viên:**
  - Email: `admin@lowlandcoffee.com`
  - Mật khẩu: Mật khẩu bạn đã tạo trên Firebase Auth

