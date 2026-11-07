import { 
  db, 
  collection, 
  doc, 
  updateDoc, 
  onSnapshot, 
  query, 
  orderBy 
} from "./config.js?v=7";
import { formatVND } from "./dashboard.js?v=7";

let ordersList = [];
let currentFilter = "all";
let searchQuery = "";

/**
 * Khởi tạo quản lý Đơn hàng Realtime (POS Board)
 */
export function initOrders() {
  listenOrdersStream();
  setupFilterTabs();
  setupSearchInput();
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
    snapshot.forEach((docSnap) => {
      ordersList.push({ docId: docSnap.id, ...docSnap.data() });
    });

    updateOrderCounters();
    renderOrders();
  }, (err) => {
    console.error("Lỗi stream orders:", err);
  });
}

function updateOrderCounters() {
  const counts = {
    all: ordersList.length,
    "Mới nhận": 0,
    "Đang chế biến": 0,
    "Đang giao": 0,
    "Hoàn thành": 0,
    "Đã hủy": 0
  };

  ordersList.forEach((o) => {
    const st = o.status || "Mới nhận";
    if (counts[st] !== undefined) {
      counts[st]++;
    }
  });

  // Cập nhật 4 thẻ tóm tắt trên đầu
  const setTxt = (id, val) => {
    const el = document.getElementById(id);
    if (el) el.textContent = val;
  };

  setTxt("summary-new-orders", `${counts["Mới nhận"]} đơn`);
  setTxt("summary-prep-orders", `${counts["Đang chế biến"]} đơn`);
  setTxt("summary-ship-orders", `${counts["Đang giao"]} đơn`);
  setTxt("summary-done-orders", `${counts["Hoàn thành"]} đơn`);

  // Cập nhật huy hiệu số lượng trên các tab lọc
  setTxt("badge-count-all", counts.all);
  setTxt("badge-count-new", counts["Mới nhận"]);
  setTxt("badge-count-prep", counts["Đang chế biến"]);
  setTxt("badge-count-ship", counts["Đang giao"]);
  setTxt("badge-count-done", counts["Hoàn thành"]);
  setTxt("badge-count-cancel", counts["Đã hủy"]);
}

function setupFilterTabs() {
  const tabs = document.querySelectorAll(".order-filter-tab");
  tabs.forEach(tab => {
    tab.addEventListener("click", () => {
      tabs.forEach(t => {
        t.classList.remove("active-filter", "bg-amber-900", "text-white", "font-bold");
        t.classList.add("bg-white", "border", "border-stone-200", "text-stone-600", "font-medium");
      });

      tab.classList.remove("bg-white", "border", "border-stone-200", "text-stone-600", "font-medium");
      tab.classList.add("active-filter", "bg-amber-900", "text-white", "font-bold");

      currentFilter = tab.getAttribute("data-status");
      renderOrders();
    });
  });
}

function setupSearchInput() {
  const searchInput = document.getElementById("order-search-input");
  if (!searchInput) return;
  searchInput.addEventListener("input", (e) => {
    searchQuery = (e.target.value || "").trim().toLowerCase();
    renderOrders();
  });
}

