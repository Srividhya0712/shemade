import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shemadev2/screens/seller/signUpScreen.dart';

import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  final List<Map<String, String>> _pages = [
    {
      "image": "assets/ob1.jpg",
      "title": "Welcome to SheMade",
      "description": "Discover unique products crafted by talented women entrepreneurs."
    },
    {
      "image": "assets/ob2.png",
      "title": "Empower Women Entrepreneurs",
      "description": "Support and uplift women by engaging in a thriving marketplace."
    },
    {
      "image": "assets/ob3.jpg",
      "title": "Start Buying Today",
      "description": "Find what you love with secure transactions and a seamless experience."
    },
  ];

  /// **Mark onboarding as completed and navigate to SignUp**
  Future<void> _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// **PageView for onboarding slides**
          PageView.builder(
            controller: _controller,
            onPageChanged: (index) {
              setState(() => isLastPage = index == _pages.length - 1);
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    _pages[index]["image"]!,
                    height: 250,
                    width: 250,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _pages[index]["title"]!,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    child: Text(
                      _pages[index]["description"]!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ),
                ],
              );
            },
          ),

          /// **Smooth Page Indicator**
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _controller,
                count: _pages.length,
                effect: const ExpandingDotsEffect(
                  activeDotColor: Colors.pinkAccent,
                  dotHeight: 10,
                  dotWidth: 10,
                ),
              ),
            ),
          ),

          /// **Next or Get Started Button**
          Positioned(
            bottom: 30,
            right: 20,
            child: isLastPage
                ? ElevatedButton(
              onPressed: _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text("Get Started"),
            )
                : TextButton(
              onPressed: () {
                _controller.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text(
                "Next",
                style: TextStyle(fontSize: 18, color: Colors.pinkAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
