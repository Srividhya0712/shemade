import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  // 🔹 Signup function
  Future<String?> signup({
    required String name,
    required String email,
    required String password,
    required String role,
    required num phone,
    required String location,
  }) async {
    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );


      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'role': role,
        'location': location,
        'phone': phone,
      });


      return null;
    } catch (e) {
      return e.toString();
    }
  }


  // 🔹 New signInUser function (Replaces the old login function)
  Future<Map<String, String>?> signInUser(String email, String password) async {
    try {
      UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(email: email, password: password);


      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();


      if (userDoc.exists) {
        return {
          'role': userDoc['role'],
          'email': userDoc['email'],
          'location': userDoc['location'] ?? '',
        };
      } else {
        return null; // User not found
      }
    } catch (e) {
      return null; // Return null on failure
    }
  }


  // 🔹 Logout function
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