function renderOrders() {
  const container = document.getElementById("orders-container");
  if (!container) return;

  const filtered = ordersList.filter(order => {
    const matchStatus = currentFilter === "all" || (order.status || "Mới nhận") === currentFilter;
    if (!matchStatus) return false;
    if (!searchQuery) return true;

    const code = (order.orderId || order.docId || "").toLowerCase();
    const customer = (order.userName || order.userId || "").toLowerCase();
    const phone = (order.receiverPhone || "").toLowerCase();
    const address = (order.deliveryAddress || "").toLowerCase();
    return (
      code.includes(searchQuery) ||
      customer.includes(searchQuery) ||
      phone.includes(searchQuery) ||
      address.includes(searchQuery)
    );
  });

  if (filtered.length === 0) {
    container.innerHTML = `
      <div class="col-span-full py-16 bg-white rounded-2xl border border-stone-200/80 text-center text-stone-400">
        <i class="fi fi-rr-inbox text-4xl mx-auto mb-3 block text-stone-300"></i>
        <p class="text-sm font-bold text-stone-600">Không tìm thấy đơn hàng nào phù hợp</p>
        <p class="text-xs text-stone-400 mt-1">Thử chuyển sang tab trạng thái khác hoặc xóa từ khóa tìm kiếm.</p>
      </div>
    `;
    return;
  }

  let html = "";
  filtered.forEach(order => {
    let items = order.items || [];
    if ((!items || items.length === 0) && order.itemsJson) {
      try {
        items = JSON.parse(order.itemsJson);
      } catch (_) {
        items = [];
      }
    }

    const status = order.status || "Mới nhận";
    const dateFormatted = formatDate(order.orderDate);
    const docId = order.docId;
    const displayId = order.orderId || docId.substring(0, 8);
    const topAccent = getCardTopAccent(status);

    html += `
      <div class="bg-white rounded-2xl border border-stone-200/90 ${topAccent} shadow-sm hover:shadow-md transition flex flex-col justify-between h-full overflow-hidden">
        
        <!-- PHẦN TRÊN: HEADER + STEPPER + THÔNG TIN KHÁCH + DANH SÁCH MÓN -->
        <div class="p-5 flex-1 flex flex-col">
          
          <!-- 1. Header đơn hàng -->
          <div class="flex items-start justify-between pb-3 border-b border-stone-100">
            <div>
              <div class="flex items-center space-x-2">
                <span class="font-black text-base text-amber-950 tracking-tight">#${displayId}</span>
                ${getStatusBadge(status)}
              </div>
              <p class="text-[11px] text-stone-400 font-medium mt-1 flex items-center space-x-1">
                <i class="fi fi-rr-clock-three text-[10px]"></i>
                <span>${dateFormatted}</span>
              </p>
            </div>
            <div class="text-right">
              <span class="text-[10px] font-bold uppercase tracking-wider text-stone-400 block">Tổng thanh toán</span>
              <span class="text-lg font-black text-amber-900">${formatVND(order.totalAmount)}</span>
            </div>
          </div>

          <!-- 2. Thanh tiến trình 4 bước trực quan -->
          ${renderOrderStepper(status)}

          <!-- 3. Khung thông tin Khách hàng, Giao nhận & Thanh toán -->
          <div class="text-xs text-stone-600 mb-3 bg-stone-50/90 p-3 rounded-xl space-y-1.5 border border-stone-200/60">
            <div class="flex items-center justify-between">
              <p class="font-bold text-stone-800 inline-flex items-center space-x-1.5">
                <i class="fi fi-rr-user text-amber-900"></i>
                <span>${order.userName || order.userId || "Khách vãng lai"}</span>
              </p>
              ${order.receiverPhone ? `<span class="font-bold text-amber-900 bg-amber-100/70 px-2 py-0.5 rounded-md inline-flex items-center space-x-1"><i class="fi fi-rr-phone-call text-[10px]"></i><span>${order.receiverPhone}</span></span>` : ''}
            </div>
            ${order.deliveryAddress ? `
              <p class="text-[11px] text-stone-600 leading-snug">
                <span class="font-bold text-stone-700"><i class="fi fi-rr-marker text-rose-600 mr-1"></i>${order.deliveryType || "Giao tận nơi"}:</span> ${order.deliveryAddress}
              </p>
            ` : ''}
            ${order.orderNote ? `
              <p class="text-[11px] font-semibold text-amber-900 bg-amber-50 border border-amber-200/70 px-2.5 py-1 rounded-lg">
                <i class="fi fi-rr-edit-alt mr-1"></i>Ghi chú Barista: <span class="font-normal">${order.orderNote}</span>
              </p>
            ` : ''}
            <div class="flex flex-wrap items-center justify-between gap-1 pt-1 border-t border-stone-200/50">
              <span class="inline-flex items-center space-x-1 px-2 py-0.5 rounded-md text-[10px] font-bold ${order.paymentMethod && order.paymentMethod.includes('VNPAY') ? 'bg-blue-100 text-blue-800 border border-blue-200' : 'bg-amber-100 text-amber-900 border border-amber-200'}">
                <i class="fi ${order.paymentMethod && order.paymentMethod.includes('VNPAY') ? 'fi-rr-credit-card' : 'fi-rr-money-bill-wave'}"></i>
                <span>${order.paymentMethod && order.paymentMethod.includes('VNPAY') ? 'VNPAY Sandbox (Đã TT)' : 'Tiền mặt (COD)'}</span>
              </span>
              ${order.voucherCode ? `
                <span class="inline-flex items-center space-x-1 px-2 py-0.5 rounded-md text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                  <i class="fi fi-rr-ticket"></i>
                  <span>${order.voucherCode} (-${formatVND(order.discount)})</span>
                </span>
              ` : ''}
            </div>
          </div>

          <!-- 4. Danh sách món đã đặt -->
          <div class="flex-1">
            <div class="text-[11px] font-bold text-stone-400 uppercase tracking-wider mb-1.5 flex justify-between">
              <span>Chi tiết món (${items.reduce((sum, i) => sum + (Number(i.quantity) || 1), 0)} ly/phần)</span>
              <span>Thành tiền</span>
            </div>
            <div class="space-y-2 max-h-44 overflow-y-auto pr-1">
              ${items.map(item => {
                let toppingsArr = [];
                if (Array.isArray(item.selectedToppings)) {
                  toppingsArr = item.selectedToppings;
                } else if (typeof item.selectedToppings === "string" && item.selectedToppings.trim().startsWith("[")) {
                  try {
                    toppingsArr = JSON.parse(item.selectedToppings);
                  } catch (_) {
                    toppingsArr = [];
                  }
                }
                return `
                  <div class="flex items-start justify-between text-xs py-1.5 border-b border-stone-100 last:border-0">
                    <div class="flex-1 pr-2">
                      <div class="flex items-center space-x-1.5">
                        <span class="px-1.5 py-0.5 bg-amber-900 text-white rounded text-[10px] font-black">${item.quantity}x</span>
                        <span class="font-bold text-stone-800">${item.name}</span>
                      </div>
                      <p class="text-[11px] text-stone-500 mt-0.5">
                        Size <b>${item.selectedSize || "S"}</b> • Đường ${item.selectedSugar ?? 100}% • Đá ${item.selectedIce ?? 100}%
                      </p>
                      ${toppingsArr.length > 0 ? `<p class="text-[10px] font-medium text-amber-800 mt-0.5">+ ${toppingsArr.join(', ')}</p>` : ''}
                    </div>
                    <span class="font-bold text-stone-800 whitespace-nowrap">${formatVND(item.totalPrice)}</span>
                  </div>
                `;
              }).join('')}
            </div>
          </div>
        </div>

        <!-- PHẦN DƯỚI CÙNG: THANH THAO TÁC DUYỆT ĐƠN 1-CHẠM (LUÔN CỐ ĐỊNH Ở ĐÁY THẺ) -->
        <div class="px-5 py-3.5 bg-stone-50/80 border-t border-stone-200/70">
          ${renderOrderActionFooter(docId, displayId, status)}
        </div>

      </div>
    `;
  });

  container.innerHTML = html;
  if (window.lucide) window.lucide.createIcons();
}

