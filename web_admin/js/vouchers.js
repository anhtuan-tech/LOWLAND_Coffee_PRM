import { 
  db, 
  collection, 
  doc, 
  getDocs, 
  setDoc, 
  addDoc, 
  updateDoc,
  deleteDoc, 
  onSnapshot 
} from "./config.js?v=9";
import { formatVND } from "./dashboard.js?v=9";

/**
 * Khởi tạo quản lý Mã giảm giá (Vouchers)
 */
export function initVouchers() {
  listenVouchersStream();
  setupVoucherForm();
}

function parseVoucherEndOfDay(expiryRaw) {
  if (!expiryRaw) return null;
  const d = new Date(expiryRaw);
  if (isNaN(d.getTime())) return null;
  if (d.getHours() === 0 && d.getMinutes() === 0 && d.getSeconds() === 0) {
    d.setHours(23, 59, 59, 999);
  }
  return d;
}

let currentVouchersMap = {};

function listenVouchersStream() {
  const tableBody = document.getElementById("vouchers-table-body");
  if (!tableBody) return;

  onSnapshot(collection(db, "vouchers"), (snapshot) => {
    if (snapshot.empty) {
      seedDefaultVouchersIfEmpty();
      return;
    }

    const list = [];
    currentVouchersMap = {};
    snapshot.forEach((docSnap) => {
      const data = { id: docSnap.id, ...docSnap.data() };
      list.push(data);
      currentVouchersMap[docSnap.id] = data;
    });

    // Sắp xếp voucher còn hạn lên trên, hết hạn xuống dưới
    list.sort((a, b) => {
      const expA = parseVoucherEndOfDay(a.expiryDate);
      const expB = parseVoucherEndOfDay(b.expiryDate);
      const now = new Date();
      const isExpA = expA ? now > expA : false;
      const isExpB = expB ? now > expB : false;
      if (isExpA !== isExpB) return isExpA ? 1 : -1;
      return (expA?.getTime() || 0) - (expB?.getTime() || 0);
    });

    let html = "";
    const now = new Date();

    list.forEach((v) => {
      const upperCode = (v.code || "").toUpperCase();
      const descLower = (v.description || "").toLowerCase();
      const isFirstOrder =
        typeof v.onlyFirstOrder === "boolean"
          ? v.onlyFirstOrder
          : upperCode === "LOWLANDNEW" || descLower.includes("đơn hàng đầu tiên");
      const isOncePerUser =
        typeof v.oncePerUser === "boolean" ? v.oncePerUser : isFirstOrder;
      const category =
        v.applicableCategory || (upperCode === "TRAXANH15" ? "Trà & Bánh" : "all");

      const isPercent = v.type === "percentage";
      const valueLabel = isPercent
        ? `${v.discountValue}% ${v.maxDiscount ? `(Tối đa ${formatVND(v.maxDiscount)})` : ''}`
        : formatVND(v.discountValue);

      const expDate = parseVoucherEndOfDay(v.expiryDate);
      const isExpired = expDate ? now > expDate : false;
      const remainingDays = expDate
        ? Math.max(0, Math.ceil((expDate.getTime() - now.getTime()) / (1000 * 3600 * 24)))
        : 30;

      const expiryFormatted = expDate
        ? expDate.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' })
        : "Không giới hạn";

      const statusBadge = isExpired
        ? `<span class="px-2.5 py-1 text-xs font-bold rounded-full bg-rose-100 text-rose-700 border border-rose-200 inline-flex items-center space-x-1">
             <i class="fi fi-sr-cross-circle text-[10px]"></i>
             <span>Đã kết thúc (Khóa)</span>
           </span>`
        : `<span class="px-2.5 py-1 text-xs font-bold rounded-full bg-emerald-100 text-emerald-700 border border-emerald-200 inline-flex items-center space-x-1">
             <i class="fi fi-sr-check-circle text-[10px]"></i>
             <span>Đang chạy (Còn ${remainingDays} ngày)</span>
           </span>`;

      // Các nhãn điều kiện đa dạng (Flaticon UIcons)
      let conditionBadges = "";
      if (isFirstOrder) {
        conditionBadges += `<span class="inline-flex items-center space-x-1 px-2 py-0.5 text-[10px] font-bold rounded-md bg-orange-100 text-orange-800 mr-1 mt-1"><i class="fi fi-sr-sparkles"></i><span>Đơn đầu tiên</span></span>`;
      } else if (isOncePerUser) {
        conditionBadges += `<span class="inline-flex items-center space-x-1 px-2 py-0.5 text-[10px] font-bold rounded-md bg-blue-100 text-blue-800 mr-1 mt-1"><i class="fi fi-rr-user"></i><span>1 lần/khách</span></span>`;
      } else {
        conditionBadges += `<span class="inline-flex items-center space-x-1 px-2 py-0.5 text-[10px] font-bold rounded-md bg-stone-100 text-stone-600 mr-1 mt-1"><i class="fi fi-rr-refresh"></i><span>Dùng nhiều lần</span></span>`;
      }

      if (category && category !== "all") {
        conditionBadges += `<span class="inline-flex items-center space-x-1 px-2 py-0.5 text-[10px] font-bold rounded-md bg-amber-100 text-amber-900 mr-1 mt-1"><i class="fi fi-rr-mug-hot-alt"></i><span>Nhóm: ${category}</span></span>`;
      }
      if (v.usageLimit) {
        conditionBadges += `<span class="inline-flex items-center space-x-1 px-2 py-0.5 text-[10px] font-bold rounded-md bg-purple-100 text-purple-800 mt-1"><i class="fi fi-rr-ticket"></i><span>Giới hạn: ${v.usedCount || 0}/${v.usageLimit} lượt</span></span>`;
      }

      html += `
        <tr class="border-b border-stone-100 hover:bg-stone-50 transition ${isExpired ? 'bg-stone-50/70 opacity-75' : ''}">
          <td class="py-3 px-4 font-mono font-bold text-amber-900 tracking-wider">
            <span class="px-2.5 py-1 ${isExpired ? 'bg-stone-200 text-stone-600 border-stone-300 line-through' : 'bg-amber-50 border-amber-200 text-amber-900'} border rounded-lg">${v.code}</span>
          </td>
          <td class="py-3 px-4">
            <div class="font-bold text-stone-800">${v.title || v.code}</div>
            ${v.description ? `<div class="text-[11px] text-stone-400">${v.description}</div>` : ''}
            <div>${conditionBadges}</div>
          </td>
          <td class="py-3 px-4 font-bold ${isExpired ? 'text-stone-500' : 'text-emerald-700'}">${valueLabel}</td>
          <td class="py-3 px-4 text-stone-600 text-xs font-semibold">${formatVND(v.minOrderValue)}</td>
          <td class="py-3 px-4 text-xs font-semibold ${isExpired ? 'text-rose-600' : 'text-stone-600'}">${expiryFormatted}</td>
          <td class="py-3 px-4">${statusBadge}</td>
          <td class="py-3 px-4 text-right space-x-1 whitespace-nowrap">
            ${isExpired ? `
              <button onclick="window.extendVoucherExpiry('${v.id}', '${v.code}')"
                      class="px-2.5 py-1.5 text-[11px] font-bold bg-amber-100 text-amber-900 hover:bg-amber-200 rounded-lg transition"
                      title="Gia hạn thêm 15 ngày">
                +15 ngày
              </button>
            ` : ''}
            <button onclick="window.openEditVoucherModal('${v.id}')" class="p-2 text-stone-500 hover:text-amber-800 hover:bg-amber-50 rounded-lg transition" title="Chỉnh sửa mã">
              <i class="fi fi-rr-edit text-sm"></i>
            </button>
            <button onclick="window.deleteVoucher('${v.id}', '${v.code}')" class="p-2 text-stone-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition" title="Xóa mã">
              <i class="fi fi-rr-trash text-sm"></i>
            </button>
          </td>
        </tr>
      `;
    });

    tableBody.innerHTML = html;
  });
}

