import {
  db,
  storage,
  collection,
  doc,
  getDocs,
  setDoc,
  addDoc,
  updateDoc,
  deleteDoc,
  onSnapshot,
  ref,
  uploadBytesResumable,
  getDownloadURL
} from "./config.js";
import { formatVND } from "./dashboard.js";

let productsList = [];
let currentEditingId = null;

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
              <i data-lucide="coffee" class="w-12 h-12 text-stone-300 mx-auto mb-3"></i>
              <p class="text-stone-500 font-semibold mb-2">Chưa có sản phẩm nào trong thực đơn Firestore</p>
              <p class="text-xs text-stone-400 mb-4">Bạn có thể tự thêm món mới hoặc nạp nhanh bộ 8 món cà phê/trà/bánh mẫu của LOWLAND Coffee.</p>
              <button onclick="window.seedDefaultProducts()" 
                      class="inline-flex items-center space-x-2 px-4 py-2.5 bg-amberLow hover:bg-amber-600 text-white rounded-xl text-xs font-bold shadow-md transition">
                <i data-lucide="sparkles" class="w-4 h-4"></i>
                <span>Nạp ngay 8 món mẫu tự động</span>
              </button>
            </div>
          </td>
        </tr>
      `;
      if (window.lucide) window.lucide.createIcons();
      return;
    }

    snapshot.forEach((doc) => {
      const p = { id: doc.id, ...doc.data() };
      productsList.push(p);

      const isAvailable = p.isAvailable !== false;
      const statusBadge = isAvailable
        ? `<button onclick="window.toggleProductStatus('${p.id}', false)" class="px-2.5 py-1 text-xs font-semibold rounded-full bg-emerald-100 text-emerald-700 hover:bg-emerald-200 transition">Còn hàng</button>`
        : `<button onclick="window.toggleProductStatus('${p.id}', true)" class="px-2.5 py-1 text-xs font-semibold rounded-full bg-rose-100 text-rose-700 hover:bg-rose-200 transition">Hết hàng</button>`;

      html += `
        <tr class="border-b border-stone-100 hover:bg-stone-50 transition">
          <td class="py-3 px-4">
            <img src="${p.imageUrl || 'https://images.unsplash.com/photo-1517256064527-09c73fc73e38?auto=format&fit=crop&w=150&q=80'}" 
                 class="w-14 h-14 object-cover rounded-xl shadow-sm border border-stone-200" 
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
              <i data-lucide="edit-3" class="w-4 h-4"></i>
            </button>
            <button onclick="window.deleteProduct('${p.id}', '${p.name}')" class="p-2 text-stone-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition" title="Xóa món">
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

/**
 * Đổi trạng thái Còn hàng / Hết hàng
 */
window.toggleProductStatus = async function (productId, newStatus) {
  try {
    const productRef = doc(db, "products", productId);
    await updateDoc(productRef, { isAvailable: newStatus });
  } catch (err) {
    alert("Lỗi cập nhật trạng thái món: " + err.message);
  }
};

/**
 * Xóa sản phẩm khỏi Firestore
 */
window.deleteProduct = async function (productId, productName) {
  if (!confirm(`Bạn có chắc chắn muốn xóa món "${productName}" khỏi thực đơn?`)) return;

  try {
    await deleteDoc(doc(db, "products", productId));
  } catch (err) {
    alert("Lỗi khi xóa món: " + err.message);
  }
};

/**
 * Mở modal Sửa thông tin món
 */
