import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // GET ALL ITEMS — returns a real time stream
  // like a websocket in React — updates automatically!
  Stream<List<ItemModel>> getItems({String filter = 'all'}) {
    Query query = _firestore
        .collection('items')
        .orderBy('createdAt', descending: true);

    if (filter == 'found') {
      query = query.where('type', isEqualTo: 'found');
    } else if (filter == 'lost') {
      query = query.where('type', isEqualTo: 'lost');
    }

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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ItemModel.fromFirestore(doc))
          .toList();
    });
  }

  // ADD ITEM
  Future<String?> addItem(ItemModel item) async {
    try {
      await _firestore.collection('items').add(item.toMap());
      return null; // success
    } catch (e) {
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