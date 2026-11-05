import { 
  db, 
  collection, 
  doc, 
  updateDoc, 
  onSnapshot, 
  query, 
  orderBy 
} from "./config.js";
import { formatVND } from "./dashboard.js";

let ordersList = [];
let currentFilter = "all";

/**
 * Khởi tạo quản lý Đơn hàng Realtime
 */
export function initOrders() {
  listenOrdersStream();
  setupFilterTabs();
}

/**
 * Lắng nghe Realtime Stream từ collection 'orders'
 */
function listenOrdersStream() {
  const container = document.getElementById("orders-container");
  if (!container) return;

  const ordersRef = collection(db, "orders");
  const q = query(ordersRef, orderBy("orderDate", "desc"));

  onSnapshot(q, (snapshot) => {
    ordersList = [];
    snapshot.forEach((doc) => {
      ordersList.push({ docId: doc.id, ...doc.data() });
    });

    renderOrders();
  }, (err) => {
    console.error("Lỗi stream orders:", err);
  });
}

function setupFilterTabs() {
  const tabs = document.querySelectorAll(".order-filter-tab");
  tabs.forEach(tab => {
    tab.addEventListener("click", () => {
      tabs.forEach(t => t.classList.remove("active-filter", "bg-amber-900", "text-white"));
      tabs.forEach(t => t.classList.add("bg-stone-100", "text-stone-600"));

      tab.classList.remove("bg-stone-100", "text-stone-600");
      tab.classList.add("active-filter", "bg-amber-900", "text-white");

      currentFilter = tab.getAttribute("data-status");
      renderOrders();
    });
  });
}

function renderOrders() {
  const container = document.getElementById("orders-container");
  if (!container) return;

  const filtered = ordersList.filter(order => {
    if (currentFilter === "all") return true;
    return order.status === currentFilter;
  });

  if (filtered.length === 0) {
    container.innerHTML = `
      <div class="col-span-full py-16 text-center text-stone-400">
        <i data-lucide="inbox" class="w-12 h-12 mx-auto mb-3 stroke-1"></i>
        <p class="text-base font-medium">Không có đơn hàng nào trong trạng thái này.</p>
      </div>
    `;
    if (window.lucide) window.lucide.createIcons();
    return;
  }

  let html = "";
  filtered.forEach(order => {
    const items = order.items || [];
    const dateFormatted = formatDate(order.orderDate);
    const docId = order.docId;

    html += `
      <div class="bg-white rounded-2xl border border-stone-200/80 shadow-sm p-5 hover:shadow-md transition">
        <!-- Header đơn hàng -->
        <div class="flex items-start justify-between border-b border-stone-100 pb-3 mb-3">
          <div>
            <div class="flex items-center space-x-2">
              <span class="font-bold text-lg text-amber-950">#${order.orderId || docId.substring(0, 8)}</span>
              ${getStatusBadge(order.status || "Mới nhận")}
            </div>
            <p class="text-xs text-stone-400 mt-1">🕒 ${dateFormatted}</p>
          </div>
          <div class="text-right">
            <span class="text-xs text-stone-500 block">Tổng thanh toán</span>
            <span class="text-lg font-black text-amber-900">${formatVND(order.totalAmount)}</span>
          </div>
        </div>

        <!-- Khách hàng & Thanh toán -->
        <div class="text-xs text-stone-600 mb-3 bg-stone-50 p-2.5 rounded-xl space-y-1">
          <p class="font-semibold text-stone-800">👤 Khách hàng: <span class="font-normal">${order.userName || order.userId || "Khách lẻ"}</span></p>
          <p class="font-semibold flex items-center">
            💳 Thanh toán: 
            <span class="ml-1.5 px-2 py-0.5 rounded-md text-[10px] font-bold ${order.paymentMethod && order.paymentMethod.includes('VNPAY') ? 'bg-blue-100 text-blue-800 border border-blue-200' : 'bg-amber-100 text-amber-900 border border-amber-200'}">
              ${order.paymentMethod || "Tiền mặt (COD)"}
            </span>
          </p>
          ${order.voucherCode ? `<p class="text-emerald-700 font-semibold">🎟️ Voucher: ${order.voucherCode} (-${formatVND(order.discount)})</p>` : ''}
        </div>

        <!-- Danh sách món đã đặt -->
        <div class="space-y-2 mb-4 max-h-48 overflow-y-auto pr-1">
          ${items.map(item => `
            <div class="flex items-start justify-between text-xs py-1 border-b border-stone-50">
              <div class="flex-1 pr-2">
                <span class="font-bold text-amber-900">${item.quantity}x</span>
                <span class="font-semibold text-stone-800">${item.name}</span>
                <p class="text-[11px] text-stone-500">Size: ${item.selectedSize || "M"} | Đường: ${item.selectedSugar || 100}% | Đá: ${item.selectedIce || 100}%</p>
                ${item.selectedToppings && item.selectedToppings.length ? `<p class="text-[10px] text-amber-800">+ ${item.selectedToppings.join(', ')}</p>` : ''}
              </div>
              <span class="font-semibold text-stone-700">${formatVND(item.totalPrice)}</span>
            </div>
          `).join('')}
        </div>

        <!-- Thanh điều khiển trạng thái nhanh -->
        <div class="pt-3 border-t border-stone-100 flex items-center justify-between">
          <span class="text-xs font-semibold text-stone-500">Đổi trạng thái:</span>
          <select onchange="window.updateOrderStatus('${docId}', this.value)" 
                  class="text-xs font-semibold rounded-xl border border-stone-300 py-1.5 px-3 bg-stone-50 focus:ring-2 focus:ring-amber-800 outline-none">
            <option value="Mới nhận" ${order.status === "Mới nhận" ? "selected" : ""}>🔵 Mới nhận</option>
            <option value="Đang chế biến" ${order.status === "Đang chế biến" ? "selected" : ""}>🟠 Đang chế biến</option>
            <option value="Đang giao" ${order.status === "Đang giao" ? "selected" : ""}>🟣 Đang giao</option>
            <option value="Hoàn thành" ${order.status === "Hoàn thành" ? "selected" : ""}>🟢 Hoàn thành</option>
            <option value="Đã hủy" ${order.status === "Đã hủy" ? "selected" : ""}>🔴 Đã hủy</option>
          </select>
        </div>
      </div>
    `;
  });

  container.innerHTML = html;
  if (window.lucide) window.lucide.createIcons();
}