window.openEditProductModal = function (productId) {
  const product = productsList.find(p => p.id === productId);
  if (!product) return;

  currentEditingId = productId;
  document.getElementById("modal-product-title").textContent = "Chỉnh sửa sản phẩm";
  document.getElementById("prod-name").value = product.name || "";
  document.getElementById("prod-category").value = product.category || "Cà phê";
  document.getElementById("prod-price").value = product.price || 0;
  document.getElementById("prod-desc").value = product.description || "";
  document.getElementById("prod-toppings").value = (product.availableToppings || []).join(", ");

  // Image preview
  const preview = document.getElementById("prod-image-preview");
  preview.src = product.imageUrl || "";
  preview.classList.remove("hidden");

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
  document.getElementById("modal-product-title").textContent = "Thêm món mới vào thực đơn";
  document.getElementById("product-form").reset();
  document.getElementById("prod-image-preview").classList.add("hidden");
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

  // Xem trước & nén ảnh khi chọn từ máy tính
  fileInput.addEventListener("change", (e) => {
    const file = e.target.files[0];
    if (file) {
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

      // Danh sách Topping
      const availableToppings = toppingsRaw
        ? toppingsRaw.split(",").map(t => t.trim()).filter(Boolean)
        : ["Thạch cà phê (+6.000đ)", "Trân châu trắng (+6.000đ)", "Kem Cheese (+10.000đ)"];

      let imageUrl = preview.src;

      // 1. Thử tải ảnh lên Firebase Storage nếu người dùng chọn file từ máy
      const file = fileInput.files[0];
      if (file) {
        try {
          submitBtn.innerHTML = `<span class="animate-spin inline-block mr-2">⏳</span> Đang tải ảnh lên Cloud...`;
          const safeName = file.name.replace(/[^a-zA-Z0-9.]/g, "_");
          const storageRef = ref(storage, `products/${Date.now()}_${safeName}`);
          const uploadTask = await uploadBytesResumable(storageRef, file);
          imageUrl = await getDownloadURL(uploadTask.ref);
        } catch (storageErr) {
          console.warn("Lưu trữ đám mây tạm khóa, sử dụng ảnh nén trực tiếp:", storageErr);
          // Giữ nguyên ảnh người dùng vừa chọn từ máy tính
          if (preview.src && preview.src.length > 20) {
            imageUrl = preview.src;
          }
        }
      }

      // Nếu không có ảnh thì gán ảnh chất lượng cao mặc định
      if (!imageUrl || imageUrl.trim() === "") {
        imageUrl = "https://images.unsplash.com/photo-1517256064527-09c73fc73e38?auto=format&fit=crop&w=600&q=80";
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
      } else {
        // Thêm món mới
        productData.createdAt = new Date().toISOString();
        await addDoc(collection(db, "products"), productData);
      }

      window.closeProductModal();
    } catch (err) {
      alert("Đã xảy ra lỗi: " + err.message);
    } finally {
      submitBtn.disabled = false;
      submitBtn.innerHTML = `Lưu sản phẩm`;
    }
  });
}

/**
 * Nạp nhanh bộ 8 sản phẩm mẫu vào Firestore
 */
