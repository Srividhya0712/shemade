import 'package:flutter/material.dart';
import 'package:shemadev2/screens/seller/sellerDashboard.dart';


import 'package:shemadev2/screens/seller/sellerOrders.dart';
import 'package:shemadev2/screens/seller/seller_product_list.dart';



import '../../widgets/profile_drawer.dart';
import 'add_product_screen.dart';
class SellerHome extends StatefulWidget {
  final int initialIndex;
  const SellerHome({super.key, this.initialIndex = 0}); // Accept initial index

  @override
  _SellerHomeState createState() => _SellerHomeState();
}

class _SellerHomeState extends State<SellerHome> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // Set the initial tab index
  }

  final List<Widget> _pages = [
    SellerDashboard(),
    SellerProductList(),
    SellerOrdersPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const ProfileDrawer(),
      appBar: AppBar(title: const Text("Seller App")),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Products"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: "Orders"),
        ],
      ),
    );
  }
}
