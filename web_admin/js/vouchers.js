import { 
  db, 
  collection, 
  doc, 
  getDocs, 
  setDoc, 
  addDoc, 
  deleteDoc, 
  onSnapshot 
} from "./config.js";
import { formatVND } from "./dashboard.js";

/**
 * Khởi tạo quản lý Mã giảm giá (Vouchers)
 */
export function initVouchers() {
  listenVouchersStream();
  setupVoucherForm();
}

function listenVouchersStream() {
  const tableBody = document.getElementById("vouchers-table-body");
  if (!tableBody) return;

  onSnapshot(collection(db, "vouchers"), (snapshot) => {
    if (snapshot.empty) {
      seedDefaultVouchersIfEmpty();
      return;
    }

    let html = "";
    snapshot.forEach((docSnap) => {
      const v = { id: docSnap.id, ...docSnap.data() };
      const isPercent = v.type === "percentage";
      const valueLabel = isPercent ? `${v.discountValue}%` : formatVND(v.discountValue);
      const expiryFormatted = v.expiryDate ? new Date(v.expiryDate).toLocaleDateString('vi-VN') : "Không giới hạn";

      html += `
        <tr class="border-b border-stone-100 hover:bg-stone-50 transition">
          <td class="py-3 px-4 font-mono font-bold text-amber-900 tracking-wider">
            <span class="px-2.5 py-1 bg-amber-50 border border-amber-200 rounded-lg">${v.code}</span>
          </td>
          <td class="py-3 px-4 font-semibold text-stone-800">${v.title || v.code}</td>
          <td class="py-3 px-4 font-bold text-emerald-700">${valueLabel}</td>
          <td class="py-3 px-4 text-stone-600 text-xs">${formatVND(v.minOrderValue)}</td>
          <td class="py-3 px-4 text-stone-500 text-xs">${expiryFormatted}</td>
          <td class="py-3 px-4 text-right">
            <button onclick="window.deleteVoucher('${v.id}')" class="p-2 text-stone-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition" title="Xóa mã">
              <i data-lucide="trash-2" class="w-4 h-4"></i>
            </button>
          </td>
        </tr>
      `;
    });

    tableBody.innerHTML = html;
    if (window.lucide) window.lucide.createIcons();
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
      expiryDate: new Date(Date.now() + 30 * 24 * 3600 * 1000).toISOString()
    },
    {
      code: "GIAM20K",
      title: "Ưu đãi cà phê sáng",
      description: "Giảm ngay 20.000đ cho đơn hàng từ 70.000đ",
      type: "fixed",
      discountValue: 20000,
      minOrderValue: 70000,
      expiryDate: new Date(Date.now() + 15 * 24 * 3600 * 1000).toISOString()
    }
  ];

  for (const v of defaults) {
    await addDoc(collection(db, "vouchers"), v);
  }
}

window.deleteVoucher = async function(id) {
  if (!confirm("Bạn có chắc chắn muốn xóa mã giảm giá này?")) return;
  try {
    await deleteDoc(doc(db, "vouchers", id));
  } catch (err) {
    alert("Lỗi khi xóa voucher: " + err.message);
  }
};

window.openAddVoucherModal = function() {
  document.getElementById("voucher-form").reset();
  document.getElementById("voucher-modal").classList.remove("hidden");
};

window.closeVoucherModal = function() {
  document.getElementById("voucher-modal").classList.add("hidden");
};

function setupVoucherForm() {
  const form = document.getElementById("voucher-form");
  if (!form) return;

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
      const expiryDate = document.getElementById("v-expiry").value
        ? new Date(document.getElementById("v-expiry").value).toISOString()
        : new Date(Date.now() + 30 * 24 * 3600 * 1000).toISOString();

      await addDoc(collection(db, "vouchers"), {
        code,
        title,
        description,
        type,
        discountValue,
        minOrderValue,
        maxDiscount,
        expiryDate,
        createdAt: new Date().toISOString()
      });

      window.closeVoucherModal();
    } catch (err) {
      alert("Lỗi tạo mã giảm giá: " + err.message);
    } finally {
      btn.disabled = false;
    }
  });
}

