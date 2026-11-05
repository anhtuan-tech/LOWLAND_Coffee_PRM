-- ========================================================
-- CƠ SỞ DỮ LIỆU SQLITE: lowland_coffee.db
-- ỨNG DỤNG LOWLAND COFFEE
-- ========================================================

-- 1. BẢNG GIỎ HÀNG (cart_items)
DROP TABLE IF EXISTS cart_items;
CREATE TABLE cart_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    productId TEXT NOT NULL,
    name TEXT NOT NULL,
    imageUrl TEXT,
    basePrice REAL NOT NULL,
    selectedSize TEXT NOT NULL,
    selectedSugar INTEGER NOT NULL,
    selectedIce INTEGER NOT NULL,
    selectedToppings TEXT,
    itemPrice REAL NOT NULL,
    quantity INTEGER NOT NULL,
    totalPrice REAL NOT NULL,
    createdAt TEXT NOT NULL
);

-- Dữ liệu mẫu giỏ hàng
INSERT INTO cart_items (productId, name, imageUrl, basePrice, selectedSize, selectedSugar, selectedIce, selectedToppings, itemPrice, quantity, totalPrice, createdAt) VALUES
('cf_phin_sua', 'Phin Sữa Đá Đậm Đà', 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?auto=format&fit=crop&w=600&q=80', 35000, 'L', 70, 50, 'Kem Cheese (+10.000đ)', 45000, 2, 90000, datetime('now')),
('banh_chuoi_nuong', 'Bánh Chuối Nướng Thơm Bơ', 'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?auto=format&fit=crop&w=600&q=80', 32000, 'M', 100, 100, '', 32000, 1, 32000, datetime('now'));

-- 2. BẢNG MÓN YÊU THÍCH (favorites)
DROP TABLE IF EXISTS favorites;
CREATE TABLE favorites (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    productId TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    imageUrl TEXT,
    price REAL NOT NULL,
    description TEXT,
    createdAt TEXT NOT NULL
);

-- Dữ liệu mẫu món yêu thích
INSERT INTO favorites (productId, name, category, imageUrl, price, description, createdAt) VALUES
('cf_phin_sua', 'Phin Sữa Đá Đậm Đà', 'Cà phê', 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?auto=format&fit=crop&w=600&q=80', 35000, 'Hạt cà phê Robusta hảo hạng hòa quyện cùng sữa đặc béo ngậy.', datetime('now')),
('tra_dao_cam_sa', 'Trà Đào Cam Sả Tươi Mát', 'Trà', 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?auto=format&fit=crop&w=600&q=80', 49000, 'Trà đen ủ lạnh ngát hương sả tươi và đào mọng nước.', datetime('now')),
('banh_chuoi_nuong', 'Bánh Chuối Nướng Thơm Bơ', 'Bánh', 'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?auto=format&fit=crop&w=600&q=80', 32000, 'Vị ngọt tự nhiên của chuối sứ chín muồi nướng vàng ươm.', datetime('now'));

-- 3. BẢNG LỊCH SỬ ĐƠN HÀNG (order_history)
DROP TABLE IF EXISTS order_history;
CREATE TABLE order_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    orderId TEXT UNIQUE NOT NULL,
    userId TEXT NOT NULL,
    itemsJson TEXT NOT NULL,
    subtotal REAL NOT NULL,
    discount REAL NOT NULL,
    voucherCode TEXT,
    totalAmount REAL NOT NULL,
    orderDate TEXT NOT NULL,
    status TEXT NOT NULL,
    paymentMethod TEXT
);

-- Dữ liệu mẫu đơn hàng hoàn thành
INSERT INTO order_history (orderId, userId, itemsJson, subtotal, discount, voucherCode, totalAmount, orderDate, status, paymentMethod) VALUES
('ORD-20261105-01', 'tuanleanh15052004', '[{"name":"Phin Sữa Đá Đậm Đà","quantity":2,"price":45000,"size":"L"},{"name":"Bánh Chuối Nướng Thơm Bơ","quantity":1,"price":32000,"size":"M"}]', 122000, 24400, 'LOWLANDNEW', 97600, datetime('now'), 'Hoàn thành', 'VNPAY Sandbox (Đã thanh toán)');

