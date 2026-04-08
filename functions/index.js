const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendCommentNotification = onDocumentCreated(
  "items/{itemId}/comments/{commentId}",
  async (event) => {
    const comment = event.data.data();
    const itemId = event.params.itemId;

    try {
      // get the item document
      const itemDoc = await admin
        .firestore()
        .collection("items")
        .doc(itemId)
        .get();

      if (!itemDoc.exists) return null;

      const item = itemDoc.data();
      const itemOwnerId = item.postedBy;
      const commentAuthor = comment.postedByName;
      const itemTitle = item.title;

      // don't notify if owner commented on their own post
      if (itemOwnerId === comment.postedBy) return null;

      // save notification to Firestore
      await admin
        .firestore()
        .collection("notifications")
        .add({
          userId: itemOwnerId,
          itemId: itemId,
          itemTitle: itemTitle,
          commentAuthor: commentAuthor,
          message: `${commentAuthor} commented on your lost item "${itemTitle}"`,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      // get the item owner's device token
      const ownerDoc = await admin
        .firestore()
        .collection("users")
        .doc(itemOwnerId)
        .get();

      if (!ownerDoc.exists) return null;

      const ownerData = ownerDoc.data();
      const deviceToken = ownerData.fcmToken;

      if (!deviceToken) return null;

      // send push notification
      const message = {
        notification: {
          title: "New comment on your post",
          body: `${commentAuthor} commented on "${itemTitle}"`,
        },
        data: {
          itemId: itemId,
          type: "comment",
        },
        token: deviceToken,
      };

      await admin.messaging().send(message);
      console.log("Notification sent to:", itemOwnerId);
      return null;

    } catch (error) {
      console.error("Error sending notification:", error);
      return null;
    }
  }
);