export async function seedDefaultProducts() {
  const defaultProducts = [
    {
      id: "cf_phin_sua",
      name: "Phin Sữa Đá Đậm Đà",
      category: "Cà phê",
      price: 35000,
      imageUrl: "https://images.unsplash.com/photo-1517256064527-09c73fc73e38?auto=format&fit=crop&w=600&q=80",
      description: "Hạt cà phê Robusta hảo hạng hòa quyện cùng sữa đặc béo ngậy, giữ trọn hương vị truyền thống tinh hoa.",
      availableSizes: ["S", "M", "L"],
      availableToppings: ["Thạch cà phê (+6.000đ)", "Trân châu trắng (+6.000đ)", "Kem Cheese (+10.000đ)", "Shot Espresso (+10.000đ)"],
      isAvailable: true,
      createdAt: new Date().toISOString()
    },
    {
      id: "cf_phin_den",
      name: "Phin Đen Đá Nguyên Bản",
      category: "Cà phê",
      price: 32000,
      imageUrl: "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=600&q=80",
      description: "Cà phê phin truyền thống thơm lừng, vị đắng thanh dịu, hậu vị sâu lắng đánh thức mọi giác quan.",
      availableSizes: ["S", "M", "L"],
      availableToppings: ["Thạch cà phê (+6.000đ)", "Shot Espresso (+10.000đ)"],
      isAvailable: true,
      createdAt: new Date().toISOString()
    },
    {
      id: "cf_bac_xiu",
      name: "Bạc Xỉu Kem Béo LOWLAND",
      category: "Cà phê",
      price: 38000,
      imageUrl: "https://images.unsplash.com/photo-1541167760496-1628856ab772?auto=format&fit=crop&w=600&q=80",
      description: "Sự kết hợp tinh tế giữa sữa tươi béo ngậy, sữa đặc ngọt dịu và một chút cà phê phin thoang thoảng.",
      availableSizes: ["S", "M", "L"],
      availableToppings: ["Kem Cheese (+10.000đ)", "Trân châu trắng (+6.000đ)"],
      isAvailable: true,
      createdAt: new Date().toISOString()
    },
    {
      id: "tra_dao_cam_sa",
      name: "Trà Đào Cam Sả Tươi Mát",
      category: "Trà",
      price: 49000,
      imageUrl: "https://images.unsplash.com/photo-1556679343-c7306c1976bc?auto=format&fit=crop&w=600&q=80",
      description: "Trà đen ủ lạnh ngát hương sả tươi, cam vàng thanh mát kết hợp cùng những lát đào giòn ngọt sảng khoái.",
      availableSizes: ["S", "M", "L"],
      availableToppings: ["Miếng đào thêm (+10.000đ)", "Thạch đào (+6.000đ)", "Trân châu trắng (+6.000đ)"],
      isAvailable: true,
      createdAt: new Date().toISOString()
    },
    {
      id: "tra_sen_vang",
      name: "Trà Sen Vàng Củ Năng",
      category: "Trà",
      price: 49000,
      imageUrl: "https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=600&q=80",
      description: "Trà ô long thanh khiết kết hợp hạt sen bùi béo và củ năng giòn ngọt, phủ lớp kem sữa mềm mịn.",
      availableSizes: ["S", "M", "L"],
      availableToppings: ["Hạt sen thêm (+10.000đ)", "Củ năng (+6.000đ)"],
      isAvailable: true,
      createdAt: new Date().toISOString()
    },
    {
      id: "banh_pho_mai_cf",
      name: "Bánh Mousse Cà Phê Phô Mai",
      category: "Bánh",
      price: 39000,
      imageUrl: "https://images.unsplash.com/photo-1533134242443-d4fd215305ad?auto=format&fit=crop&w=600&q=80",
      description: "Chiếc bánh mềm mịn béo ngậy vị phô mai mascarpone quyện cùng hương cà phê nồng nàn.",
      availableSizes: ["M"],
      availableToppings: [],
      isAvailable: true,
      createdAt: new Date().toISOString()
    },
    {
      id: "banh_chuoi_nuong",
      name: "Bánh Chuối Nướng Thơm Bơ",
      category: "Bánh",
      price: 32000,
      imageUrl: "https://images.unsplash.com/photo-1607958996333-41aef7caefaa?auto=format&fit=crop&w=600&q=80",
      description: "Vị ngọt tự nhiên của chuối sứ chín muồi nướng vàng ươm, dậy mùi bơ sữa thơm nức lòng.",
      availableSizes: ["M"],
      availableToppings: [],
      isAvailable: true,
      createdAt: new Date().toISOString()
    },
    {
      id: "banh_croissant",
      name: "Bánh Croissant Ngàn Lớp",
      category: "Bánh",
      price: 35000,
      imageUrl: "https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&w=600&q=80",
      description: "Bánh sừng bò truyền thống vỏ giòn tan, ruột xốp mềm béo ngậy bơ Pháp hảo hạng.",
      availableSizes: ["M"],
      availableToppings: [],
      isAvailable: true,
      createdAt: new Date().toISOString()
    }
  ];

  try {
    for (const p of defaultProducts) {
      await setDoc(doc(db, "products", p.id), p);
    }
    alert("Đã nạp thành công 8 món mẫu vào thực đơn Firestore!");
  } catch (err) {
    alert("Lỗi khi nạp dữ liệu: " + err.message);
  }
}
window.seedDefaultProducts = seedDefaultProducts;

