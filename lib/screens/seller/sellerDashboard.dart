import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/order_model.dart';

class SellerDashboard extends StatefulWidget {
  @override
  _SellerDashboardState createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  User? user = FirebaseAuth.instance.currentUser;
  String sellerName = "";

  @override
  void initState() {
    super.initState();
    _fetchSellerName();
  }

  Future<void> _fetchSellerName() async {
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      setState(() {
        sellerName = doc.data()?['name'] ?? 'Seller';
      });
    }
  }

  Future<List<Product>> _getProductStockDetails() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: user?.uid)
        .get();
    return snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seller Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pinkAccent.shade200,
      ),
      body: FutureBuilder(
        future: _getProductStockDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error loading data"));
          }

          var products = snapshot.data as List<Product>;
          int totalProducts = products.length;
          int totalStock = products.fold(0, (sum, item) => sum + item.stockQuantity);
          int totalSold = products.fold(0, (sum, item) => sum + ((item.initialStock ?? 0) - item.stockQuantity));
          int stockedOut = products.where((item) => item.stockQuantity == 0).length;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome, $sellerName!",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.pink)),
                  SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(child: _buildStatCard("Total Products", totalProducts, Icons.shopping_bag, Colors.blue)),
                      SizedBox(width: 16),
                      Expanded(child: _buildStatCard("Total Stock", totalStock, Icons.store, Colors.green)),
                    ],
                  ),

                  SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(child: _buildStatCard("Sold Items", totalSold, Icons.sell, Colors.orange)),
                      SizedBox(width: 16),
                      Expanded(child: _buildStatCard("Stocked Out", stockedOut, Icons.error, Colors.red)),
                    ],
                  ),

                  SizedBox(height: 20),
                  Text("Product Stock Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: products.map((product) {
                        final progress = (product.stockQuantity / (product.initialStock ?? 1)).clamp(0.0, 1.0);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: _buildCircularProductIndicator(product.name, product.stockQuantity, progress),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return AspectRatio(
        aspectRatio: 1.0,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          color: Colors.pink[50],
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30, color: color),
                SizedBox(height: 4),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  "$value",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildCircularProductIndicator(String productName, int stockRemaining, double progress) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(progress < 0.3 ? Colors.red : Colors.green),
              ),
            ),
            Text("${(progress * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        SizedBox(height: 6),
        Text(productName, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text("$stockRemaining left", style: TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}