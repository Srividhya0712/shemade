import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shemadev2/screens/seller/prod_Description_page.dart';


import '../../models/order_model.dart';
import '../../notifications/notifications_page.dart';

class BuyerProductList extends StatefulWidget {
  @override
  _BuyerProductListState createState() => _BuyerProductListState();
}

class _BuyerProductListState extends State<BuyerProductList> {
  String selectedCategory = "All";
  String selectedSubCategory = "All";
  String searchQuery = "";
  bool showFavoritesOnly = false;

  final String buyerId = FirebaseAuth.instance.currentUser!.uid;

  Stream<List<Product>> fetchProducts() {
    return FirebaseFirestore.instance
        .collection('products')
        .where('stockQuantity', isGreaterThan: 0)
        .snapshots()
        .asyncMap((snapshot) async {
      final allProducts = snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();

      if (showFavoritesOnly) {
        final favSnapshot = await FirebaseFirestore.instance
            .collection('favorites')
            .where('buyerId', isEqualTo: buyerId)
            .get();
        final favoriteProductIds = favSnapshot.docs.map((doc) => doc['productId']).toSet();

        return allProducts.where((p) => favoriteProductIds.contains(p.id)).toList();
      }

      return allProducts;
    });
  }

  Future<bool> isFavorite(String productId) async {
    final favDoc = await FirebaseFirestore.instance
        .collection('favorites')
        .where('buyerId', isEqualTo: buyerId)
        .where('productId', isEqualTo: productId)
        .get();
    return favDoc.docs.isNotEmpty;
  }

  Future<void> toggleFavorite(String productId) async {
    final favRef = FirebaseFirestore.instance.collection('favorites');
    final snapshot = await favRef
        .where('buyerId', isEqualTo: buyerId)
        .where('productId', isEqualTo: productId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      // Remove favorite
      await favRef.doc(snapshot.docs.first.id).delete();
    } else {
      // Add favorite
      await favRef.add({'buyerId': buyerId, 'productId': productId});
    }

    setState(() {}); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Shemade",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.pink[900],
          ),
        ),
        centerTitle: true,
        actions: [
          StreamBuilder<int>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: buyerId)
                .where('isRead', isEqualTo: false)
                .snapshots()
                .map((snapshot) => snapshot.docs.length),
            builder: (context, snapshot) {
              int unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications, color: Colors.pinkAccent),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => NotificationsPage(buyerId: buyerId)),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.pink[900],
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: Icon(
              showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: Colors.pinkAccent,
            ),
            tooltip: showFavoritesOnly ? "Show All" : "Show Favorites",
            onPressed: () {
              setState(() {
                showFavoritesOnly = !showFavoritesOnly;
              });
            },
          )
        ],
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.pink.shade100,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search handmade items...",
                prefixIcon: Icon(Icons.search, color: Colors.pink),
                filled: true,
                fillColor: Colors.pink.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onChanged: (query) {
                setState(() {
                  searchQuery = query.toLowerCase();
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              DropdownButton<String>(
                value: selectedCategory,
                onChanged: (value) => setState(() => selectedCategory = value!),
                items: ["All", "Plants", "Clothes", "Art & Crafts"].map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
              ),
              DropdownButton<String>(
                value: selectedSubCategory,
                onChanged: (value) => setState(() => selectedSubCategory = value!),
                items: ["All", "Men", "Women", "Child", "Herbal", "Decor"].map((subcategory) {
                  return DropdownMenuItem(value: subcategory, child: Text(subcategory));
                }).toList(),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: fetchProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("No products available"));
                }

                List<Product> filteredProducts = snapshot.data!.where((product) {
                  return (selectedCategory == "All" || product.category == selectedCategory) &&
                      (selectedSubCategory == "All" || product.subcategory == selectedSubCategory) &&
                      (searchQuery.isEmpty || product.name.toLowerCase().contains(searchQuery));
                }).toList();

                return ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return FutureBuilder<bool>(
                      future: isFavorite(product.id),
                      builder: (context, favSnapshot) {
                        final isFav = favSnapshot.data ?? false;
                        return Card(
                          elevation: 5,
                          color: Colors.white,
                          shadowColor: Colors.pink.shade100,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: ListTile(
                            leading: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    product.imageUrls.isNotEmpty ? product.imageUrls[0] : '',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => 
                                      Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[200],
                                        child: Icon(Icons.error, size: 20, color: Colors.pink),
                                      ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: Icon(
                                      isFav ? Icons.favorite : Icons.favorite_border,
                                      color: Colors.pinkAccent,
                                      size: 20,
                                    ),
                                    onPressed: () => toggleFavorite(product.id),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(product.name, style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("₹${product.price} | ${product.description}",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.pinkAccent),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) => ProductDescriptionPage(product: product),
                              ));
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
