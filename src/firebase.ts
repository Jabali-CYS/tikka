import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";

const firebaseConfig = {
  apiKey: "AIzaSyCTKahQcheeVCTmuDPKlj9y0JcNRoDBCxM",
  authDomain: "grill-chicken-tikka.firebaseapp.com",
  projectId: "grill-chicken-tikka",
  storageBucket: "grill-chicken-tikka.appspot.com",
  messagingSenderId: "580202894784"
};

// Initialize Firebase App
const app = initializeApp(firebaseConfig);

// Export instances
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
