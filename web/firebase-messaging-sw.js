importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

const firebaseConfig = {
    apiKey: 'AIzaSyBLnqBZeXbZJX0mN98-EGys0jB3tQPrrsg',
    appId: '1:451436284213:web:9b1c5dbd39a62e8212e47c',
    messagingSenderId: '451436284213',
    projectId: 'ikenas-ad83c',
    authDomain: 'ikenas-ad83c.firebaseapp.com',
    storageBucket: 'ikenas-ad83c.firebasestorage.app',
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  return self.registration.showNotification(notificationTitle,
    notificationOptions);
});
