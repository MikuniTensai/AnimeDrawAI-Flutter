import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _checkAndResetSubscriptionExpiry(credential.user!.uid);
    return credential;
  }

  Future<UserCredential> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _initializeUser(credential.user!, displayName: displayName);
    return credential;
  }

  Future<UserCredential> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    if (credential.additionalUserInfo?.isNewUser ?? false) {
      await _initializeUser(credential.user!);
    }
    await _checkAndResetSubscriptionExpiry(credential.user!.uid);
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception("Google Sign-In cancelled");

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      await _initializeUser(
        userCredential.user!,
        displayName: googleUser.displayName,
      );
    }
    await _checkAndResetSubscriptionExpiry(userCredential.user!.uid);
    return userCredential;
  }

  Future<UserCredential> linkWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception("Google Sign-In cancelled");

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await user.linkWithCredential(credential);
    await _firestore.collection('users').doc(user.uid).update({
      "provider": "google",
      "email": user.email ?? googleUser.email,
      "isAnonymous": false,
    });
    await _checkAndResetSubscriptionExpiry(userCredential.user!.uid);
    return userCredential;
  }

  Future<UserCredential> linkWithEmail(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    final AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    final userCredential = await user.linkWithCredential(credential);
    await _firestore.collection('users').doc(user.uid).update({
      "provider": "email",
      "email": email,
      "isAnonymous": false,
    });
    await _checkAndResetSubscriptionExpiry(userCredential.user!.uid);
    return userCredential;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> _initializeUser(User user, {String? displayName}) async {
    final name = displayName ?? _generateRandomName();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    await _firestore.collection('users').doc(user.uid).set({
      "displayName": name,
      "email": user.email ?? "",
      "isAnonymous": user.isAnonymous,
      "createdAt": FieldValue.serverTimestamp(),
      "generationCount": 0,
      "dailyGenerationCount": 0,
      "lastGenerationDate": today,
      "lastResetDate": today,
      "subscriptionType": "free",
      "subscriptionActive": true,
      "subscriptionExpiryDate": null,
      "provider": _getProviderString(user),
      "gems": 0,
    });
  }

  String _getProviderString(User user) {
    if (user.isAnonymous) return "anonymous";
    if (user.providerData.any((p) => p.providerId == 'google.com')) {
      return "google";
    }
    if (user.providerData.any((p) => p.providerId == 'password')) {
      return "email";
    }
    return "unknown";
  }

  Future<void> _checkAndResetSubscriptionExpiry(String uid) async {
    try {
      final userDoc = await _firestore.collection("users").doc(uid).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data();
      final expiry = userData?["subscriptionExpiryDate"];
      if (expiry == null) return;

      DateTime? expiryDate;
      if (expiry is String) {
        expiryDate = DateTime.tryParse(expiry);
      } else if (expiry is Timestamp) {
        expiryDate = expiry.toDate();
      }

      if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
        final batch = _firestore.batch();

        final userRef = _firestore.collection("users").doc(uid);
        batch.update(userRef, {
          "subscriptionType": "free",
          "subscriptionActive": false,
          "subscriptionExpiryDate": null,
        });

        final limitRef = _firestore.collection("generation_limits").doc(uid);
        batch.set(limitRef, {
          "subscriptionType": "free",
          "maxDailyLimit": 5,
          "subscriptionLimit": 0,
          "subscriptionUsed": 0,
          "dailyGenerations": 0,
          "isPremium": false,
          "subscriptionEndDate": null,
        }, SetOptions(merge: true));

        await batch.commit();
      }
    } catch (e) {
      // Ignore error so sign-in still continues
    }
  }

  String _generateRandomName() {
    final adjectives = [
      "Happy",
      "Brave",
      "Swift",
      "Clever",
      "Mighty",
      "Silent",
      "Golden",
      "Silver",
      "Crystal",
      "Shadow",
    ];
    final nouns = [
      "Dragon",
      "Phoenix",
      "Tiger",
      "Wolf",
      "Eagle",
      "Warrior",
      "Mage",
      "Knight",
      "Ninja",
      "Samurai",
    ];
    final random = Random();
    final adj = adjectives[random.nextInt(adjectives.length)];
    final noun = nouns[random.nextInt(nouns.length)];
    final num = random.nextInt(9999);
    return "$adj$noun$num";
  }

  Future<String> getUserDisplayName(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['displayName'] ?? "User";
  }

  Future<void> updateDisplayName(String newName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      "displayName": newName,
    });
    await user.updateDisplayName(newName);
  }
}