async function seedDefaultVouchersIfEmpty() {
  const defaults = [
    {
      code: "LOWLANDNEW",
      title: "Chào bạn mới LOWLAND",
      description: "Giảm 20% cho đơn hàng đầu tiên (Tối đa 40.000đ)",
      type: "percentage",
      discountValue: 20,
      maxDiscount: 40000,
      minOrderValue: 40000,
      onlyFirstOrder: true,
      oncePerUser: true,
      applicableCategory: "all",
      expiryDate: new Date(Date.now() + 30 * 24 * 3600 * 1000).toISOString()
    },
    {
      code: "GIAM20K",
      title: "Ưu đãi cà phê sáng",
      description: "Giảm ngay 20.000đ cho đơn hàng từ 70.000đ",
      type: "fixed",
      discountValue: 20000,
      minOrderValue: 70000,
      onlyFirstOrder: false,
      oncePerUser: false,
      applicableCategory: "all",
      expiryDate: new Date(Date.now() + 15 * 24 * 3600 * 1000).toISOString()
    },
    {
      code: "TRAXANH15",
      title: "Tuần lễ Trà & Bánh",
      description: "Giảm 15% cho mọi hóa đơn có trà hoặc bánh",
      type: "percentage",
      discountValue: 15,
      maxDiscount: 30000,
      minOrderValue: 50000,
      onlyFirstOrder: false,
      oncePerUser: false,
      applicableCategory: "Trà & Bánh",
      expiryDate: new Date(Date.now() + 10 * 24 * 3600 * 1000).toISOString()
    }
  ];

  for (const v of defaults) {
    await addDoc(collection(db, "vouchers"), v);
  }
}

