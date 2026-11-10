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

INSERT INTO cart_items (productId, name, imageUrl, basePrice, selectedSize, selectedSugar, selectedIce, selectedToppings, itemPrice, quantity, totalPrice, createdAt) VALUES ('Mmjf1DCcUFbzi0tuyZee', 'Cà Phê Nấm Linh Chi', 'https://res.cloudinary.com/bflxgvhn/image/upload/v1794082524/lowland_coffee/products/ecug8v0eezriwxbwfrjy.png', 35000, 'S', 100, 100, '[]', 35000, 1, 35000, '2026-11-10T08:57:23.504');
INSERT OR REPLACE INTO order_history (orderId, userId, itemsJson, subtotal, discount, voucherCode, totalAmount, orderDate, status, paymentMethod) VALUES ('ORD-74561576', 'jbwRqBLgE6RpNKZ1dffpj7E2bH73', '[{"id":2,"productId":"OHbT4keDQ9mHj7PabawP","name":"Cà Phê Đông Trùng Hạ Thảo","imageUrl":"https://res.cloudinary.com/bflxgvhn/image/upload/v1794082982/lowland_coffee/products/jtuufhe8qh2o0cfivht4.jpg","basePrice":35000,"selectedSize":"S","selectedSugar":100,"selectedIce":100,"selectedToppings":"[]","itemPrice":35000,"quantity":1,"totalPrice":35000,"createdAt":"2026-11-10T08:34:37.982"}]', 35000, 0, NULL, 35000, '2026-11-10T08:36:01.576', 'Hoàn thành', 'VNPAY Sandbox (Đã thanh toán)');
INSERT OR REPLACE INTO order_history (orderId, userId, itemsJson, subtotal, discount, voucherCode, totalAmount, orderDate, status, paymentMethod) VALUES ('ORD-74226410', 'jbwRqBLgE6RpNKZ1dffpj7E2bH73', '[{"id":1,"productId":"Mmjf1DCcUFbzi0tuyZee","name":"Cà Phê Nấm Linh Chi","imageUrl":"https://res.cloudinary.com/bflxgvhn/image/upload/v1794082524/lowland_coffee/products/ecug8v0eezriwxbwfrjy.png","basePrice":35000,"selectedSize":"S","selectedSugar":50,"selectedIce":50,"selectedToppings":"[]","itemPrice":35000,"quantity":1,"totalPrice":35000,"createdAt":"2026-11-10T08:28:41.753"}]', 35000, 0, NULL, 35000, '2026-11-10T08:30:26.410', 'Đã hủy', 'VNPAY Sandbox (Đã thanh toán)');
INSERT OR REPLACE INTO shared_preferences (prefKey, prefValue) VALUES ('is_logged_in', 'true');
INSERT OR REPLACE INTO shared_preferences (prefKey, prefValue) VALUES ('user_uid', 'jbwRqBLgE6RpNKZ1dffpj7E2bH73');
INSERT OR REPLACE INTO shared_preferences (prefKey, prefValue) VALUES ('user_email', 'khangnm.ce190728@gmail.com');
INSERT OR REPLACE INTO shared_preferences (prefKey, prefValue) VALUES ('user_name', 'Nguyễn Minh Khang');
INSERT OR REPLACE INTO shared_preferences (prefKey, prefValue) VALUES ('user_phone_number', '0942938615');
COMMIT;
