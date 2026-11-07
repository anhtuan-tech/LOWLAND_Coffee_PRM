import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js";
import {
  getAuth,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut,
  onAuthStateChanged
} from "https://www.gstatic.com/firebasejs/10.12.0/firebase-auth.js";
import {
  getFirestore,
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  addDoc,
  updateDoc,
  deleteDoc,
  onSnapshot,
  query,
  orderBy,
  where,
  limit
} from "https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js";
import {
  getStorage,
  ref,
  uploadBytesResumable,
  getDownloadURL
} from "https://www.gstatic.com/firebasejs/10.12.0/firebase-storage.js";

// Cấu hình Firebase Web chính xác từ Firebase Console của LOWLAND Coffee
export const firebaseConfig = {
  apiKey: "AIzaSyDh87j1s8dvGNHpP7Jsqw-6chaokejNoz8",
  authDomain: "lowland-coffee.firebaseapp.com",
  projectId: "lowland-coffee",
  storageBucket: "lowland-coffee.firebasestorage.app",
  messagingSenderId: "914107662357",
  appId: "1:914107662357:web:09d4ea1da4306ee4ed0e1c",
  measurementId: "G-2MQV2NXC5Q"
};

// Khởi tạo Firebase App
export const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);

// ============================================================================
// CẤU HÌNH CLOUDINARY (LƯU TRỮ HÌNH ẢNH ĐÁM MÂY MIỄN PHÍ 100%)
// Bạn có thể điền trực tiếp ở đây HOẶC nhập ngay trên giao diện Web Admin!
// ============================================================================
export const cloudinaryConfig = {
  cloudName: "bflxgvhn", // VD: "dxyz12345" (Lấy tại Dashboard Cloudinary)
  uploadPreset: "lowland_unsigned" // Tên Upload Preset (Chế độ: Unsigned)
};

/**
 * Lấy cấu hình Cloudinary hiện tại (Ưu tiên config.js -> localStorage -> Firestore `settings/cloudinary`)
 */
export async function getCloudinaryCredentials() {
  if (cloudinaryConfig.cloudName && cloudinaryConfig.cloudName.trim() !== "") {
    return {
      cloudName: cloudinaryConfig.cloudName.trim(),
      uploadPreset: (cloudinaryConfig.uploadPreset || "lowland_unsigned").trim()
    };
  }

  try {
    const savedLocal = localStorage.getItem("lowland_cloudinary_config");
    if (savedLocal) {
      const parsed = JSON.parse(savedLocal);
      if (parsed.cloudName && parsed.uploadPreset) {
        return {
          cloudName: parsed.cloudName.trim(),
          uploadPreset: parsed.uploadPreset.trim()
        };
      }
    }
  } catch (_) { }

  try {
    const snap = await getDoc(doc(db, "settings", "cloudinary"));
    if (snap.exists()) {
      const data = snap.data();
      if (data.cloudName && data.uploadPreset) {
        localStorage.setItem("lowland_cloudinary_config", JSON.stringify(data));
        return {
          cloudName: data.cloudName.trim(),
          uploadPreset: data.uploadPreset.trim()
        };
      }
    }
  } catch (_) { }

  return { cloudName: "", uploadPreset: "lowland_unsigned" };
}

/**
 * Upload File hoặc chuỗi Base64 lên Cloudinary bằng Unsigned Upload API
 * @returns {Promise<string>} Đường dẫn ảnh HTTPS (`secure_url`) trên Cloudinary
 */
export async function uploadToCloudinary(fileOrDataUrl, folder = "lowland_coffee/products") {
  const { cloudName, uploadPreset } = await getCloudinaryCredentials();
  if (!cloudName || !uploadPreset) {
    throw new Error("Chưa cấu hình Cloud Name hoặc Upload Preset của Cloudinary.");
  }

  const formData = new FormData();
  formData.append("file", fileOrDataUrl);
  formData.append("upload_preset", uploadPreset);
  formData.append("folder", folder);

  const response = await fetch(`https://api.cloudinary.com/v1_1/${cloudName}/image/upload`, {
    method: "POST",
    body: formData
  });

  const data = await response.json();
  if (!response.ok || !data.secure_url) {
    throw new Error(data.error?.message || "Không thể upload ảnh lên Cloudinary.");
  }

  return data.secure_url;
}

// Export các hàm tiện ích Firestore & Storage
export {
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  addDoc,
  updateDoc,
  deleteDoc,
  onSnapshot,
  query,
  orderBy,
  where,
  limit,
  ref,
  uploadBytesResumable,
  getDownloadURL
};

