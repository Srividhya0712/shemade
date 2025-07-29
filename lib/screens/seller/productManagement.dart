import 'package:flutter/material.dart';
import 'add_product_screen.dart';
import 'seller_product_list.dart';

class ProductManagement extends StatefulWidget {
  const ProductManagement({super.key});

  @override
  _ProductManagementState createState() => _ProductManagementState();
}

class _ProductManagementState extends State<ProductManagement> {
  int _selectedTab = 0;

  final List<Widget> _tabs = [
    AddProductScreen(),
    SellerProductList(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Product Management")),
      body: _tabs[_selectedTab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Add Product"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "My Products"),
        ],
      ),
    );
  }
}
