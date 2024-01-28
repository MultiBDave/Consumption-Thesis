importScripts("https://www.gstatic.com/firebasejs/7.5.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/7.5.0/firebase-messaging.js");
firebase.initializeApp({
    databaseURL: 'https://consumption-meter.firebaseio.com',
    apiKey: "AIzaSyA5ZqL9Csot_0OwxWIzw1tJBvIzSH_C6mE",
    authDomain: "consumption-meter.firebaseapp.com",
    projectId: "consumption-meter",
    storageBucket: "consumption-meter.appspot.com",
    messagingSenderId: "502965915123",
    appId: "1:502965915123:web:783670f1a8aacd71249686"
});
const messaging = firebase.messaging();
messaging.setBackgroundMessageHandler(function (payload) {
    const promiseChain = clients
        .matchAll({
            type: "window",
            includeUncontrolled: true
        })
        .then(windowClients => {
            for (let i = 0; i < windowClients.length; i++) {
                const windowClient = windowClients[i];
                windowClient.postMessage(payload);
            }
        })
        .then(() => {
            return registration.showNotification("New Message");
        });
    return promiseChain;
});
self.addEventListener('notificationclick', function (event) {
    console.log('notification received: ', event)
});