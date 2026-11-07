import {
  db,
  collection,
  doc,
  getDocs,
  setDoc,
  addDoc,
  updateDoc,
  deleteDoc,
  onSnapshot,
  getCloudinaryCredentials,
  uploadToCloudinary
} from "./config.js?v=10";
import { formatVND } from "./dashboard.js?v=10";

const DEFAULT_LOGO_IMAGE = "img/logo.png";
let productsList = [];
let currentEditingId = null;
let currentExistingImageUrl = "";
let hasNewFileSelected = false;
const uploadedFilesCache = new Map();

function isDefaultOrEmptyImage(url) {
  if (!url || typeof url !== "string") return true;
  const trimmed = url.trim();
  return (
    trimmed === "" ||
    trimmed === DEFAULT_LOGO_IMAGE ||
    trimmed === "assets/images/logo.png" ||
    trimmed.includes("1517256064527-09c73fc73e38") ||
    trimmed.endsWith("localhost:5555/") ||
    trimmed.endsWith("localhost:5555") ||
    trimmed.endsWith("localhost:5500/") ||
    trimmed.endsWith("localhost:5500")
  );
}

/**
 * Khởi tạo quản lý sản phẩm
 */
export function initProducts() {
  listenProductsStream();
  setupProductForm();
}

/**
 * Lắng nghe Realtime Stream danh sách sản phẩm từ Cloud Firestore
 */
function listenProductsStream() {
  const tableBody = document.getElementById("products-table-body");
  if (!tableBody) return;

  onSnapshot(collection(db, "products"), (snapshot) => {
    productsList = [];
    let html = "";

    if (snapshot.empty) {
      tableBody.innerHTML = `
        <tr>
          <td colspan="6" class="py-12 text-center">
            <div class="max-w-md mx-auto">
              <i class="fi fi-rr-mug-hot-alt text-4xl text-stone-300 mx-auto mb-3 block"></i>
              <p class="text-stone-500 font-semibold mb-2">Chưa có sản phẩm nào trong thực đơn Firestore</p>
              <p class="text-xs text-stone-400 mb-4">Hãy bấm nút "Thêm món mới" ở góc trên bên phải để thêm sản phẩm đầu tiên.</p>
            </div>
          </td>
        </tr>
      `;
      return;
    }

    snapshot.forEach((doc) => {
      const p = { id: doc.id, ...doc.data() };
      productsList.push(p);

      const isAvailable = p.isAvailable !== false;
      const statusBadge = isAvailable
        ? `<button onclick="window.toggleProductStatus('${p.id}', false)" class="px-2.5 py-1 text-xs font-semibold rounded-full bg-emerald-100 text-emerald-700 hover:bg-emerald-200 transition inline-flex items-center space-x-1"><i class="fi fi-sr-check-circle text-[10px]"></i><span>Còn hàng</span></button>`
        : `<button onclick="window.toggleProductStatus('${p.id}', true)" class="px-2.5 py-1 text-xs font-semibold rounded-full bg-rose-100 text-rose-700 hover:bg-rose-200 transition inline-flex items-center space-x-1"><i class="fi fi-sr-cross-circle text-[10px]"></i><span>Hết hàng</span></button>`;

      const isLogoFallback = isDefaultOrEmptyImage(p.imageUrl);
      const displayImgSrc = isLogoFallback ? DEFAULT_LOGO_IMAGE : p.imageUrl;

      // Tự động dọn URL Unsplash mặc định cũ trên Firestore (nếu có) về rỗng để đồng bộ Logo quán
      if (p.imageUrl && (p.imageUrl.includes("1517256064527-09c73fc73e38") || p.imageUrl.endsWith("localhost:5555/"))) {
        updateDoc(doc(db, "products", p.id), { imageUrl: "" }).catch(() => {});
      }

      html += `
        <tr class="border-b border-stone-100 hover:bg-stone-50 transition">
          <td class="py-3 px-4">
            <img src="${displayImgSrc}" 
                 onerror="this.onerror=null;this.src='${DEFAULT_LOGO_IMAGE}';"
                 class="w-14 h-14 ${isLogoFallback ? 'object-contain bg-white p-1' : 'object-cover'} rounded-xl shadow-sm border border-stone-200" 
                 alt="${p.name}" />
          </td>
          <td class="py-3 px-4 font-bold text-stone-800">${p.name}</td>
          <td class="py-3 px-4">
            <span class="px-2.5 py-1 text-xs font-medium rounded-lg bg-stone-100 text-stone-700 border border-stone-200">
              ${p.category || "Cà phê"}
            </span>
          </td>
          <td class="py-3 px-4 font-bold text-amber-900">${formatVND(p.price)}</td>
          <td class="py-3 px-4">${statusBadge}</td>
          <td class="py-3 px-4 text-right space-x-2">
            <button onclick="window.openEditProductModal('${p.id}')" class="p-2 text-stone-600 hover:text-amber-800 hover:bg-amber-50 rounded-lg transition" title="Sửa món">
              <i class="fi fi-rr-edit text-sm"></i>
            </button>
            <button onclick="window.deleteProduct('${p.id}', '${p.name}')" class="p-2 text-stone-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition" title="Xóa món">
              <i class="fi fi-rr-trash text-sm"></i>
            </button>
          </td>
        </tr>
      `;
    });

    tableBody.innerHTML = html;
  });
}

