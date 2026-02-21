importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "AIzaSyD6qSLF7zNEF6Sbr9V5tYj9YSOvqAartCQ",
  appId: "1:972665082655:web:16651b208ac04afda2562a",
  messagingSenderId: "972665082655",
  projectId: "realitycart-a1e3f",
  authDomain: "realitycart-a1e3f.firebaseapp.com",
  storageBucket: "realitycart-a1e3f.firebasestorage.app",
  measurementId: "G-22QJFWQ62N"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  // Customize notification here
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle,
    notificationOptions);
});
