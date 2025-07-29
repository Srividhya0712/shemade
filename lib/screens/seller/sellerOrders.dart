import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SellerOrdersPage extends StatefulWidget {
  @override
  _SellerOrdersPageState createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage> with AutomaticKeepAliveClientMixin {
  final String currentSellerId = FirebaseAuth.instance.currentUser!.uid;
  List<DocumentSnapshot> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadOrders() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final querySnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: currentSellerId)
          .orderBy('orderedAt', descending: true)
          .get();

      if (!mounted) return;

      setState(() {
        _orders = querySnapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading orders: $e');
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Error loading orders: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      DocumentSnapshot orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        if (!mounted) return;
        setState(() {
          _errorMessage = "Order not found";
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic>? orderData = orderDoc.data() as Map<String, dynamic>?;
      if (orderData == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = "Error loading order data";
          _isLoading = false;
        });
        return;
      }

      // Update order status
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': newStatus,
      });

      // If order is accepted, update product stock
      if (newStatus == 'Accepted') {
        // Check if productId exists in order data
        if (orderData.containsKey('productId') && orderData['productId'] != null && orderData['productId'].toString().isNotEmpty) {
          String productId = orderData['productId'].toString();
          int orderedQuantity = orderData['quantity'] ?? 1;
          
          try {
            // Get current product stock
            DocumentSnapshot productDoc = await FirebaseFirestore.instance
                .collection('products')
                .doc(productId)
                .get();
                
            if (productDoc.exists) {
              int currentStock = productDoc['stockQuantity'] ?? 0;
              int newStock = currentStock - orderedQuantity;
              
              if (newStock >= 0) {
                // Update product stock
                await FirebaseFirestore.instance
                    .collection('products')
                    .doc(productId)
                    .update({
                      'stockQuantity': newStock,
                    });
              } else {
                // If stock would go negative, don't update and show error
                if (!mounted) return;
                setState(() {
                  _errorMessage = "Insufficient stock for this order";
                  _isLoading = false;
                });
                return;
              }
            } else {
              if (!mounted) return;
              setState(() {
                _errorMessage = "Product not found";
                _isLoading = false;
              });
              return;
            }
          } catch (e) {
            print('Error updating product stock: $e');
            if (!mounted) return;
            setState(() {
              _errorMessage = "Error updating product stock";
              _isLoading = false;
            });
            return;
          }
        } else {
          if (!mounted) return;
          setState(() {
            _errorMessage = "Product ID not found in order data";
            _isLoading = false;
          });
          return;
        }
      }

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': orderData['buyerId'],
        'title': 'Order Update',
        'message': 'Your order for ${orderData['productName']} has been $newStatus.',
        'timestamp': Timestamp.now(),
        'isRead': false,
        'orderId': orderId,
      });

      if (!mounted) return;
      await _loadOrders();

      if (!mounted) return;
      _scaffoldKey.currentState?.showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus')),
      );
    } catch (e) {
      print('Error updating order status: $e');
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Error updating order status: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: ScaffoldMessenger(
        key: _scaffoldKey,
        child: Scaffold(
          appBar: AppBar(
            title: Text("Manage Orders"),
            backgroundColor: Colors.pinkAccent,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadOrders,
              ),
            ],
          ),
          body: Stack(
            children: [
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else if (_orders.isEmpty)
                Center(child: Text("No orders yet"))
              else
                RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final orderData = order.data() as Map<String, dynamic>;
                      final status = orderData['status'] ?? 'Unknown';

                      return Card(
                        margin: EdgeInsets.all(10),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.pink[50]!,
                                Colors.white,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        orderData['imageUrls'] != null && (orderData['imageUrls'] as List).isNotEmpty 
                                            ? (orderData['imageUrls'] as List)[0] 
                                            : '',
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => 
                                          Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.pink[100],
                                            child: Icon(Icons.image_not_supported, color: Colors.pink[300]),
                                          ),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            orderData['productName'] ?? 'Unknown Product',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.pink[900],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            "₹${orderData['price'] ?? '0'}",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(status).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: _getStatusColor(status)),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: _getStatusColor(status),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Divider(color: Colors.pink[100]),
                                SizedBox(height: 8),
                                Text(
                                  "Buyer Details",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pink[900],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Name: ${orderData['buyerName'] ?? 'Unknown Buyer'}",
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  "Email: ${orderData['buyerEmail'] ?? 'No email'}",
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  "Phone: ${orderData['buyerPhone'] ?? 'No phone'}",
                                  style: TextStyle(fontSize: 14),
                                ),
                                SizedBox(height: 16),
                                if (status == 'Pending')
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => updateOrderStatus(order.id, 'Accepted'),
                                        icon: Icon(Icons.check_circle, color: Colors.green),
                                        label: Text(
                                          "Accept",
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            side: BorderSide(color: Colors.green),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () => updateOrderStatus(order.id, 'Declined'),
                                        icon: Icon(Icons.cancel, color: Colors.red),
                                        label: Text(
                                          "Decline",
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                            side: BorderSide(color: Colors.red),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (_errorMessage != null)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(8),
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
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Accepted':
        return Colors.green;
      case 'Declined':
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}
