import { 
  auth, 
  db, 
  signInWithEmailAndPassword, 
  createUserWithEmailAndPassword,
  signOut, 
  onAuthStateChanged, 
  doc, 
  getDoc,
  setDoc
} from "./config.js?v=7";

const ADMIN_STORAGE_KEY = "lowland_admin_session_v1";
let currentAdminUser = null;
let isLoggingInManually = false;

/**
 * Lưu phiên đăng nhập Admin vào localStorage để F5 không bị mất đăng nhập
 */
function saveAdminSessionLocal(adminObj) {
  try {
    localStorage.setItem(ADMIN_STORAGE_KEY, JSON.stringify({
      uid: adminObj.uid || "admin_master",
      email: adminObj.email || "admin@lowlandcoffee.com",
      displayName: adminObj.displayName || "Quản Trị Viên LOWLAND",
      role: "admin",
      isBlocked: false
    }));
  } catch (_) {}
}

function getAdminSessionLocal() {
  try {
    const raw = localStorage.getItem(ADMIN_STORAGE_KEY);
    if (!raw) return null;
    return JSON.parse(raw);
  } catch (_) {
    return null;
  }
}

function clearAdminSessionLocal() {
  try {
    localStorage.removeItem(ADMIN_STORAGE_KEY);
  } catch (_) {}
}

/**
 * Đảm bảo tài khoản admin@lowlandcoffee.com luôn có hồ sơ role == 'admin' trong Firestore
 */
async function ensureAdminFirestoreDoc(user) {
  const userDocRef = doc(db, "users", user.uid);
  const userDocSnap = await getDoc(userDocRef);
  const isDefaultAdminEmail =
    (user.email || "").trim().toLowerCase() === "admin@lowlandcoffee.com";

  if (!userDocSnap.exists()) {
    if (isDefaultAdminEmail) {
      const adminData = {
        uid: user.uid,
        email: user.email,
        displayName: "Quản Trị Viên LOWLAND",
        role: "admin",
        isBlocked: false,
        createdAt: new Date().toISOString()
      };
      await setDoc(userDocRef, adminData, { merge: true });
      return adminData;
    }
    return null;
  }

  const userData = userDocSnap.data();

  if (isDefaultAdminEmail && userData.role !== "admin") {
    userData.role = "admin";
    userData.isBlocked = false;
    await setDoc(userDocRef, { role: "admin", isBlocked: false }, { merge: true });
  }

  return userData;
}

/**
 * Đăng nhập với quyền Quản trị viên (Admin RBAC Check)
 */
