import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/seller/loginScreen.dart';

class ProfileDrawer extends StatefulWidget {
  const ProfileDrawer({super.key});

  @override
  _ProfileDrawerState createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> {
  User? user = FirebaseAuth.instance.currentUser;
  String name = "", email = "", phone = "", location = "";
  bool isEditingPhone = false;
  bool isEditingLocation = false;
  TextEditingController phoneController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          name = userDoc['name'];
          email = userDoc['email'];
          phone = userDoc['phone'].toString();
          location = userDoc['location'];
          phoneController.text = phone;
          locationController.text = location;
        });
      }
    }
  }

  Future<void> _updateUserData(String field, String value) async {
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({field: value});
      setState(() {
        if (field == 'phone') {
          phone = value;
          isEditingPhone = false;
        } else if (field == 'location') {
          location = value;
          isEditingLocation = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(top: 40, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.pink.shade200,
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.pink.shade600,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.pink.shade50,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: Icon(Icons.phone, color: Colors.pink.shade400),
                    title: isEditingPhone
                        ? TextField(
                            controller: phoneController,
                            style: TextStyle(
                              fontSize: 15,
                              letterSpacing: 0.3,
                            ),
                            decoration: InputDecoration(
                              hintText: "Enter phone number",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          )
                        : Text(
                            phone,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                    trailing: IconButton(
                      icon: Icon(
                        isEditingPhone ? Icons.check : Icons.edit,
                        color: Colors.pink.shade400,
                      ),
                      onPressed: () {
                        if (isEditingPhone) {
                          _updateUserData('phone', phoneController.text);
                        } else {
                          setState(() => isEditingPhone = true);
                        }
                      },
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.location_on, color: Colors.pink.shade400),
                    title: isEditingLocation
                        ? TextField(
                            controller: locationController,
                            style: TextStyle(
                              fontSize: 15,
                              letterSpacing: 0.3,
                            ),
                            decoration: InputDecoration(
                              hintText: "Enter location",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          )
                        : Text(
                            location,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                    trailing: IconButton(
                      icon: Icon(
                        isEditingLocation ? Icons.check : Icons.edit,
                        color: Colors.pink.shade400,
                      ),
                      onPressed: () {
                        if (isEditingLocation) {
                          _updateUserData('location', locationController.text);
                        } else {
                          setState(() => isEditingLocation = true);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
            ),
            child: Column(
              children: [
                Divider(),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.pink.shade400),
                  title: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
