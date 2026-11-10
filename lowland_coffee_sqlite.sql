BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS cart_items (
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
CREATE TABLE IF NOT EXISTS favorites (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  productId TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  imageUrl TEXT,
  price REAL NOT NULL,
  description TEXT,
  createdAt TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS order_history (
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
CREATE TABLE IF NOT EXISTS shared_preferences (
  prefKey TEXT PRIMARY KEY NOT NULL,
  prefValue TEXT
);
DELETE FROM cart_items;
DELETE FROM favorites;
DELETE FROM order_history;
DELETE FROM shared_preferences;

INSERT INTO cart_items (productId, name, imageUrl, basePrice, selectedSize, selectedSugar, selectedIce, selectedToppings, itemPrice, quantity, totalPrice, createdAt) VALUES ('Mmjf1DCcUFbzi0tuyZee', 'Cà Phê Nấm Linh Chi', 'https://res.cloudinary.com/bflxgvhn/image/upload/v1794082524/lowland_coffee/products/ecug8v0eezriwxbwfrjy.png', 35000, 'S', 100, 100, '[]', 35000, 1, 35000, '2026-11-08T12:56:45.375');
INSERT OR REPLACE INTO favorites (productId, name, category, imageUrl, price, description, createdAt) VALUES ('cf_bac_xiu', 'Bạc Xỉu Sữa Tươi Kem Béo', 'Cà phê', 'https://images.unsplash.com/photo-1541167760496-1628856ab772?auto=format&fit=crop&w=600&q=80', 39000, 'Sự hòa quyện ngọt ngào giữa sữa béo, sữa tươi thanh trùng và chút phảng phất của cà phê phin nguyên chất.', '2026-11-08T12:57:40.574');
INSERT OR REPLACE INTO favorites (productId, name, category, imageUrl, price, description, createdAt) VALUES ('banh_chuoi_nuong', 'Bánh Chuối Nướng Thơm Bơ', 'Bánh', 'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?auto=format&fit=crop&w=600&q=80', 32000, 'Vị ngọt tự nhiên của chuối sứ chín muồi nướng vàng ươm, dậy mùi bơ sữa thơm nức lòng.', '2026-11-08T12:57:40.574');
INSERT OR REPLACE INTO order_history (orderId, userId, itemsJson, subtotal, discount, voucherCode, totalAmount, orderDate, status, paymentMethod) VALUES ('ORD-83230115', 'rTfUGUMnlZM6rbCHq6xh2PhCoov1', '[{"id":1,"productId":"banh_chuoi_nuong","name":"Bánh Chuối Nướng Thơm Bơ","imageUrl":"https://images.unsplash.com/photo-1607958996333-41aef7caefaa?auto=format&fit=crop&w=600&q=80","basePrice":32000,"selectedSize":"M","selectedSugar":100,"selectedIce":100,"selectedToppings":"[]","itemPrice":32000,"quantity":2,"totalPrice":64000,"createdAt":"2026-11-08T01:54:45.585"}]', 64000, 0, NULL, 64000, '2026-11-08T03:27:10.115', 'Hoàn thành', 'VNPAY Sandbox (Đã thanh toán)');
INSERT OR REPLACE INTO order_history (orderId, userId, itemsJson, subtotal, discount, voucherCode, totalAmount, orderDate, status, paymentMethod) VALUES ('ORD-76905926', 'rTfUGUMnlZM6rbCHq6xh2PhCoov1', '[{"id":7,"productId":"banh_pho_mai_cf","name":"Bánh Mousse Cà Phê Phô Mai","imageUrl":"https://images.unsplash.com/photo-1533134242443-d4fd215305ad?auto=format&fit=crop&w=600&q=80","basePrice":39000,"selectedSize":"M","selectedSugar":100,"selectedIce":100,"selectedToppings":"[]","itemPrice":45000,"quantity":2,"totalPrice":90000,"createdAt":"2026-11-08T01:41:43.716"}]', 90000, 0, NULL, 90000, '2026-11-08T01:41:45.926', 'Hoàn thành', 'Tiền mặt (COD)');
INSERT OR REPLACE INTO order_history (orderId, userId, itemsJson, subtotal, discount, voucherCode, totalAmount, orderDate, status, paymentMethod) VALUES ('ORD-76892564', 'rTfUGUMnlZM6rbCHq6xh2PhCoov1', '[{"id":6,"productId":"banh_pho_mai_cf","name":"Bánh Mousse Cà Phê Phô Mai","imageUrl":"https://images.unsplash.com/photo-1533134242443-d4fd215305ad?auto=format&fit=crop&w=600&q=80","basePrice":39000,"selectedSize":"M","selectedSugar":100,"selectedIce":100,"selectedToppings":"[]","itemPrice":45000,"quantity":2,"totalPrice":90000,"createdAt":"2026-11-08T01:41:30.580"}]', 90000, 0, NULL, 90000, '2026-11-08T01:41:32.564', 'Đã hủy', 'Tiền mặt (COD)');
INSERT OR REPLACE INTO order_history (orderId, userId, itemsJson, subtotal, discount, voucherCode, totalAmount, orderDate, status, paymentMethod) VALUES ('ORD-76851616', 'rTfUGUMnlZM6rbCHq6xh2PhCoov1', '[{"id":5,"productId":"tra_thach_dao","name":"Trà Thạch Đào Mát Lạnh","imageUrl":"https://images.unsplash.com/photo-1556679343-c7306c1976bc?auto=format&fit=crop&w=600&q=80","basePrice":45000,"selectedSize":"L","selectedSugar":100,"selectedIce":100,"selectedToppings":"[\"Miếng đào thêm (+10.000đ)\",\"Thạch đào (+6.000đ)\",\"Trân châu trắng (+6.000đ)\"]","itemPrice":77000,"quantity":4,"totalPrice":308000,"createdAt":"2026-11-08T01:40:48.551"},{"id":4,"productId":"cf_phin_den","name":"Phin Đen Đá Nguyên Bản","imageUrl":"https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=600&q=80","basePrice":32000,"selectedSize":"L","selectedSugar":100,"selectedIce":100,"selectedToppings":"[\"Thạch cà phê (+6.000đ)\",\"Shot Espresso (+10.000đ)\"]","itemPrice":58000,"quantity":2,"totalPrice":116000,"createdAt":"2026-11-08T01:40:48.550"},{"id":3,"productId":"banh_chuoi_nuong","name":"Bánh Chuối Nướng Thơm Bơ","imageUrl":"https://images.unsplash.com/photo-1607958996333-41aef7caefaa?auto=format&fit=crop&w=600&q=80","basePrice":32000,"selectedSize":"M","selectedSugar":100,"selectedIce":100,"selectedToppings":"[]","itemPrice":32000,"quantity":3,"totalPrice":96000,"createdAt":"2026-11-08T00:31:17.625"}]', 520000, 0, NULL, 520000, '2026-11-08T01:40:51.616', 'Hoàn thành', 'Tiền mặt (COD)');
INSERT OR REPLACE INTO order_history (orderId, userId, itemsJson, subtotal, discount, voucherCode, totalAmount, orderDate, status, paymentMethod) VALUES ('ORD-42603422', 'rTfUGUMnlZM6rbCHq6xh2PhCoov1', '[{"id":1,"productId":"banh_chuoi_nuong","name":"Bánh Chuối Nướng Thơm Bơ","imageUrl":"https://images.unsplash.com/photo-1607958996333-41aef7caefaa?auto=format&fit=crop&w=600&q=80","basePrice":32000,"selectedSize":"M","selectedSugar":100,"selectedIce":100,"selectedToppings":"[]","itemPrice":38000,"quantity":2,"totalPrice":76000,"createdAt":"2026-11-05T08:36:18.520"}]', 76000, 0, NULL, 76000, '2026-11-05T08:36:43.422', 'Hoàn thành', 'VNPAY Sandbox (Đã thanh toán)');
INSERT OR REPLACE INTO order_history (orderId, userId, itemsJson, subtotal, discount, voucherCode, totalAmount, orderDate, status, paymentMethod) VALUES ('ORD-42706362', 'rTfUGUMnlZM6rbCHq6xh2PhCoov1', '[{"id":2,"productId":"banh_pho_mai_cf","name":"Bánh Mousse Cà Phê Phô Mai","imageUrl":"https://images.unsplash.com/photo-1533134242443-d4fd215305ad?auto=format&fit=crop&w=600&q=80","basePrice":39000,"selectedSize":"M","selectedSugar":100,"selectedIce":100,"selectedToppings":"[]","itemPrice":45000,"quantity":2,"totalPrice":90000,"createdAt":"2026-11-05T08:37:51.454"}]', 90000, 18000, 'LOWLANDNEW', 72000, '2026-11-05T08:38:26.362', 'Hoàn thành', 'VNPAY Sandbox (Đã thanh toán)');
INSERT OR REPLACE INTO order_history (orderId, userId, itemsJson, subtotal, discount, voucherCode, totalAmount, orderDate, status, paymentMethod) VALUES ('ORD-64159226', 'rTfUGUMnlZM6rbCHq6xh2PhCoov1', '[{"id":2,"productId":"tra_thach_dao","name":"Trà Thạch Đào Mát Lạnh","imageUrl":"https://images.unsplash.com/photo-1556679343-c7306c1976bc?auto=format&fit=crop&w=600&q=80","basePrice":45000,"selectedSize":"L","selectedSugar":100,"selectedIce":70,"selectedToppings":"[\"Trân châu trắng (+6.000đ)\",\"Thạch đào (+6.000đ)\",\"Miếng đào thêm (+10.000đ)\"]","itemPrice":77000,"quantity":1,"totalPrice":77000,"createdAt":"2026-11-07T22:09:05.125"},{"id":1,"productId":"cf_phin_sua","name":"Phin Sữa Đá Đậm Đà","imageUrl":"https://images.unsplash.com/photo-1517256064527-09c73fc73e38?auto=format&fit=crop&w=600&q=80","basePrice":35000,"selectedSize":"L","selectedSugar":100,"selectedIce":100,"selectedToppings":"[\"Thạch cà phê (+6.000đ)\",\"Trân châu trắng (+6.000đ)\",\"Kem Cheese (+10.000đ)\",\"Shot Espresso (+10.000đ)\"]","itemPrice":77000,"quantity":2,"totalPrice":154000,"createdAt":"2026-11-07T22:08:47.093"}]', 231000, 0, NULL, 231000, '2026-11-07T22:09:19.227', 'Hoàn thành', 'Tiền mặt (COD)');
INSERT OR REPLACE INTO order_history (orderId, userId, itemsJson, subtotal, discount, voucherCode, totalAmount, orderDate, status, paymentMethod) VALUES ('ORD-64182943', 'rTfUGUMnlZM6rbCHq6xh2PhCoov1', '[{"id":4,"productId":"banh_croissant","name":"Bánh Croissant Ngàn Lớp","imageUrl":"https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=600&q=80","basePrice":35000,"selectedSize":"M","selectedSugar":100,"selectedIce":100,"selectedToppings":"[]","itemPrice":35000,"quantity":1,"totalPrice":35000,"createdAt":"2026-11-07T22:09:33.588"},{"id":3,"productId":"banh_chuoi_nuong","name":"Bánh Chuối Nướng Thơm Bơ","imageUrl":"https://images.unsplash.com/photo-1607958996333-41aef7caefaa?auto=format&fit=crop&w=600&q=80","basePrice":32000,"selectedSize":"M","selectedSugar":100,"selectedIce":100,"selectedToppings":"[]","itemPrice":32000,"quantity":1,"totalPrice":32000,"createdAt":"2026-11-07T22:09:30.495"}]', 67000, 0, NULL, 67000, '2026-11-07T22:09:42.943', 'Hoàn thành', 'VNPAY Sandbox (Đã thanh toán)');
INSERT OR REPLACE INTO order_history (orderId, userId, itemsJson, subtotal, discount, voucherCode, totalAmount, orderDate, status, paymentMethod) VALUES ('ORD-72312880', 'rTfUGUMnlZM6rbCHq6xh2PhCoov1', '[{"id":2,"productId":"cf_phin_den","name":"Phin Đen Đá Nguyên Bản","imageUrl":"https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=600&q=80","basePrice":32000,"selectedSize":"L","selectedSugar":100,"selectedIce":100,"selectedToppings":"[\"Thạch cà phê (+6.000đ)\",\"Shot Espresso (+10.000đ)\"]","itemPrice":58000,"quantity":2,"totalPrice":116000,"createdAt":"2026-11-08T00:23:57.682"},{"id":1,"productId":"tra_thach_dao","name":"Trà Thạch Đào Mát Lạnh","imageUrl":"https://images.unsplash.com/photo-1556679343-c7306c1976bc?auto=format&fit=crop&w=600&q=80","basePrice":45000,"selectedSize":"L","selectedSugar":100,"selectedIce":100,"selectedToppings":"[\"Miếng đào thêm (+10.000đ)\",\"Thạch đào (+6.000đ)\",\"Trân châu trắng (+6.000đ)\"]","itemPrice":77000,"quantity":4,"totalPrice":308000,"createdAt":"2026-11-08T00:23:46.803"}]', 424000, 40000, 'LOWLANDNEW', 384000, '2026-11-08T00:25:12.880', 'Hoàn thành', 'VNPAY Sandbox (Đã thanh toán)');
INSERT OR REPLACE INTO shared_preferences (prefKey, prefValue) VALUES ('is_logged_in', 'true');
INSERT OR REPLACE INTO shared_preferences (prefKey, prefValue) VALUES ('user_uid', 'rTfUGUMnlZM6rbCHq6xh2PhCoov1');
INSERT OR REPLACE INTO shared_preferences (prefKey, prefValue) VALUES ('user_email', 'tuanleanh15052004@gmail.com');
INSERT OR REPLACE INTO shared_preferences (prefKey, prefValue) VALUES ('user_name', 'Lê Anh Tuấn');
INSERT OR REPLACE INTO shared_preferences (prefKey, prefValue) VALUES ('user_phone_number', '0815255855');
COMMIT;
