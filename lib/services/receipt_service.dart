import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firestore = FirebaseFirestore.instance;

class ReceiptService {
  User? loggedInUser;

  ReceiptService() {
    getCurrentUser();
  }

  void getCurrentUser() async {
    loggedInUser = FirebaseAuth.instance.currentUser;
  }

  // Fetch receipts for the current user
  Stream<DocumentSnapshot<Map<String, dynamic>>> fetchReceipts() {
    if (loggedInUser == null) {
      throw Exception('User not logged in');
    }

    return _firestore
        .collection('receipts')
        .doc(loggedInUser!.email) // Use email or uid for user identification
        .snapshots();
  }

  // Add a new receipt
  Future<void> addReceipt(Map<String, dynamic> receiptData) async {
    if (loggedInUser == null) {
      throw Exception('User not logged in');
    }

    // Generate a unique ID for each receipt
    String receiptId =
        FirebaseFirestore.instance.collection('receipts').doc().id;

    // Add the receipt ID to the receipt data
    receiptData['id'] = receiptId;

    // Get the user document by userId or email
    DocumentReference userDocRef =
        _firestore.collection('receipts').doc(loggedInUser!.email);

    await userDocRef.set({
      'receiptlist': FieldValue.arrayUnion([receiptData])
    }, SetOptions(merge: true));
  }

  // Update an existing receipt
  Future<void> updateReceipt(
      String receiptId, Map<String, dynamic> updatedData) async {
    if (loggedInUser == null) {
      throw Exception('User not logged in');
    }

    // Get the user document by userId or email
    DocumentReference userDocRef =
        _firestore.collection('receipts').doc(loggedInUser!.email);

    DocumentSnapshot userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      throw Exception('User document not found');
    }

    // Get the current receipt list
    List<dynamic> receiptList = userDoc['receiptlist'] ?? [];

    // Find the index of the receipt to update by its ID
    int receiptIndex =
        receiptList.indexWhere((receipt) => receipt['id'] == receiptId);

    if (receiptIndex != -1) {
      // Replace the old receipt with the updated data
      receiptList[receiptIndex] = updatedData;

      // Update the receipt list in the document
      await userDocRef.update({'receiptlist': receiptList});
    } else {
      throw Exception('Receipt not found');
    }
  }

  // Delete a receipt by its index (assumes receipts are stored in an array)
  Future<void> deleteReceipt(String receiptId) async {
    if (loggedInUser == null) {
      throw Exception('User not logged in');
    }

    DocumentReference userDocRef =
        _firestore.collection('receipts').doc(loggedInUser!.email);

    // First, get the current receipt list
    DocumentSnapshot doc = await userDocRef.get();
    if (doc.exists) {
      List<dynamic> receiptList = doc['receiptlist'] ?? [];

      // Find the receipt and remove it
      receiptList.removeWhere((receipt) => receipt['id'] == receiptId);

      // Update the document with the new list
      await userDocRef.update({'receiptlist': receiptList});
    }
  }

  // Set category to null for all receipts that match the given category name
  Future<void> setReceiptsCategoryToNull(String categoryName) async {
    if (loggedInUser == null) {
      throw Exception('User not logged in');
    }

    DocumentReference userDocRef =
        _firestore.collection('receipts').doc(loggedInUser!.email);

    // Fetch the user's receipts
    DocumentSnapshot doc = await userDocRef.get();
    if (doc.exists) {
      List<dynamic> receiptList = doc['receiptlist'] ?? [];

      // Iterate over the receipts and set category to null for those with matching category
      List<dynamic> updatedReceiptList = receiptList.map((receipt) {
        if (receipt['category'] == categoryName) {
          receipt['category'] = null; // Set the category to null
        }
        return receipt;
      }).toList();

      // Update the Firestore document with the modified receipts
      await userDocRef.update({'receiptlist': updatedReceiptList});
    } else {
      throw Exception('No receipts found for the current user');
    }
  }
}
