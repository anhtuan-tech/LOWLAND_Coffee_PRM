import { db, collection, doc, updateDoc, onSnapshot } from "./config.js";

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
        ? `<button onclick="window.toggleUserBlock('${u.uid}', false)" class="text-xs font-semibold px-3 py-1.5 rounded-lg bg-emerald-50 text-emerald-700 hover:bg-emerald-100 transition">Mở khóa</button>`
        : `<button onclick="window.toggleUserBlock('${u.uid}', true)" class="text-xs font-semibold px-3 py-1.5 rounded-lg bg-rose-50 text-rose-600 hover:bg-rose-100 transition">Khóa tài khoản</button>`;

      html += `
        <tr class="border-b border-stone-100 hover:bg-stone-50 transition">
          <td class="py-3 px-4">
            <div class="w-10 h-10 rounded-full bg-amber-900 text-white font-bold flex items-center justify-center text-sm shadow-sm">
              ${(u.displayName || u.email || 'U')[0].toUpperCase()}
            </div>
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
 * Bật/Tắt chặn người dùng (isBlocked: true / false)
 */
window.toggleUserBlock = async function(uid, isBlocked) {
  try {
    const userRef = doc(db, "users", uid);
    await updateDoc(userRef, { isBlocked });
  } catch (err) {
    alert("Lỗi cập nhật trạng thái người dùng: " + err.message);
  }
};

