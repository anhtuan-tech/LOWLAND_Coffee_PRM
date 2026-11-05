import { 
  auth, 
  db, 
  signInWithEmailAndPassword, 
  signOut, 
  onAuthStateChanged, 
  doc, 
  getDoc 
} from "./config.js";

let currentAdminUser = null;

/**
 * Đăng nhập với quyền Quản trị viên (Admin RBAC Check)
 */
export async function loginAdmin(email, password) {
  try {
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;

    // Kiểm tra phân quyền trong Firestore collection 'users'
    const userDocRef = doc(db, "users", user.uid);
    const userDocSnap = await getDoc(userDocRef);

    if (!userDocSnap.exists()) {
      await signOut(auth);
      throw new Error("Không tìm thấy thông tin tài khoản trong cơ sở dữ liệu hệ thống.");
    }

    const userData = userDocSnap.data();

    // 1. Kiểm tra tài khoản có bị khóa không
    if (userData.isBlocked === true) {
      await signOut(auth);
      throw new Error("Tài khoản của bạn đã bị vô hiệu hóa / khóa quyền truy cập.");
    }

    // 2. Kiểm tra Role RBAC (Chỉ cho phép role == 'admin')
    if (userData.role !== "admin") {
      await signOut(auth);
      throw new Error("Truy cập bị từ chối! Tài khoản này không có quyền Quản trị viên (Yêu cầu role == 'admin').");
    }

    currentAdminUser = { ...user, ...userData };
    return currentAdminUser;
  } catch (error) {
    let message = error.message;
    if (error.code === "auth/invalid-credential" || error.code === "auth/wrong-password") {
      message = "Email hoặc mật khẩu không chính xác.";
    } else if (error.code === "auth/user-not-found") {
      message = "Tài khoản không tồn tại trong hệ thống.";
    } else if (error.code === "auth/too-many-requests") {
      message = "Đã thử đăng nhập sai quá nhiều lần. Vui lòng thử lại sau.";
    }
    throw new Error(message);
  }
}

/**
 * Đăng xuất khỏi hệ thống Web Admin
 */
export async function logoutAdmin() {
  await signOut(auth);
  currentAdminUser = null;
}

/**
 * Lắng nghe trạng thái đăng nhập & kiểm tra session Admin
 */
export function listenAuthState(onLoginSuccess, onRequireLogin) {
  onAuthStateChanged(auth, async (user) => {
    if (user) {
      try {
        const userDocRef = doc(db, "users", user.uid);
        const userDocSnap = await getDoc(userDocRef);

        if (userDocSnap.exists()) {
          const userData = userDocSnap.data();
          if (userData.role === "admin" && !userData.isBlocked) {
            currentAdminUser = { ...user, ...userData };
            onLoginSuccess(currentAdminUser);
            return;
          }
        }
        // Không phải admin
        await signOut(auth);
        onRequireLogin();
      } catch (err) {
        onRequireLogin();
      }
    } else {
      onRequireLogin();
    }
  });
}

export function getCurrentAdmin() {
  return currentAdminUser;
}

window.showForgotAdminGuide = function() {
  alert(
    "HƯỚNG DẪN ĐẶT LẠI MẬT KHẨU QUẢN TRỊ VIÊN:\n\n" +
    "Cách 1 (Nhanh nhất - 10 giây):\n" +
    "1. Dùng chính tài khoản bạn vừa đăng ký trên Mobile (vd: tuanleanh15052004@gmail.com).\n" +
    "2. Mở Firebase Console > Firestore Database > collection 'users'.\n" +
    "3. Bấm vào tài khoản của bạn, sửa trường role từ 'customer' thành 'admin'.\n" +
    "4. Bạn dùng email đó và mật khẩu của bạn để đăng nhập vào Web Admin này!\n\n" +
    "Cách 2 (Tạo lại admin@lowlandcoffee.com):\n" +
    "1. Mở Firebase Console > Authentication > Users.\n" +
    "2. Xóa tài khoản admin@lowlandcoffee.com cũ, bấm 'Add user' nhập lại mật khẩu mới (vd: 123456).\n" +
    "3. Vào Firestore > collection 'users' đảm bảo role là 'admin'."
  );
};

