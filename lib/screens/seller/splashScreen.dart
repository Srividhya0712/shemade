import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shemadev2/screens/seller/sellerHome.dart';



import 'buyerHome.dart';
import 'loginScreen.dart';
import 'onBoardingscreen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(Duration(seconds: 3)); // Splash delay

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      String userRole = userDoc['role'] ?? '';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => userRole == 'Buyer' ? BuyerHome() : SellerHome(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => hasSeenOnboarding ? LoginScreen() : OnboardingScreen(),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: SvgPicture.network(
                  'https://www.svgrepo.com/show/452178/cart.svg',
                  color: Colors.pinkAccent,
                  placeholderBuilder: (context) => const CircularProgressIndicator(), // Fallback
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