/**
 * Điền nhanh mẫu Voucher trên Modal tạo mới
 */
window.applyVoucherTemplate = function(templateKey) {
  const setVal = (id, val) => {
    const el = document.getElementById(id);
    if (el) el.value = val;
  };
  const setCheck = (id, checked) => {
    const el = document.getElementById(id);
    if (el) el.checked = checked;
  };

  if (templateKey === "first_order") {
    setVal("v-code", "LOWLANDNEW");
    setVal("v-type", "percentage");
    setVal("v-title", "Chào bạn mới LOWLAND");
    setVal("v-desc", "Giảm 20% cho đơn hàng đầu tiên (Tối đa 40.000đ)");
    setVal("v-value", 20);
    setVal("v-min-order", 40000);
    setVal("v-max-discount", 40000);
    setVal("v-category", "all");
    setVal("v-usage-limit", "");
    setCheck("v-only-first-order", true);
    setCheck("v-once-per-user", true);
  } else if (templateKey === "coffee_morning") {
    setVal("v-code", "CAFE15K");
    setVal("v-type", "fixed");
    setVal("v-title", "Bữa sáng tỉnh táo cùng Phin");
    setVal("v-desc", "Giảm ngay 15.000đ cho đơn có món Cà phê từ 45.000đ");
    setVal("v-value", 15000);
    setVal("v-min-order", 45000);
    setVal("v-max-discount", "");
    setVal("v-category", "Cà phê");
    setVal("v-usage-limit", 100);
    setCheck("v-only-first-order", false);
    setCheck("v-once-per-user", true);
  } else if (templateKey === "tea_cake") {
    setVal("v-code", "TRABANH15");
    setVal("v-type", "percentage");
    setVal("v-title", "Chiều thư giãn Trà & Bánh");
    setVal("v-desc", "Giảm 15% (tối đa 30.000đ) cho hóa đơn có Trà hoặc Bánh");
    setVal("v-value", 15);
    setVal("v-min-order", 50000);
    setVal("v-max-discount", 30000);
    setVal("v-category", "Trà & Bánh");
    setVal("v-usage-limit", "");
    setCheck("v-only-first-order", false);
    setCheck("v-once-per-user", false);
  } else if (templateKey === "vip_party") {
    setVal("v-code", "PARTY35K");
    setVal("v-type", "fixed");
    setVal("v-title", "Tiệc trà hội nhóm giảm sâu");
    setVal("v-desc", "Giảm ngay 35.000đ cho đơn hàng nhóm từ 150.000đ");
    setVal("v-value", 35000);
    setVal("v-min-order", 150000);
    setVal("v-max-discount", "");
    setVal("v-category", "all");
    setVal("v-usage-limit", 50);
    setCheck("v-only-first-order", false);
    setCheck("v-once-per-user", false);
  }

  if (window.showToast) {
    window.showToast("Đã điền sẵn mẫu chiến dịch ưu đãi! Bạn có thể tùy chỉnh thêm trước khi bấm Phát hành.", "info", "Đã nạp mẫu");
  }
};

