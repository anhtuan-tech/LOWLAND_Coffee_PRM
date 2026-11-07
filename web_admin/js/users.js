import { db, collection, doc, updateDoc, onSnapshot } from "./config.js?v=7";

/**
 * Khởi tạo quản lý khách hàng & tài khoản
 */
export function initUsers() {
  listenUsersStream();
}

function listenUsersStream() {
  const tableBody = document.getElementById("users-table-body");
  if (!tableBody) return;

  onSnapshot(collection(db, "users"), (snapshot) => {
    if (snapshot.empty) {
      tableBody.innerHTML = `
        <tr>
          <td colspan="6" class="py-12 text-center text-stone-400">
            Chưa có tài khoản nào được ghi nhận trong Firestore.
          </td>
        </tr>
      `;
      return;
    }

    let html = "";
    snapshot.forEach((docSnap) => {
      const u = { uid: docSnap.id, ...docSnap.data() };
      const isBlocked = u.isBlocked === true;
      const isAdmin = u.role === "admin";

      const roleBadge = isAdmin
        ? `<span class="px-2.5 py-1 text-xs font-bold rounded-lg bg-amber-100 text-amber-900 border border-amber-300">Admin</span>`
        : `<span class="px-2.5 py-1 text-xs font-medium rounded-lg bg-stone-100 text-stone-700">Khách hàng</span>`;

      const statusBadge = isBlocked
        ? `<span class="px-2.5 py-1 text-xs font-bold rounded-full bg-rose-100 text-rose-700">Đã khóa</span>`
        : `<span class="px-2.5 py-1 text-xs font-bold rounded-full bg-emerald-100 text-emerald-700">Hoạt động</span>`;

      const toggleAction = isBlocked
        ? `<button onclick="window.toggleUserBlock('${u.uid}', false)" class="text-xs font-semibold px-3 py-1.5 rounded-lg bg-emerald-50 text-emerald-700 hover:bg-emerald-100 transition inline-flex items-center space-x-1"><i class="fi fi-rr-unlock text-xs"></i><span>Mở khóa</span></button>`
        : `<button onclick="window.toggleUserBlock('${u.uid}', true)" class="text-xs font-semibold px-3 py-1.5 rounded-lg bg-rose-50 text-rose-600 hover:bg-rose-100 transition inline-flex items-center space-x-1"><i class="fi fi-rr-lock text-xs"></i><span>Khóa tài khoản</span></button>`;

      const avatarHtml = u.photoUrl
        ? `<img src="${u.photoUrl}" alt="${u.displayName || 'User'}" class="w-10 h-10 rounded-full object-cover shadow-sm border border-stone-200" />`
        : `<div class="w-10 h-10 rounded-full bg-amber-900 text-white font-bold flex items-center justify-center text-sm shadow-sm">
             ${(u.displayName || u.email || 'U')[0].toUpperCase()}
           </div>`;

      html += `
        <tr class="border-b border-stone-100 hover:bg-stone-50 transition">
          <td class="py-3 px-4">
            ${avatarHtml}
          </td>
          <td class="py-3 px-4 font-semibold text-stone-800">${u.displayName || "Chưa đặt tên"}</td>
          <td class="py-3 px-4 text-stone-600">${u.email || "Không có email"}</td>
          <td class="py-3 px-4">${roleBadge}</td>
          <td class="py-3 px-4">${statusBadge}</td>
          <td class="py-3 px-4 text-right">
            ${isAdmin ? `<span class="text-xs text-stone-400 italic">Không khả dụng</span>` : toggleAction}
          </td>
        </tr>
      `;
    });

    tableBody.innerHTML = html;
  });
}

/**
 * Bật/Tắt chặn người dùng (isBlocked: true / false) kèm Toast & Confirm Modal
 */
window.toggleUserBlock = async function(uid, isBlocked) {
  if (isBlocked && window.showConfirmModal) {
    const confirmed = await window.showConfirmModal({
      title: "Khóa tài khoản khách hàng?",
      message: "Khách hàng này sẽ tạm thời không thể đăng nhập và đặt đơn trên ứng dụng.",
      confirmText: "Khóa tài khoản",
      cancelText: "Hủy",
      type: "danger"
    });
    if (!confirmed) return;
  }

  try {
    const userRef = doc(db, "users", uid);
    await updateDoc(userRef, { isBlocked });
    if (window.showToast) {
      window.showToast(
        isBlocked ? "Đã khóa quyền truy cập của tài khoản khách hàng." : "Đã mở khóa tài khoản khách hàng thành công!",
        isBlocked ? "warning" : "success",
        "Quản lý Khách hàng"
      );
    }
  } catch (err) {
    if (window.showToast) {
      window.showToast("Lỗi cập nhật trạng thái người dùng: " + err.message, "error");
    }
  }
};

