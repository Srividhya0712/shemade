import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Required for buyerId

import 'package:shemadev2/screens/seller/buyerOrdersPage.dart';
import 'package:shemadev2/widgets/profile_drawer.dart';

import 'buyerProductList.dart';

class BuyerHome extends StatefulWidget {
  final int initialIndex;
  const BuyerHome({super.key, this.initialIndex = 0});

  @override
  _BuyerHomeState createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  late int _selectedIndex;
  String? buyerId;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    // Get current user's UID as buyerId
    buyerId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    if (buyerId == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> _pages = [
      BuyerProductList(),
      BuyerOrdersPage(buyerId: buyerId!), // Now safely pass it
    ];

    return Scaffold(
      drawer: const ProfileDrawer(),
      appBar: AppBar(title: const Text("Buyer App")),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Shop"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "My Orders"),
        ],
      ),
    );
  }
}