window.extendVoucherExpiry = async function(id, code) {
  try {
    const newExpiry = new Date(Date.now() + 15 * 24 * 3600 * 1000);
    newExpiry.setHours(23, 59, 59, 999);
    await updateDoc(doc(db, "vouchers", id), {
      expiryDate: newExpiry.toISOString()
    });
    if (window.showToast) {
      window.showToast(`Đã gia hạn mã "${code}" thêm 15 ngày hoạt động!`, "success", "Gia hạn thành công");
    }
  } catch (err) {
    if (window.showToast) {
      window.showToast("Lỗi khi gia hạn voucher: " + err.message, "error");
    }
  }
};

window.deleteVoucher = async function(id, code = "") {
  const confirmed = window.showConfirmModal
    ? await window.showConfirmModal({
        title: `Xóa mã giảm giá ${code ? `"${code}"` : ""}?`,
        message: "Mã giảm giá này sẽ bị gỡ khỏi hệ thống và khách hàng không thể áp dụng nữa.",
        confirmText: "Xóa mã ngay",
        cancelText: "Hủy",
        type: "danger"
      })
    : true;
  if (!confirmed) return;

  try {
    await deleteDoc(doc(db, "vouchers", id));
    if (window.showToast) {
      window.showToast(`Đã xóa mã ưu đãi ${code} khỏi hệ thống.`, "success", "Đã xóa Voucher");
    }
  } catch (err) {
    if (window.showToast) {
      window.showToast("Lỗi khi xóa voucher: " + err.message, "error");
    }
  }
};

window.openAddVoucherModal = function() {
  const form = document.getElementById("voucher-form");
  if (form) form.reset();

  const idInput = document.getElementById("v-id");
  if (idInput) idInput.value = "";
  const titleEl = document.getElementById("voucher-modal-title");
  if (titleEl) titleEl.textContent = "Phát hành Mã ưu đãi (Voucher) mới";

  const expiryInput = document.getElementById("v-expiry");
  if (expiryInput) {
    const todayStr = new Date().toISOString().split("T")[0];
    const defaultFuture = new Date(Date.now() + 15 * 24 * 3600 * 1000).toISOString().split("T")[0];
    expiryInput.min = todayStr;
    expiryInput.value = defaultFuture;
  }

  document.getElementById("voucher-modal").classList.remove("hidden");
};

window.openEditVoucherModal = function(id) {
  const v = currentVouchersMap[id];
  if (!v) return;

  const form = document.getElementById("voucher-form");
  if (form) form.reset();

  const idInput = document.getElementById("v-id");
  if (idInput) idInput.value = id;
  const titleEl = document.getElementById("voucher-modal-title");
  if (titleEl) titleEl.textContent = `Chỉnh sửa Mã ưu đãi: ${v.code || ""}`;

  const setVal = (elId, val) => {
    const el = document.getElementById(elId);
    if (el) el.value = val ?? "";
  };
  const setCheck = (elId, checked) => {
    const el = document.getElementById(elId);
    if (el) el.checked = Boolean(checked);
  };

  setVal("v-code", v.code || "");
  setVal("v-type", v.type || "percentage");
  setVal("v-title", v.title || "");
  setVal("v-desc", v.description || "");
  setVal("v-value", v.discountValue ?? "");
  setVal("v-min-order", v.minOrderValue ?? 0);
  setVal("v-max-discount", v.maxDiscount ?? "");
  setVal("v-category", v.applicableCategory || "all");
  setVal("v-usage-limit", v.usageLimit ?? "");

  const upperCode = (v.code || "").toUpperCase();
  const isFirstOrder =
    typeof v.onlyFirstOrder === "boolean" ? v.onlyFirstOrder : upperCode === "LOWLANDNEW";
  const isOncePerUser =
    typeof v.oncePerUser === "boolean" ? v.oncePerUser : isFirstOrder;

  setCheck("v-only-first-order", isFirstOrder);
  setCheck("v-once-per-user", isOncePerUser);

  if (v.expiryDate) {
    const d = new Date(v.expiryDate);
    if (!isNaN(d.getTime())) {
      setVal("v-expiry", d.toISOString().split("T")[0]);
    }
  }

  document.getElementById("voucher-modal").classList.remove("hidden");
};

