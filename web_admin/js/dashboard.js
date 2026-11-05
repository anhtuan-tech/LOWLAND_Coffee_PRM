import { db, collection, getDocs, onSnapshot, query, orderBy, limit } from "./config.js";

let revenueChartInstance = null;

export function formatVND(amount) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount || 0);
}

/**
 * Tải dữ liệu Dashboard Overview & lắng nghe cập nhật realtime
 */
export async function initDashboard() {
  await loadKpis();
  renderRevenueChart();
  listenRecentOrders();
}

/**
 * Tính toán 4 chỉ số KPI Cards
 */
async function loadKpis() {
  try {
    // 1. Lấy sản phẩm
    const productsSnap = await getDocs(collection(db, "products"));
    const totalProducts = productsSnap.size;
    document.getElementById("kpi-products").textContent = totalProducts;

    // 2. Lấy khách hàng
    const usersSnap = await getDocs(collection(db, "users"));
    let totalCustomers = 0;
    usersSnap.forEach((doc) => {
      const data = doc.data();
      if (data.role !== "admin") totalCustomers++;
    });
    document.getElementById("kpi-customers").textContent = totalCustomers;

    // 3. Lấy đơn hàng tính doanh thu & đơn thành công
    const ordersSnap = await getDocs(collection(db, "orders"));
    let totalRevenue = 0;
    let completedOrders = 0;

    ordersSnap.forEach((doc) => {
      const order = doc.data();
      if (order.status === "Hoàn thành" || order.status === "Đã giao") {
        totalRevenue += Number(order.totalAmount || 0);
        completedOrders++;
      }
    });

    document.getElementById("kpi-revenue").textContent = formatVND(totalRevenue);
    document.getElementById("kpi-orders").textContent = completedOrders;
  } catch (error) {
    console.error("Lỗi tải KPI:", error);
  }
}

/**
 * Vẽ Biểu đồ Doanh thu (Chart.js)
 */
function renderRevenueChart() {
  const ctx = document.getElementById("revenueChart");
  if (!ctx) return;

  if (revenueChartInstance) {
    revenueChartInstance.destroy();
  }

  // Dữ liệu mô phỏng doanh thu theo 7 ngày gần nhất
  const days = ["Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7", "Chủ Nhật"];
  const revenueData = [1250000, 1890000, 1640000, 2450000, 3100000, 4850000, 5200000];

  revenueChartInstance = new Chart(ctx, {
    type: 'line',
    data: {
      labels: days,
      datasets: [{
        label: 'Doanh thu (VNĐ)',
        data: revenueData,
        borderColor: '#4A2810', // Nâu cà phê LOWLAND
        backgroundColor: 'rgba(198, 139, 69, 0.15)', // Vàng mật ong
        borderWidth: 3,
        tension: 0.35,
        fill: true,
        pointBackgroundColor: '#C68B45',
        pointRadius: 5,
        pointHoverRadius: 8
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false },
        tooltip: {
          callbacks: {
            label: (ctx) => `Doanh thu: ${formatVND(ctx.parsed.y)}`
          }
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          ticks: {
            callback: (value) => (value / 1000000).toFixed(1) + ' tr'
          },
          grid: { color: '#F3ECE1' }
        },
        x: {
          grid: { display: false }
        }
      }
    }
  });
}

/**
 * Bảng đơn hàng mới nhất trong ngày (Realtime Stream)
 */
function listenRecentOrders() {
  const tableBody = document.getElementById("recent-orders-body");
  if (!tableBody) return;

  const ordersRef = collection(db, "orders");
  const q = query(ordersRef, orderBy("orderDate", "desc"), limit(6));

  onSnapshot(q, (snapshot) => {
    if (snapshot.empty) {
      tableBody.innerHTML = `
        <tr>
          <td colspan="5" class="py-6 text-center text-stone-400">
            Chưa có đơn hàng nào phát sinh hôm nay.
          </td>
        </tr>
      `;
      return;
    }

    let html = "";
    snapshot.forEach((doc) => {
      const order = doc.data();
      const statusBadge = getStatusBadge(order.status || "Mới nhận");

      html += `
        <tr class="border-b border-stone-100 hover:bg-stone-50 transition">
          <td class="py-3 px-4 font-semibold text-stone-800">#${order.orderId || doc.id.substring(0, 8)}</td>
          <td class="py-3 px-4 text-stone-600">
            <div class="font-medium">${order.userName || order.userId || "Khách vãng lai"}</div>
            <span class="text-[10px] font-bold ${order.paymentMethod && order.paymentMethod.includes('VNPAY') ? 'text-blue-600' : 'text-stone-400'}">
              ${order.paymentMethod ? (order.paymentMethod.includes('VNPAY') ? '💳 VNPAY Sandbox' : '💵 Tiền mặt') : '💵 Tiền mặt'}
            </span>
          </td>
          <td class="py-3 px-4 text-stone-500 text-sm">${formatDate(order.orderDate)}</td>
          <td class="py-3 px-4 font-bold text-amber-900">${formatVND(order.totalAmount)}</td>
          <td class="py-3 px-4">${statusBadge}</td>
        </tr>
      `;
    });

    tableBody.innerHTML = html;
  }, (err) => {
    console.error("Lỗi stream recent orders:", err);
  });
}

function getStatusBadge(status) {
  switch (status) {
    case "Mới nhận":
      return `<span class="px-2.5 py-1 text-xs font-semibold rounded-full bg-blue-100 text-blue-700">Mới nhận</span>`;
    case "Đang chế biến":
      return `<span class="px-2.5 py-1 text-xs font-semibold rounded-full bg-amber-100 text-amber-800">Đang chế biến</span>`;
    case "Đang giao":
      return `<span class="px-2.5 py-1 text-xs font-semibold rounded-full bg-purple-100 text-purple-700">Đang giao</span>`;
    case "Hoàn thành":
      return `<span class="px-2.5 py-1 text-xs font-semibold rounded-full bg-emerald-100 text-emerald-700">Hoàn thành</span>`;
    case "Đã hủy":
      return `<span class="px-2.5 py-1 text-xs font-semibold rounded-full bg-rose-100 text-rose-700">Đã hủy</span>`;
    default:
      return `<span class="px-2.5 py-1 text-xs font-semibold rounded-full bg-stone-100 text-stone-700">${status}</span>`;
  }
}

function formatDate(dateStr) {
  if (!dateStr) return "Mới đây";
  try {
    const d = new Date(dateStr);
    return d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) + ' ' + d.toLocaleDateString('vi-VN');
  } catch (_) {
    return dateStr;
  }
}

