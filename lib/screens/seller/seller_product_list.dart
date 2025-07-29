import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class SellerProductList extends StatefulWidget {
  @override
  _SellerProductListState createState() => _SellerProductListState();
}

class _SellerProductListState extends State<SellerProductList> {
  final User? user = FirebaseAuth.instance.currentUser;
  String searchQuery = "";

  Future<void> _deleteProduct(String productId) async {
    await FirebaseFirestore.instance.collection('products').doc(productId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("🗑️ Product deleted successfully!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.pinkAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Products'),
        backgroundColor: Colors.pinkAccent.shade200, // Changed to Feminine Pink
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.pinkAccent),
                hintText: "Search products...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20), // Rounded for a softer look
                  borderSide: BorderSide(color: Colors.pinkAccent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.pink),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('sellerId', isEqualTo: user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No products added yet.', style: TextStyle(color: Colors.pinkAccent)));
                }
                var products = snapshot.data!.docs;
                var filteredProducts = products.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return data['name'].toLowerCase().contains(searchQuery) ||
                      data['category'].toLowerCase().contains(searchQuery);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return Center(child: Text("No matching products found.", style: TextStyle(color: Colors.pinkAccent)));
                }

                return ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    var product = filteredProducts[index];
                    var data = product.data() as Map<String, dynamic>;
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      color: Colors.pink.shade50, // Soft Pink Card
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: data['imageUrls'] != null && data['imageUrls'].isNotEmpty
                              ? Image.network(
                            data['imageUrls'][0], // Get the first image from the array
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                              Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[200],
                                child: Icon(Icons.error, size: 20, color: Colors.pink),
                              ),
                          )
                              : Icon(Icons.image_not_supported, size: 50, color: Colors.pinkAccent),
                        ),
                        title: Text(
                          "${data['name']} - ₹${data['price']}",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.pink.shade900),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${data['category']} | Stock: ${data['stockQuantity']}",
                              style: TextStyle(color: Colors.pink.shade700),
                            ),
                            Text(
                              data['description'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.pink.shade600),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.pinkAccent),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProductScreen(
                                      productId: product.id,
                                      productData: data,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _deleteProduct(product.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          bool? productAdded = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductScreen()),
          );
          if (productAdded == true) {
            setState(() {});
          }
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.pinkAccent, // Soft Pink FAB
      ),
    );
  }
}