function getCardTopAccent(status) {
  switch (status) {
    case "Mới nhận":
      return "border-t-4 border-t-blue-500";
    case "Đang chế biến":
      return "border-t-4 border-t-amber-500";
    case "Đang giao":
      return "border-t-4 border-t-purple-500";
    case "Hoàn thành":
      return "border-t-4 border-t-emerald-500";
    case "Đã hủy":
      return "border-t-4 border-t-rose-500 opacity-80";
    default:
      return "border-t-4 border-t-stone-400";
  }
}

function renderOrderStepper(status) {
  if (status === "Đã hủy") {
    return `
      <div class="my-2.5 py-1.5 px-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-[11px] font-bold flex items-center justify-center space-x-1.5">
        <span>❌ Đơn hàng này đã bị hủy</span>
      </div>
    `;
  }

  const steps = ["Mới nhận", "Đang chế biến", "Đang giao", "Hoàn thành"];
  const labels = ["Nhận đơn", "Pha chế", "Giao món", "Hoàn tất"];
  const currentIdx = Math.max(0, steps.indexOf(status));

  return `
    <div class="my-3 grid grid-cols-4 gap-1">
      ${steps.map((st, idx) => {
        const isDone = idx <= currentIdx;
        const barColor = isDone
          ? (currentIdx === 3 ? "bg-emerald-500" : "bg-amberLow")
          : "bg-stone-200";
        const textColor = isDone ? "text-stone-800 font-bold" : "text-stone-400 font-medium";
        return `
          <div class="flex flex-col items-center">
            <div class="w-full h-1.5 rounded-full ${barColor} transition-all"></div>
            <span class="text-[10px] ${textColor} mt-1">${labels[idx]}</span>
          </div>
        `;
      }).join('')}
    </div>
  `;
}

