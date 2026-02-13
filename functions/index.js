const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Listens for new notification documents in a couple's subcollection
 * and sends an FCM push notification to the partner.
 */
exports.sendPartnerNotification = onDocumentCreated(
    "couples/{coupleId}/notifications/{notificationId}",
    async (event) => {
        const notifData = event.data.data();
        if (!notifData) return;

        const coupleId = event.params.coupleId;
        const senderId = notifData.senderId;

        try {
            // 1. Get couple details to find the partner
            const coupleDoc = await admin.firestore()
                .collection("couples").doc(coupleId).get();
            if (!coupleDoc.exists) return;

            const users = coupleDoc.data().users || [];
            const partnerId = users.find((uid) => uid !== senderId);

            if (!partnerId) {
                console.log("No partner found in couple:", coupleId);
                return;
            }

            // 2. Get partner's FCM token
            const partnerDoc = await admin.firestore()
                .collection("users").doc(partnerId).get();
            const userData = partnerDoc.data();
            const fcmToken = userData ? userData.fcmToken : null;

            if (!fcmToken) {
                console.log("Partner has no FCM token:", partnerId);
                return;
            }

            // 3. Send notification
            const message = {
                notification: {
                    title: notifData.title || "Yuvam Bildirimi",
                    body: notifData.body || "Bir güncelleme var.",
                },
                data: {
                    click_action: "FLUTTER_NOTIFICATION_CLICK",
                    id: event.params.notificationId,
                    type: notifData.data ? (notifData.data.type || "general") : "general",
                },
                token: fcmToken,
            };

            await admin.messaging().send(message);
            console.log("Successfully sent notification to:", partnerId);
        } catch (error) {
            console.error("Error sending notification:", error);
        }
    }
);