/**
 * Cập nhật trạng thái đơn hàng trực tiếp lên Cloud Firestore
 */
window.updateOrderStatus = async function(docId, newStatus) {
  try {
    const orderRef = doc(db, "orders", docId);
    await updateDoc(orderRef, {
      status: newStatus,
      updatedAt: new Date().toISOString()
    });
  } catch (err) {
    alert("Lỗi cập nhật trạng thái đơn: " + err.message);
  }
};

function getStatusBadge(status) {
  switch (status) {
    case "Mới nhận":
      return `<span class="px-2 py-0.5 text-xs font-bold rounded-full bg-blue-100 text-blue-700">Mới nhận</span>`;
    case "Đang chế biến":
      return `<span class="px-2 py-0.5 text-xs font-bold rounded-full bg-amber-100 text-amber-800">Đang chế biến</span>`;
    case "Đang giao":
      return `<span class="px-2 py-0.5 text-xs font-bold rounded-full bg-purple-100 text-purple-700">Đang giao</span>`;
    case "Hoàn thành":
      return `<span class="px-2 py-0.5 text-xs font-bold rounded-full bg-emerald-100 text-emerald-700">Hoàn thành</span>`;
    case "Đã hủy":
      return `<span class="px-2 py-0.5 text-xs font-bold rounded-full bg-rose-100 text-rose-700">Đã hủy</span>`;
    default:
      return `<span class="px-2 py-0.5 text-xs font-bold rounded-full bg-stone-100 text-stone-700">${status}</span>`;
  }
}

function formatDate(dateStr) {
  if (!dateStr) return "Mới đây";
  try {
    const d = new Date(dateStr);
    return d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) + ' - ' + d.toLocaleDateString('vi-VN');
  } catch (_) {
    return dateStr;
  }
}