function renderOrderActionFooter(docId, displayId, status) {
  if (status === "Mới nhận") {
    return `
      <div class="flex items-center justify-between gap-2">
        <button onclick="window.updateOrderStatus('${docId}', 'Đang chế biến', '${displayId}')"
                class="flex-1 py-2 px-3 bg-coffee hover:bg-coffee-dark text-white rounded-xl text-xs font-bold shadow-sm transition flex items-center justify-center space-x-1.5">
          <i class="fi fi-sr-mug-hot-alt"></i>
          <span>Nhận đơn & Pha chế</span>
        </button>
        <button onclick="window.updateOrderStatus('${docId}', 'Đã hủy', '${displayId}')"
                class="py-2 px-3 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 rounded-xl text-xs font-bold transition inline-flex items-center space-x-1">
          <i class="fi fi-rr-cross-small"></i>
          <span>Hủy đơn</span>
        </button>
      </div>
    `;
  }

  if (status === "Đang chế biến") {
    return `
      <div class="flex items-center justify-between gap-2">
        <button onclick="window.updateOrderStatus('${docId}', 'Đang giao', '${displayId}')"
                class="flex-1 py-2 px-3 bg-purple-600 hover:bg-purple-700 text-white rounded-xl text-xs font-bold shadow-sm transition flex items-center justify-center space-x-1.5">
          <i class="fi fi-sr-moped"></i>
          <span>Giao hàng / Trả món</span>
        </button>
        <button onclick="window.updateOrderStatus('${docId}', 'Đã hủy', '${displayId}')"
                class="py-2 px-3 bg-rose-50 hover:bg-rose-100 text-rose-700 border border-rose-200 rounded-xl text-xs font-bold transition">
          Hủy
        </button>
      </div>
    `;
  }

  if (status === "Đang giao") {
    return `
      <div class="flex items-center justify-between gap-2">
        <button onclick="window.updateOrderStatus('${docId}', 'Hoàn thành', '${displayId}')"
                class="flex-1 py-2 px-3 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold shadow-sm transition flex items-center justify-center space-x-1.5">
          <i class="fi fi-sr-check-circle"></i>
          <span>Xác nhận Hoàn thành</span>
        </button>
        <select onchange="window.updateOrderStatus('${docId}', this.value, '${displayId}')"
                class="text-[11px] font-semibold rounded-xl border border-stone-300 py-1.5 px-2 bg-white text-stone-600 outline-none">
          <option value="Đang giao" selected>Khác...</option>
          <option value="Đang chế biến">Quay lại Pha chế</option>
          <option value="Đã hủy">Hủy đơn</option>
        </select>
      </div>
    `;
  }

  // Khi đơn đã Hoàn thành hoặc Đã hủy: Hiển thị trạng thái khóa gọn gàng kèm nút chỉnh lại nếu cần
  return `
    <div class="flex items-center justify-between">
      <span class="text-xs font-bold inline-flex items-center space-x-1.5 ${status === 'Hoàn thành' ? 'text-emerald-700' : 'text-rose-700'}">
        <i class="fi ${status === 'Hoàn thành' ? 'fi-sr-badge-check' : 'fi-sr-ban'}"></i>
        <span>${status === 'Hoàn thành' ? 'Đơn hàng đã hoàn tất' : 'Đơn hàng đã hủy'}</span>
      </span>
      <select onchange="window.updateOrderStatus('${docId}', this.value, '${displayId}')" 
              class="text-[11px] font-semibold rounded-lg border border-stone-200 py-1 px-2 bg-white text-stone-500 hover:border-stone-300 outline-none">
        <option value="${status}" selected>Đổi trạng thái...</option>
        <option value="Mới nhận">Mới nhận</option>
        <option value="Đang chế biến">Đang chế biến</option>
        <option value="Đang giao">Đang giao</option>
        <option value="Hoàn thành">Hoàn thành</option>
        <option value="Đã hủy">Đã hủy</option>
      </select>
    </div>
  `;
}

