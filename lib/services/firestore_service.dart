import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/item_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // UPLOAD ITEM IMAGE TO STORAGE
  Future<String?> uploadItemImage(File image, String itemId) async {
    try {
      String uid = _auth.currentUser?.uid ?? 'unknown';
      String fileName = 'item_photos/$uid/$itemId.jpg';
      Reference storageRef = _storage.ref().child(fileName);
      await storageRef.putFile(image);
      String url = await storageRef.getDownloadURL();
      return url;
    } catch (e) {
      print('🔴 upload error: $e');
      return null;
    }
  }

  // GET ALL ITEMS — real time stream
  Stream<List<ItemModel>> getItems({String filter = 'all'}) {
    Query query = _firestore
        .collection('items')
        .orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ItemModel.fromFirestore(doc))
          .toList();
    });
  }

  // GET MY ITEMS
  Stream<List<ItemModel>> getMyItems() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('items')
        .where('postedBy', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => ItemModel.fromFirestore(doc))
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  // ADD ITEM
  Future<String?> addItem(ItemModel item, File imageFile) async {
    try {
      print('💾 saving to firestore...');

      // first create the document to get an ID
      DocumentReference docRef =
          await _firestore.collection('items').add(item.toMap());

      // upload image to Storage using the document ID
      String? imageUrl = await uploadItemImage(imageFile, docRef.id);

      if (imageUrl == null) {
        // delete the document if image upload failed
        await docRef.delete();
        return 'failed to upload image';
      }

      // update document with image URL
      await docRef.update({'imageUrl': imageUrl});

      print('💾 saved successfully!');
      return null;
    } catch (e) {
      print('🔴 firestore error: $e');
      return 'failed to post item. please try again';
    }
  }

  // UPDATE ITEM STATUS
  Future<String?> updateItemStatus(String itemId, String newStatus) async {
    try {
      await _firestore.collection('items').doc(itemId).update({
        'status': newStatus,
      });
      return null;
    } catch (e) {
      return 'failed to update status';
    }
  }

  // GET SINGLE ITEM
  Future<ItemModel?> getItem(String itemId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('items').doc(itemId).get();
      if (doc.exists) {
        return ItemModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // GET ALL ITEMS FOR MAP
  Future<List<ItemModel>> getItemsForMap() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('items')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => ItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }
}