import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shemadev2/screens/seller/buyerHome.dart';
import 'package:shemadev2/screens/seller/loginScreen.dart';
import 'package:shemadev2/screens/seller/onBoardingscreen.dart';
import 'package:shemadev2/screens/seller/sellerHome.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}


class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}


class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;
  bool _hasSeenOnboarding = false;
  String _userRole = ''; // Stores "buyer" or "seller"
  bool _isSplashVisible = true; // Controls splash visibility


  @override
  void initState() {
    super.initState();
    _showSplashScreen();
    _checkLoginStatus();
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', false);
        setState(() {
          _isLoggedIn = false;
          _userRole = '';
        });
      } else {
        await _fetchUserRole(user);
      }
    });
  }


  Future<void> _showSplashScreen() async {
    await Future.delayed(Duration(seconds: 3)); // 3-second splash
    setState(() {
      _isSplashVisible = false;
    });
  }


  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    User? user = FirebaseAuth.instance.currentUser;
    if (_isLoggedIn && user != null) {
      await _fetchUserRole(user);
    }
    setState(() {});
  }


  Future<void> _fetchUserRole(User user) async {
    DocumentSnapshot userDoc =
    await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      String role = (userDoc['role'] ?? '').toString(); // Remove toLowerCase()
      setState(() {
        _userRole = role;
        _isLoggedIn = true;
      });


      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', role); // Save role locally
    }
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFFFB6C1), // Light pink
        scaffoldBackgroundColor: const Color(0xFFFFF0F5), // Lavender blush
        colorScheme: ColorScheme.light(
          primary: const Color(0xFFFFB6C1), // Light pink
          secondary: const Color(0xFFFFD700), // Gold
          surface: Colors.white,
          background: const Color(0xFFFFF0F5), // Lavender blush
          error: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.black87,
          onSurface: Colors.black87,
          onBackground: Colors.black87,
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFB6C1), // Light pink
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB6C1), // Light pink
            foregroundColor: Colors.white,
            elevation: 2,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFFFB6C1), // Light pink
            textStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFFFFB6C1).withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: const Color(0xFFFFB6C1).withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFFB6C1), width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(
            color: Colors.black54,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: Colors.black38,
            fontSize: 16,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          shadowColor: const Color(0xFFFFB6C1).withOpacity(0.2),
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
          displayMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
          displaySmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
      ),
      home: _isSplashVisible
          ? SplashScreen() // Show splash screen first
          : _isLoggedIn
          ? (_userRole == 'Buyer'
          ? BuyerHome()
          : SellerHome()) // Redirect based on role
          : _hasSeenOnboarding
          ? LoginScreen()
          : OnboardingScreen(),
    );
  }
}


class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade100, // Light pink background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade300, Colors.pink.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Image.asset(
            'assets/splash.png', // Make sure this exists in assets
            width: 250,




            height: 250,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
