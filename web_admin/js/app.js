import { listenAuthState, loginAdmin, logoutAdmin } from "./auth.js?v=16";
import { initDashboard } from "./dashboard.js?v=16";
import { initProducts } from "./products.js?v=16";
import { initOrders } from "./orders.js?v=16";
import { initUsers } from "./users.js?v=16";
import { initVouchers } from "./vouchers.js?v=16";

// Trạng thái tab hiện tại
let activeTab = "dashboard";
let isModulesInitialized = false;

function startRealtimeClock() {
  const updateClock = () => {
    const now = new Date();
    const timeStr = now.toLocaleTimeString("vi-VN", {
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
      hour12: false,
    });
    const dateStr = now.toLocaleDateString("vi-VN", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
    });
    const formatted = `${timeStr} • ${dateStr}`;
    const headerClock = document.getElementById("realtime-clock");
    if (headerClock) headerClock.textContent = formatted;
    const loginClock = document.getElementById("login-realtime-clock");
    if (loginClock) loginClock.textContent = formatted;
  };
  updateClock();
  setInterval(updateClock, 1000);
}

async function performAdminLogin(e) {
  if (e) {
    e.preventDefault();
    e.stopPropagation();
  }

  const loginError = document.getElementById("login-error-msg");
  const loginSubmitBtn = document.getElementById("login-submit-btn");

  if (loginError) loginError.classList.add("hidden");
  if (loginSubmitBtn) {
    loginSubmitBtn.disabled = true;
    loginSubmitBtn.innerHTML = `<span class="mr-2">⏳</span> Đang xác thực quyền Admin...`;
  }

  const email = document.getElementById("admin-email")?.value || "";
  const password = document.getElementById("admin-password")?.value || "";

  try {
    const adminUser = await loginAdmin(email, password);
    if (loginSubmitBtn) {
      loginSubmitBtn.disabled = false;
      loginSubmitBtn.innerHTML = `Đăng nhập hệ thống`;
    }
    showAdminLayout(adminUser);
    switchTab("dashboard");
    if (window.showToast) {
      window.showToast("Chào mừng Quản trị viên đến với hệ thống điều hành LOWLAND Coffee!", "success", "Đăng nhập thành công");
    }
  } catch (err) {
    if (loginError) {
      loginError.textContent = err.message;
      loginError.classList.remove("hidden");
    }
    if (window.showToast) {
      window.showToast(err.message, "error", "Đăng nhập thất bại");
    }
    if (loginSubmitBtn) {
      loginSubmitBtn.disabled = false;
      loginSubmitBtn.innerHTML = `Đăng nhập hệ thống`;
    }
  }
  return false;
}

window.handleAdminLoginSubmit = performAdminLogin;

function bootstrapAdminApp() {
  startRealtimeClock();

  // 1. Thiết lập Form Đăng nhập ngay lập tức để ngăn form reload trang (?)
  const loginForm = document.getElementById("admin-login-form");
  if (loginForm) {
    loginForm.addEventListener("submit", performAdminLogin);
  }

  // 2. Nút Đăng xuất (Dùng Custom Confirm Modal & Toast thay vì confirm() mặc định)
  const logoutBtn = document.getElementById("btn-logout");
  if (logoutBtn) {
    logoutBtn.addEventListener("click", async () => {
      const confirmed = window.showConfirmModal
        ? await window.showConfirmModal({
            title: "Xác nhận Đăng xuất",
            message: "Bạn có chắc chắn muốn đăng xuất khỏi cổng Quản trị LOWLAND Coffee?",
            confirmText: "Đăng xuất ngay",
            cancelText: "Ở lại",
            type: "warning"
          })
        : true;
      if (confirmed) {
        await logoutAdmin();
        showLoginForm();
        if (window.showToast) {
          window.showToast("Bạn đã đăng xuất khỏi phiên làm việc Quản trị viên.", "info", "Đã đăng xuất");
        }
      }
    });
  }

  // 3. Thiết lập chuyển Tab ở Sidebar
  const navItems = document.querySelectorAll(".nav-item");
  navItems.forEach((item) => {
    item.addEventListener("click", () => {
      const tab = item.getAttribute("data-tab");
      switchTab(tab);
    });
  });

  // 4. Kiểm tra trạng thái xác thực Admin
  listenAuthState(
    (adminUser) => {
      showAdminLayout(adminUser);
      switchTab(activeTab || "dashboard");
    },
    () => {
      showLoginForm();
    }
  );
}

// Khởi chạy an toàn dù DOMContentLoaded đã qua hay chưa (do ES Module tải bất đồng bộ)
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", bootstrapAdminApp);
} else {
  bootstrapAdminApp();
}

function showLoginForm() {
  document.getElementById("auth-screen").classList.remove("hidden");
  document.getElementById("admin-screen").classList.add("hidden");
}

function showAdminLayout(adminUser) {
  document.getElementById("auth-screen").classList.add("hidden");
  document.getElementById("admin-screen").classList.remove("hidden");

  // Hiển thị thông tin admin trên Header
  document.getElementById("header-admin-name").textContent =
    adminUser.displayName || "Quản Trị Viên";
  document.getElementById("header-admin-email").textContent =
    adminUser.email || "admin@lowlandcoffee.com";
  document.getElementById("header-admin-avatar").textContent = (
    adminUser.displayName ||
    adminUser.email ||
    "A"
  )[0].toUpperCase();

  // Chỉ khởi chạy các listener Firestore 1 lần để tránh nhân đôi dữ liệu
  if (!isModulesInitialized) {
    isModulesInitialized = true;
    initDashboard();
    initProducts();
    initOrders();
    initUsers();
    initVouchers();
  }
}

/**
 * Chuyển đổi giữa các tab Dashboard, Products, Orders, Users, Vouchers
 */
function switchTab(tabName) {
  activeTab = tabName;

  // Cập nhật giao diện Sidebar & màu icon Flaticon
  document.querySelectorAll(".nav-item").forEach((item) => {
    const icon = item.querySelector("i.fi");
    if (item.getAttribute("data-tab") === tabName) {
      item.classList.add("bg-amber-900/10", "text-amber-950", "font-bold");
      item.classList.remove("text-stone-600", "font-medium");
      if (icon) {
        icon.classList.add("text-amberLow");
        icon.classList.remove("text-stone-400");
      }
    } else {
      item.classList.remove("bg-amber-900/10", "text-amber-950", "font-bold");
      item.classList.add("text-stone-600", "font-medium");
      if (icon) {
        icon.classList.remove("text-amberLow");
        icon.classList.add("text-stone-400");
      }
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