/**
 * Đổi trạng thái Còn hàng / Hết hàng
 */
window.toggleProductStatus = async function (productId, newStatus) {
  try {
    const productRef = doc(db, "products", productId);
    await updateDoc(productRef, { isAvailable: newStatus });
    if (window.showToast) {
      window.showToast(
        newStatus ? "Đã mở bán lại sản phẩm trên thực đơn." : "Đã tạm ngưng bán (Hết hàng) sản phẩm này.",
        newStatus ? "success" : "warning",
        "Cập nhật trạng thái món"
      );
    }
  } catch (err) {
    if (window.showToast) {
      window.showToast("Lỗi cập nhật trạng thái món: " + err.message, "error");
    }
  }
};

/**
 * Xóa sản phẩm khỏi Firestore
 */
window.deleteProduct = async function (productId, productName) {
  const confirmed = window.showConfirmModal
    ? await window.showConfirmModal({
      title: `Xóa món "${productName}"?`,
      message: `Bạn có chắc chắn muốn xóa món "${productName}" khỏi thực đơn LOWLAND Coffee?`,
      confirmText: "Xóa món ngay",
      cancelText: "Hủy",
      type: "danger"
    })
    : true;
  if (!confirmed) return;

  try {
    await deleteDoc(doc(db, "products", productId));
    if (window.showToast) {
      window.showToast(`Đã xóa món "${productName}" khỏi thực đơn.`, "success", "Đã xóa sản phẩm");
    }
  } catch (err) {
    if (window.showToast) {
      window.showToast("Lỗi khi xóa món: " + err.message, "error");
    }
  }
};

/**
 * Mở modal Sửa thông tin món
 */
window.openEditProductModal = function (productId) {
  const product = productsList.find(p => p.id === productId);
  if (!product) return;

  currentEditingId = productId;
  hasNewFileSelected = false;
  currentExistingImageUrl = !isDefaultOrEmptyImage(product.imageUrl) ? product.imageUrl : "";

  document.getElementById("modal-product-title").textContent = "Chỉnh sửa sản phẩm";
  document.getElementById("prod-name").value = product.name || "";
  document.getElementById("prod-category").value = product.category || "Cà phê";
  document.getElementById("prod-price").value = product.price || 0;
  document.getElementById("prod-desc").value = product.description || "";
  document.getElementById("prod-toppings").value = (product.availableToppings || []).join(", ");

  // Reset ô chọn file để không bị dính file từ lần tải lên trước đó
  const fileInput = document.getElementById("prod-image-file");
  if (fileInput) fileInput.value = "";

  // Image preview
  const preview = document.getElementById("prod-image-preview");
  if (currentExistingImageUrl) {
    preview.src = currentExistingImageUrl;
    preview.dataset.hasImage = "true";
    preview.classList.remove("hidden");
  } else {
    preview.removeAttribute("src");
    preview.dataset.hasImage = "false";
    preview.classList.add("hidden");
  }

  // Checkboxes Size
  const sizes = product.availableSizes || ["S", "M", "L"];
  document.getElementById("size-s").checked = sizes.includes("S");
  document.getElementById("size-m").checked = sizes.includes("M");
  document.getElementById("size-l").checked = sizes.includes("L");

  document.getElementById("product-modal").classList.remove("hidden");
};

/**
 * Mở modal Thêm món mới
 */
window.openAddProductModal = function () {
  currentEditingId = null;
  hasNewFileSelected = false;
  currentExistingImageUrl = "";

  document.getElementById("modal-product-title").textContent = "Thêm món mới vào thực đơn";
  document.getElementById("product-form").reset();
  const fileInput = document.getElementById("prod-image-file");
  if (fileInput) fileInput.value = "";

  const preview = document.getElementById("prod-image-preview");
  if (preview) {
    preview.removeAttribute("src");
    preview.dataset.hasImage = "false";
    preview.classList.add("hidden");
  }
  document.getElementById("size-s").checked = true;
  document.getElementById("size-m").checked = true;
  document.getElementById("size-l").checked = true;
  document.getElementById("product-modal").classList.remove("hidden");
};

window.closeProductModal = function () {
  document.getElementById("product-modal").classList.add("hidden");
};

/**
 * Thiết lập xử lý form Thêm / Sửa & Upload ảnh lên Firebase Storage
 */