/**
 * Cập nhật trạng thái đơn hàng trực tiếp lên Cloud Firestore (Kèm Toast & Confirm Modal)
 */
window.updateOrderStatus = async function(docId, newStatus, displayId = "") {
  const orderLabel = displayId ? `#${displayId}` : `#${docId.substring(0, 8)}`;

  if (newStatus === "Đã hủy" && window.showConfirmModal) {
    const confirmed = await window.showConfirmModal({
      title: `Hủy đơn hàng ${orderLabel}?`,
      message: `Bạn có chắc chắn muốn chuyển đơn hàng ${orderLabel} sang trạng thái "Đã hủy"?`,
      confirmText: "Xác nhận hủy đơn",
      cancelText: "Quay lại",
      type: "danger"
    });
    if (!confirmed) {
      renderOrders();
      return;
    }
  }

  try {
    const orderRef = doc(db, "orders", docId);
    await updateDoc(orderRef, {
      status: newStatus,
      updatedAt: new Date().toISOString()
    });
    if (window.showToast) {
      const toastType = newStatus === "Đã hủy" ? "warning" : "success";
      window.showToast(
        `Đơn hàng ${orderLabel} đã chuyển sang trạng thái "${newStatus}".`,
        toastType,
        "Cập nhật đơn hàng"
      );
    }
  } catch (err) {
    if (window.showToast) {
      window.showToast("Không thể cập nhật trạng thái đơn: " + err.message, "error", "Lỗi cập nhật");
    }
  }
};

function getStatusBadge(status) {
  switch (status) {
    case "Mới nhận":
      return `<span class="px-2.5 py-0.5 text-[11px] font-bold rounded-full bg-blue-100 text-blue-700">Mới nhận</span>`;
    case "Đang chế biến":
      return `<span class="px-2.5 py-0.5 text-[11px] font-bold rounded-full bg-amber-100 text-amber-800">Đang chế biến</span>`;
    case "Đang giao":
      return `<span class="px-2.5 py-0.5 text-[11px] font-bold rounded-full bg-purple-100 text-purple-700">Đang giao</span>`;
    case "Hoàn thành":
      return `<span class="px-2.5 py-0.5 text-[11px] font-bold rounded-full bg-emerald-100 text-emerald-700">Hoàn thành</span>`;
    case "Đã hủy":
      return `<span class="px-2.5 py-0.5 text-[11px] font-bold rounded-full bg-rose-100 text-rose-700">Đã hủy</span>`;
    default:
      return `<span class="px-2.5 py-0.5 text-[11px] font-bold rounded-full bg-stone-100 text-stone-700">${status}</span>`;
  }
}

function formatDate(dateStr) {
  if (!dateStr) return "Mới đây";
  try {
    const d = new Date(dateStr);
    return (
      d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false }) +
      ' - ' +
      d.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' })
    );
  } catch (_) {
    return dateStr;
  }
}
