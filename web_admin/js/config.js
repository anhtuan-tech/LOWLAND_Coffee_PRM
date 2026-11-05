import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js";
import { 
  getAuth, 
  signInWithEmailAndPassword, 
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
  where 
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

// Export các hàm tiện ích Firestore & Storage
export {
  signInWithEmailAndPassword,
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
  ref,
  uploadBytesResumable,
  getDownloadURL
};