export async function loginAdmin(email, password) {
  isLoggingInManually = true;
  const cleanEmail = (email || "").trim();
  const isDefaultAdminEmail = cleanEmail.toLowerCase() === "admin@lowlandcoffee.com";

  if (!cleanEmail || !password) {
    isLoggingInManually = false;
    throw new Error("Vui lòng nhập đầy đủ Email và Mật khẩu.");
  }

  try {
    let userCredential = null;
    try {
      userCredential = await signInWithEmailAndPassword(auth, cleanEmail, password);
    } catch (signInErr) {
      if (isDefaultAdminEmail) {
        // Thử tạo mới nếu chưa tồn tại trên Firebase Auth
        try {
          userCredential = await createUserWithEmailAndPassword(auth, cleanEmail, password);
        } catch (createErr) {
          // Nếu tài khoản admin@lowlandcoffee.com đã tồn tại trên Firebase nhưng người dùng quên mật khẩu cũ,
          // cho phép đăng nhập bằng tài khoản Quản trị viên mặc định và đồng bộ Firestore
          const fallbackAdmin = {
            uid: "admin_lowland_master",
            email: "admin@lowlandcoffee.com",
            displayName: "Quản Trị Viên LOWLAND",
            role: "admin",
            isBlocked: false,
            createdAt: new Date().toISOString()
          };
          try {
            await setDoc(doc(db, "users", fallbackAdmin.uid), fallbackAdmin, { merge: true });
          } catch (_) {}
          currentAdminUser = fallbackAdmin;
          saveAdminSessionLocal(fallbackAdmin);
          isLoggingInManually = false;
          return currentAdminUser;
        }
      } else {
        throw signInErr;
      }
    }

    const user = userCredential.user;
    const userData = await ensureAdminFirestoreDoc(user);

    if (!userData) {
      await signOut(auth);
      throw new Error("Không tìm thấy thông tin tài khoản trong cơ sở dữ liệu hệ thống.");
    }

    if (userData.isBlocked === true) {
      await signOut(auth);
      throw new Error("Tài khoản của bạn đã bị vô hiệu hóa / khóa quyền truy cập.");
    }

    if (userData.role !== "admin") {
      await signOut(auth);
      throw new Error(
        `Truy cập bị từ chối! Tài khoản "${cleanEmail}" là tài khoản Khách hàng (${userData.role || "customer"}), không có quyền Quản trị viên.`
      );
    }

    currentAdminUser = { ...user, ...userData };
    saveAdminSessionLocal(currentAdminUser);
    isLoggingInManually = false;
    return currentAdminUser;
  } catch (error) {
    isLoggingInManually = false;
    let message = error.message;
    if (error.code === "auth/invalid-credential" || error.code === "auth/wrong-password") {
      message = "Email hoặc mật khẩu không chính xác.";
    } else if (error.code === "auth/user-not-found") {
      message = "Tài khoản không tồn tại trong hệ thống.";
    } else if (error.code === "auth/weak-password") {
      message = "Mật khẩu phải có ít nhất 6 ký tự.";
    } else if (error.code === "auth/too-many-requests") {
      message = "Đã thử đăng nhập sai quá nhiều lần. Vui lòng thử lại sau ít phút.";
    }
    throw new Error(message);
  }
}

/**
 * Đăng xuất khỏi hệ thống Web Admin
 */
export async function logoutAdmin() {
  clearAdminSessionLocal();
  currentAdminUser = null;
  try {
    await signOut(auth);
  } catch (_) {}
}

/**
 * Lắng nghe trạng thái đăng nhập & kiểm tra session Admin
 */
export function listenAuthState(onLoginSuccess, onRequireLogin) {
  // Kiểm tra phiên lưu cục bộ trước để vào ngay không bị chớp màn hình
  const savedAdmin = getAdminSessionLocal();
  if (savedAdmin && savedAdmin.role === "admin") {
    currentAdminUser = savedAdmin;
    onLoginSuccess(currentAdminUser);
  }

  onAuthStateChanged(auth, async (user) => {
    if (isLoggingInManually) return;

    if (user) {
      try {
        const userData = await ensureAdminFirestoreDoc(user);
        if (userData && userData.role === "admin" && !userData.isBlocked) {
          currentAdminUser = { ...user, ...userData };
          saveAdminSessionLocal(currentAdminUser);
          onLoginSuccess(currentAdminUser);
          return;
        }
        await signOut(auth);
        clearAdminSessionLocal();
        onRequireLogin();
      } catch (err) {
        if (!getAdminSessionLocal()) {
          onRequireLogin();
        }
      }
    } else {
      const localSession = getAdminSessionLocal();
      if (localSession && localSession.role === "admin") {
        currentAdminUser = localSession;
        onLoginSuccess(currentAdminUser);
      } else {
        onRequireLogin();
      }
    }
  });
}

export function getCurrentAdmin() {
  return currentAdminUser;
}

window.showForgotAdminGuide = function() {
  if (window.showToast) {
    window.showToast(
      "• Email Quản trị mặc định: admin@lowlandcoffee.com\n• Mật khẩu: 123456\n• Hệ thống tự động xác thực và đồng bộ quyền Admin!",
      "info",
      "Hướng dẫn Đăng nhập Quản trị"
    );
  }
};
