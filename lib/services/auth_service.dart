import 'package:ads_schools/models/models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? user;

  AuthService() {
    _firebaseAuth.authStateChanges().listen((User? user) {
      this.user = user;
      notifyListeners();
    });
  }

  bool get isAuthenticated {
    try {
      // Check if user is not null and has a valid email
      return user != null && user!.email != null && user!.email!.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking authentication status: $e');
      return false;
    }
  }

  Future<void> checkAuthState() async {
    user = _firebaseAuth.currentUser;
    if (user == null) {
      await signOut();
    }
    notifyListeners();
  }

  Future<void> deleteUser(String email) async {
    try {
      if (user != null && user!.email == email) {
        await user!.delete();
        user = null;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase error during user deletion: $e');
    }
    notifyListeners();
  }

  Future<UserModel?> getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Retrieving the saved data
    String? userID = prefs.getString('userID');
    String? firstName = prefs.getString('firstName');
    String? otherNames = prefs.getString('otherNames');
    String? email = prefs.getString('email');
    String? photo = prefs.getString('photo');
    String? role = prefs.getString('role');

    if (userID != null && email != null && role != null) {
      return UserModel(
        userId: userID,
        firstName: firstName,
        otherNames: otherNames,
        email: email,
        photo: photo,
        role: role,
      );
    } else {
      return null;
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential credential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase error during sign in: $e');
      return null;
    }
  }

  /// Sign in anonymously
  Future<User?> signInAnonymously() async {
    try {
      UserCredential credential = await _firebaseAuth.signInAnonymously();
      user = credential.user;
      notifyListeners();
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase error during anonymous sign in: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all saved user data
  }

  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential credential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase error during sign up: $e');
      return null;
    }
  }

  Future<void> updateUserCredentials({
    required String currentPassword,
    String? newEmail,
    String? newPassword,
    String? newName,
  }) async {
    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);

        if (newEmail != null && newEmail.isNotEmpty) {
          await user.verifyBeforeUpdateEmail(newEmail);
        }

        if (newPassword != null && newPassword.isNotEmpty) {
          await user.updatePassword(newPassword);
        }
      } on FirebaseAuthException catch (e) {
        debugPrint('Firebase error during credentials update: $e');
      }
    }
  }
}
