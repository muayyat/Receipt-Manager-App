import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        .collection(
            'users') // Assuming your Firestore collection is named 'users'
        .doc(loggedInUser!.uid) // Use uid to uniquely identify the user
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
    if (loggedInUser == null) {
      throw Exception('User not logged in');
    }

    // Reference to the user's document in Firestore
    DocumentReference userDocRef =
        _firestore.collection('users').doc(loggedInUser!.uid);

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
    if (loggedInUser == null) {
      throw Exception('User not logged in');
    }

    DocumentReference userDocRef =
        _firestore.collection('users').doc(loggedInUser!.uid);

    await userDocRef.update({
      'profileImagePath': profileImagePath,
    });
  }

  // Delete the user profile data
  Future<void> deleteUserProfile() async {
    if (loggedInUser == null) {
      throw Exception('User not logged in');
    }

    DocumentReference userDocRef =
        _firestore.collection('users').doc(loggedInUser!.uid);

    await userDocRef.delete();
  }
}
