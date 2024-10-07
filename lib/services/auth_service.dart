import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the currently logged-in user
  static Future<User?> getCurrentUser() async {
    try {
      return _auth.currentUser;
    } catch (e) {
      print("Error fetching user: $e");
      return null;
    }
  }

  // Sign in with email and password
  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Error signing in: $e");
      return null;
    }
  }

  // Register with email and password
  static Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Error registering: $e");
      return null;
    }
  }

  // Sign out the user
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  // Re-authenticate user
  static Future<void> reAuthenticate(String email, String password) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      } else {
        print("No user is currently signed in.");
      }
    } catch (e) {
      print("Error re-authenticating user: $e");
    }
  }

  // Delete the user account
  static Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      } else {
        print("No user is currently signed in.");
      }
    } catch (e) {
      print("Error deleting account: $e");
    }
  }

  // Reset password by sending password reset email
  static Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print("Password reset email sent to $email");
    } catch (e) {
      print("Error sending password reset email: $e");
    }
  }
}
