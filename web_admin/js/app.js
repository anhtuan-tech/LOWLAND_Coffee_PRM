import { listenAuthState, loginAdmin, logoutAdmin, getCurrentAdmin } from "./auth.js";
import { initDashboard } from "./dashboard.js";
import { initProducts } from "./products.js";
import { initOrders } from "./orders.js";
import { initUsers } from "./users.js";
import { initVouchers } from "./vouchers.js";

// Trạng thái tab hiện tại
let activeTab = "dashboard";

document.addEventListener("DOMContentLoaded", () => {
  // 1. Kiểm tra xác thực Admin
  listenAuthState(
    (adminUser) => {
      // Đăng nhập thành công với quyền Admin
      showAdminLayout(adminUser);
      switchTab("dashboard");
    },
    () => {
      // Chưa đăng nhập hoặc không phải Admin
      showLoginForm();
    }
  );

  // 2. Thiết lập Form Đăng nhập
  const loginForm = document.getElementById("admin-login-form");
  const loginError = document.getElementById("login-error-msg");
  const loginSubmitBtn = document.getElementById("login-submit-btn");

  loginForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    loginError.classList.add("hidden");
    loginSubmitBtn.disabled = true;
    loginSubmitBtn.innerHTML = `<span>⏳</span> Đang xác thực quyền Admin...`;

    const email = document.getElementById("admin-email").value;
    const password = document.getElementById("admin-password").value;

    try {
      await loginAdmin(email, password);
      // listenAuthState sẽ tự kích hoạt chuyển màn hình
    } catch (err) {
      loginError.textContent = err.message;
      loginError.classList.remove("hidden");
      loginSubmitBtn.disabled = false;
      loginSubmitBtn.innerHTML = `Đăng nhập hệ thống`;
    }
  });

  // 3. Nút Đăng xuất
  document.getElementById("btn-logout").addEventListener("click", async () => {
    if (confirm("Bạn có chắc chắn muốn đăng xuất khỏi trang Quản trị?")) {
      await logoutAdmin();
      showLoginForm();
    }
  });

  // 4. Thiết lập chuyển Tab ở Sidebar
  const navItems = document.querySelectorAll(".nav-item");
  navItems.forEach((item) => {
    item.addEventListener("click", () => {
      const tab = item.getAttribute("data-tab");
      switchTab(tab);
    });
  });
});

function showLoginForm() {
  document.getElementById("auth-screen").classList.remove("hidden");
  document.getElementById("admin-screen").classList.add("hidden");
}

function showAdminLayout(adminUser) {
  document.getElementById("auth-screen").classList.add("hidden");
  document.getElementById("admin-screen").classList.remove("hidden");

  // Hiển thị thông tin admin trên Header
  document.getElementById("header-admin-name").textContent = adminUser.displayName || "Quản Trị Viên";
  document.getElementById("header-admin-email").textContent = adminUser.email || "admin@lowlandcoffee.com";
  document.getElementById("header-admin-avatar").textContent = (adminUser.displayName || adminUser.email || "A")[0].toUpperCase();

  // Khởi chạy các module
  initDashboard();
  initProducts();
  initOrders();
  initUsers();
  initVouchers();
}

/**
 * Chuyển đổi giữa các tab Dashboard, Products, Orders, Users, Vouchers
 */
function switchTab(tabName) {
  activeTab = tabName;

  // Cập nhật giao diện Sidebar
  document.querySelectorAll(".nav-item").forEach((item) => {
    if (item.getAttribute("data-tab") === tabName) {
      item.classList.add("bg-amber-900/10", "text-amber-950", "font-bold");
      item.classList.remove("text-stone-600", "font-medium");
    } else {
      item.classList.remove("bg-amber-900/10", "text-amber-950", "font-bold");
      item.classList.add("text-stone-600", "font-medium");
    }
  });

  // Ẩn tất cả view
  const views = ["dashboard", "products", "orders", "users", "vouchers"];
  views.forEach((v) => {
    const el = document.getElementById(`view-${v}`);
    if (el) el.classList.add("hidden");
  });

  // Hiển thị view được chọn
  const activeView = document.getElementById(`view-${tabName}`);
  if (activeView) {
    activeView.classList.remove("hidden");
  }

  // Tải lại icons
  if (window.lucide) {
    window.lucide.createIcons();
  }
}

