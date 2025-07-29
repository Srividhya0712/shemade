import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/order_model.dart';
import '../../models/userModel.dart';


class ProductDescriptionPage extends StatefulWidget {
  final Product product;

  const ProductDescriptionPage({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDescriptionPageState createState() => _ProductDescriptionPageState();
}

class _ProductDescriptionPageState extends State<ProductDescriptionPage> {
  bool _isLoading = false;
  String? _errorMessage;
  int _currentImageIndex = 0;

  Future<void> placeOrder(BuildContext context) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = "User not logged in.";
          _isLoading = false;
        });
        return;
      }

      // Get buyer details
      DocumentSnapshot buyerSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!buyerSnapshot.exists) {
        setState(() {
          _errorMessage = "Buyer profile not found.";
          _isLoading = false;
        });
        return;
      }
      Map<String, dynamic>? buyerData = buyerSnapshot.data() as Map<String, dynamic>?;
      if (buyerData == null) {
        setState(() {
          _errorMessage = "Error loading buyer data.";
          _isLoading = false;
        });
        return;
      }

      // Get seller details
      DocumentSnapshot sellerSnapshot = await FirebaseFirestore.instance.collection('users').doc(widget.product.sellerId).get();
      if (!sellerSnapshot.exists) {
        setState(() {
          _errorMessage = "Seller profile not found.";
          _isLoading = false;
        });
        return;
      }
      Map<String, dynamic>? sellerData = sellerSnapshot.data() as Map<String, dynamic>?;
      if (sellerData == null) {
        setState(() {
          _errorMessage = "Error loading seller data.";
          _isLoading = false;
        });
        return;
      }

      // Create order with null checks
      ProductOrder order = ProductOrder(
        id: '', // Will be set by Firestore
        productId: widget.product.id,
        productName: widget.product.name,
        price: widget.product.price,
        colors: widget.product.colors,
        buyerId: user.uid,
        buyerName: buyerData['name'] ?? 'Unknown Buyer',
        buyerEmail: buyerData['email'] ?? '',
        buyerPhone: buyerData['phone']?.toString() ?? '',
        sellerId: widget.product.sellerId,
        sellerName: sellerData['name'] ?? 'Unknown Seller',
        sellerEmail: sellerData['email'] ?? '',
        sellerPhone: sellerData['phone']?.toString() ?? '',
        status: 'Pending',
        orderedAt: Timestamp.now(),
        imageUrls: widget.product.imageUrls,
        quantity: 1,
      );

      // Add order to Firestore
      DocumentReference orderRef = await FirebaseFirestore.instance.collection('orders').add(order.toMap());
      
      // Update order with its ID
      await orderRef.update({
        'id': orderRef.id,
        'productId': widget.product.id,
      });

      // Create notifications for both buyer and seller
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': user.uid,
        'title': 'Order Placed',
        'message': 'You placed an order for ${widget.product.name}. Status: Pending.',
        'timestamp': Timestamp.now(),
        'isRead': false,
        'orderId': orderRef.id,
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': widget.product.sellerId,
        'title': 'New Order',
        'message': '${buyerData['name'] ?? 'A buyer'} placed an order for ${widget.product.name}.',
        'timestamp': Timestamp.now(),
        'isRead': false,
        'orderId': orderRef.id,
      });

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order placed successfully!")));
      Navigator.pop(context); // Return to previous screen
    } catch (e) {
      print('Error in placeOrder: $e');
      setState(() {
        _errorMessage = "Error: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      PageView.builder(
                        itemCount: widget.product.imageUrls.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Center(
                            child: Image.network(
                              widget.product.imageUrls[index],
                              fit: BoxFit.cover,
                              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: Colors.pink,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image: $error');
                                return Container(
                                  color: Colors.grey[200],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error, size: 50, color: Colors.pink),
                                      SizedBox(height: 8),
                                      Text('Failed to load image',
                                        style: TextStyle(color: Colors.pink),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      if (widget.product.imageUrls.length > 1)
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.product.imageUrls.length,
                              (index) => Container(
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == index
                                      ? Colors.pink
                                      : Colors.grey[300],
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.pink.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "₹${widget.product.price}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      SizedBox(height: 15),
                      Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink[900],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.product.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      SizedBox(height: 20),
                      if (widget.product.colors.isNotEmpty) ...[
                        Text(
                          "Available Colors",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink[900],
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.product.colors.map((color) => Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.pink[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.pink[200]!),
                            ),
                            child: Text(
                              color,
                              style: TextStyle(
                                color: Colors.pink[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 100), // Space for the bottom button
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => placeOrder(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      "Buy Now",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              ),
            ),
          ),
          if (_errorMessage != null)
            Positioned(
              bottom: 90,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 10),
                    Expanded(child: Text(_errorMessage!)),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
