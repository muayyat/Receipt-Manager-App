import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../logger.dart';
import 'auth_service.dart';

final _firestore = FirebaseFirestore.instance;

class UserService {
  User? loggedInUser;

  UserService() {
    getCurrentUser();
  }

  // Fetch the current logged-in user
  void getCurrentUser() async {
    loggedInUser = FirebaseAuth.instance.currentUser;
  }

  // Fetch user profile data for the current user
  Stream<DocumentSnapshot<Map<String, dynamic>>> fetchUserProfile() {
    if (loggedInUser == null) {
      throw Exception('User not logged in');
    }

    // Retrieve the user profile data from Firestore
    return _firestore
        .collection('users') // Firestore collection is named 'users'
        .doc(loggedInUser!.email) // Use email as document ID
        .snapshots();
  }

  // Add or update user profile data
  Future<void> updateUserProfile({
    required String userName,
    required String phoneNumber,
    required String city,
    required String country,
    String? profileImagePath,
  }) async {
    if (loggedInUser == null || loggedInUser?.email == null) {
      throw Exception('User not logged in');
    }

    // Reference to the user's document in Firestore using their email as document ID
    DocumentReference userDocRef =
        _firestore.collection('users').doc(loggedInUser!.email);

    // Set or update the user's profile data
    await userDocRef.set({
      'userName': userName,
      'phoneNumber': phoneNumber,
      'city': city,
      'country': country,
      if (profileImagePath != null) 'profileImagePath': profileImagePath,
    }, SetOptions(merge: true));
  }

  // Update profile image
  Future<void> updateProfileImage(String profileImagePath) async {
    if (loggedInUser == null || loggedInUser?.email == null) {
      throw Exception('User not logged in');
    }

    DocumentReference userDocRef =
        _firestore.collection('users').doc(loggedInUser!.email);

    await userDocRef.update({
      'profileImagePath': profileImagePath,
    });
  }

  // Delete the user profile data
  Future<void> deleteUserProfile() async {
    if (loggedInUser == null || loggedInUser?.email == null) {
      throw Exception('User not logged in');
    }

    DocumentReference userDocRef =
        _firestore.collection('users').doc(loggedInUser!.email);

    await userDocRef.delete();
  }

  // Clear all history: Receipts, Categories, and Profile
  Future<void> clearAllHistory() async {
    if (loggedInUser == null || loggedInUser?.email == null) {
      throw Exception('User not logged in');
    }

    // Clear receipts
    await _firestore.collection('receipts').doc(loggedInUser!.email).update({
      'receiptlist': [], // Clear the array
    });

    // Clear categories
    await _firestore.collection('categories').doc(loggedInUser!.email).update({
      'categorylist': [], // Clear the array
    });
  }

  // Delete the Firebase Authentication account and Firestore profile
  Future<void> deleteUser() async {
    User? user = await AuthService.getCurrentUser();
    if (user != null) {
      try {
        // Delete user profile in Firestore
        await _firestore.collection('users').doc(user.email).delete();

        // Delete receipts
        await _firestore
            .collection('receipts')
            .doc(loggedInUser!.email)
            .delete();

        // Delete categories
        await _firestore
            .collection('categories')
            .doc(loggedInUser!.email)
            .delete();

        logger.e('User profile and account deleted successfully');
      } catch (e) {
        logger.e("Error deleting user: $e");
      }
    } else {
      logger.i("No user is currently signed in.");
    }
  }
}
