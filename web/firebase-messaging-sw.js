importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCfQ6oW39ZYPAsD-_zv3JFmzN6NyI15l7w",
  authDomain: "efootball-76fcf.firebaseapp.com",
  projectId: "efootball-76fcf",
  storageBucket: "efootball-76fcf.firebasestorage.app",
  messagingSenderId: "458723311102",
  appId: "1:458723311102:web:e3edfa46e82064627094af",
  measurementId: "G-XGZPDPFDBZ"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
