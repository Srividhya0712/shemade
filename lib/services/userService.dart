import 'package:cloud_firestore/cloud_firestore.dart';


class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Future<String?> getUserRole(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection("users").doc(userId).get();
      if (userDoc.exists) {
        return userDoc["role"];
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
    return null;
  }
}