function setupProductForm() {
  const form = document.getElementById("product-form");
  const fileInput = document.getElementById("prod-image-file");
  const preview = document.getElementById("prod-image-preview");
  const submitBtn = document.getElementById("prod-submit-btn");

  // Xem trước & nén ảnh khi người dùng chủ động chọn file mới từ máy tính
  fileInput.addEventListener("change", (e) => {
    const file = e.target.files[0];
    if (file) {
      hasNewFileSelected = true;
      const reader = new FileReader();
      reader.onload = (event) => {
        const img = new Image();
        img.onload = () => {
          // Tạo canvas nén kích thước tối đa 800px để ảnh nhẹ và load siêu nhanh
          const canvas = document.createElement("canvas");
          const maxDim = 800;
          let width = img.width;
          let height = img.height;
          if (width > height && width > maxDim) {
            height = Math.round((height * maxDim) / width);
            width = maxDim;
          } else if (height > maxDim) {
            width = Math.round((width * maxDim) / height);
            height = maxDim;
          }
          canvas.width = width;
          canvas.height = height;
          const ctx = canvas.getContext("2d");
          ctx.drawImage(img, 0, 0, width, height);
          preview.src = canvas.toDataURL("image/jpeg", 0.85);
          preview.dataset.hasImage = "true";
          preview.classList.remove("hidden");
        };
        img.src = event.target.result;
      };
      reader.readAsDataURL(file);
    }
  });

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    submitBtn.disabled = true;
    submitBtn.innerHTML = `<span class="animate-spin inline-block mr-2">⏳</span> Đang lưu sản phẩm...`;

    try {
      const name = document.getElementById("prod-name").value.trim();
      const category = document.getElementById("prod-category").value;
      const price = parseFloat(document.getElementById("prod-price").value) || 0;
      const description = document.getElementById("prod-desc").value.trim();
      const toppingsRaw = document.getElementById("prod-toppings").value.trim();

      // Danh sách Size
      const availableSizes = [];
      if (document.getElementById("size-s").checked) availableSizes.push("S");
      if (document.getElementById("size-m").checked) availableSizes.push("M");
      if (document.getElementById("size-l").checked) availableSizes.push("L");

      // Danh sách Topping: Chỉ lưu khi người dùng có điền, để trống là mảng rỗng [] (không tự động điền mẫu)
      const availableToppings = toppingsRaw
        ? toppingsRaw.split(",").map(t => t.trim()).filter(Boolean)
        : [];

      // Giữ nguyên URL ảnh cũ nếu người dùng không chọn file ảnh mới
      let imageUrl = currentExistingImageUrl;

      // Chỉ tải lên Cloudinary khi người dùng thực sự vừa chọn 1 file ảnh mới từ máy
      const file = fileInput.files[0];
      if (hasNewFileSelected && file) {
        const fileKey = `${file.name}_${file.size}_${file.lastModified}`;
        if (uploadedFilesCache.has(fileKey)) {
          // Nếu file này vừa được tải lên rồi thì tái sử dụng ngay URL Cloudinary đó
          imageUrl = uploadedFilesCache.get(fileKey);
        } else {
          try {
            submitBtn.innerHTML = `<span class="animate-spin inline-block mr-2">☁️</span> Đang tải ảnh lên Cloudinary...`;
            imageUrl = await uploadToCloudinary(file, "lowland_coffee/products");
            uploadedFilesCache.set(fileKey, imageUrl);
            if (window.showToast) {
              window.showToast("Đã tải ảnh sản phẩm lên Cloudinary thành công!", "info", "Cloudinary Upload");
            }
          } catch (cloudErr) {
            console.warn("Chưa cấu hình hoặc lỗi Cloudinary, dùng ảnh nén dự phòng:", cloudErr);
            const rawPreview = preview.getAttribute("src") || "";
            if (rawPreview && rawPreview.length > 20) {
              imageUrl = rawPreview;
            }
          }
        }
      }

      // Nếu người dùng chưa thêm ảnh thì để trống (Web Admin & App sẽ tự động hiển thị Logo quán LOWLAND Coffee)
      if (isDefaultOrEmptyImage(imageUrl)) {
        imageUrl = "";
      }

      const productData = {
        name,
        category,
        price,
        description,
        imageUrl,
        availableSizes,
        availableToppings,
        isAvailable: true,
        updatedAt: new Date().toISOString()
      };

      // 2. Lưu vào Firestore
      if (currentEditingId) {
        // Cập nhật món cũ
        await updateDoc(doc(db, "products", currentEditingId), productData);
        if (window.showToast) {
          window.showToast(`Đã cập nhật thông tin món "${name}" thành công!`, "success", "Cập nhật thực đơn");
        }
      } else {
        // Thêm món mới
        productData.createdAt = new Date().toISOString();
        await addDoc(collection(db, "products"), productData);
        if (window.showToast) {
          window.showToast(`Đã thêm món mới "${name}" vào thực đơn!`, "success", "Thêm món thành công");
        }
      }

      window.closeProductModal();
    } catch (err) {
      if (window.showToast) {
        window.showToast("Đã xảy ra lỗi khi lưu món: " + err.message, "error");
      }
    } finally {
      submitBtn.disabled = false;
      submitBtn.innerHTML = `Lưu sản phẩm`;
    }
  });
}