window.closeVoucherModal = function() {
  document.getElementById("voucher-modal").classList.add("hidden");
};

function setupVoucherForm() {
  const form = document.getElementById("voucher-form");
  if (!form) return;

  // Khi tích chọn "Đơn hàng đầu tiên", tự động tích luôn "Mỗi tài khoản chỉ dùng 1 lần"
  const firstOrderCheck = document.getElementById("v-only-first-order");
  const onceUserCheck = document.getElementById("v-once-per-user");
  if (firstOrderCheck && onceUserCheck) {
    firstOrderCheck.addEventListener("change", () => {
      if (firstOrderCheck.checked) {
        onceUserCheck.checked = true;
      }
    });
  }

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const btn = form.querySelector("button[type=submit]");
    btn.disabled = true;

    try {
      const code = document.getElementById("v-code").value.trim().toUpperCase();
      const title = document.getElementById("v-title").value.trim();
      const description = document.getElementById("v-desc").value.trim();
      const type = document.getElementById("v-type").value;
      const discountValue = parseFloat(document.getElementById("v-value").value) || 0;
      const minOrderValue = parseFloat(document.getElementById("v-min-order").value) || 0;
      const maxDiscount = document.getElementById("v-max-discount").value
        ? parseFloat(document.getElementById("v-max-discount").value)
        : null;
      const applicableCategory = document.getElementById("v-category")?.value || "all";
      const usageLimitRaw = document.getElementById("v-usage-limit")?.value;
      const usageLimit = usageLimitRaw ? parseInt(usageLimitRaw, 10) : null;
      const onlyFirstOrder = document.getElementById("v-only-first-order")?.checked || false;
      const oncePerUser = onlyFirstOrder || (document.getElementById("v-once-per-user")?.checked ?? true);

      const rawExpiryVal = document.getElementById("v-expiry").value;
      let expiryDateObj;
      if (rawExpiryVal) {
        expiryDateObj = new Date(rawExpiryVal + "T23:59:59");
      } else {
        expiryDateObj = new Date(Date.now() + 30 * 24 * 3600 * 1000);
        expiryDateObj.setHours(23, 59, 59, 999);
      }

      if (expiryDateObj < new Date()) {
        if (window.showToast) {
          window.showToast("Ngày hết hạn không được nhỏ hơn thời gian hiện tại!", "warning", "Ngày hết hạn không hợp lệ");
        }
        btn.disabled = false;
        return;
      }

      const existingId = document.getElementById("v-id")?.value?.trim();
      const payload = {
        code,
        title,
        description,
        type,
        discountValue,
        minOrderValue,
        maxDiscount,
        applicableCategory,
        usageLimit,
        onlyFirstOrder,
        oncePerUser,
        expiryDate: expiryDateObj.toISOString(),
        updatedAt: new Date().toISOString()
      };

      if (existingId) {
        await updateDoc(doc(db, "vouchers", existingId), payload);
      } else {
        await addDoc(collection(db, "vouchers"), {
          ...payload,
          usedCount: 0,
          createdAt: new Date().toISOString()
        });
      }

      window.closeVoucherModal();
      if (window.showToast) {
        window.showToast(
          existingId
            ? `Đã cập nhật mã ưu đãi "${code}" thành công!`
            : `Đã phát hành mã ưu đãi "${code}" thành công!`,
          "success",
          existingId ? "Cập nhật Voucher" : "Phát hành Voucher"
        );
      }
    } catch (err) {
      if (window.showToast) {
        window.showToast("Lỗi tạo mã giảm giá: " + err.message, "error");
      }
    } finally {
      btn.disabled = false;
    }
  });
}
