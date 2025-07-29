import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../notifications/notifications_page.dart';


class BuyerOrdersPage extends StatefulWidget {
  final String buyerId;

  const BuyerOrdersPage({Key? key, required this.buyerId}) : super(key: key);

  @override
  State<BuyerOrdersPage> createState() => _BuyerOrdersPageState();
}

class _BuyerOrdersPageState extends State<BuyerOrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['Pending', 'Accepted', 'Delivered'];

  @override
  void initState() {
    _tabController = TabController(length: _tabs.length, vsync: this);
    super.initState();
  }

  Stream<List<Map<String, dynamic>>> fetchOrdersByStatus(String status) {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('buyerId', isEqualTo: widget.buyerId)
        .where('status', isEqualTo: status)
        .orderBy('orderedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      var data = doc.data();
      data['orderId'] = doc.id; // Include document ID
      return data;
    }).toList());
  }

  Stream<int> fetchUnreadNotificationCount() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: widget.buyerId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': 'Cancelled'});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order cancelled successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel order')),
      );
    }
  }

  Future<void> confirmDelivery(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': 'Delivered'});

      // Add notification for seller
      DocumentSnapshot orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();
      
      if (orderDoc.exists) {
        Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': orderData['sellerId'],
          'title': 'Order Delivered',
          'message': '${orderData['buyerName']} has confirmed delivery of ${orderData['productName']}.',
          'timestamp': Timestamp.now(),
          'isRead': false,
          'orderId': orderId,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delivery confirmed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to confirm delivery')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Orders"),
        actions: [
          StreamBuilder<int>(
            stream: fetchUnreadNotificationCount(),
            builder: (context, snapshot) {
              int unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationsPage(buyerId: widget.buyerId),
                        ),
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
                          color: Colors.red,
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
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.pink[900],
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.pink[900],
          indicatorWeight: 3,
          labelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          tabs: _tabs.map((status) => Tab(
            text: status,
            icon: Icon(
              status == 'Pending' ? Icons.pending_actions
                : status == 'Accepted' ? Icons.check_circle
                : Icons.local_shipping,
              color: status == 'Pending' ? Colors.orange
                : status == 'Accepted' ? Colors.green
                : Colors.blue,
            ),
          )).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((status) => buildOrderList(status)).toList(),
      ),
    );
  }

  Widget buildOrderList(String status) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: fetchOrdersByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No $status orders found."));
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            var order = snapshot.data![index];

            return Card(
              margin: EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order['productName'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 4),
                    Text("Price: ₹${order['price']}", style: TextStyle(color: Colors.green)),
                    SizedBox(height: 4),
                    Text("Status: ${order['status']}", style: TextStyle(color: _getStatusColor(order['status']))),
                    SizedBox(height: 4),
                    Text("Ordered At: ${order['orderedAt'].toDate()}"),
                    Divider(height: 20),
                    Text("Seller Info:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Name: ${order['sellerName']}"),
                    Text("Email: ${order['sellerEmail']}"),
                    Text("Phone: ${order['sellerPhone']}"),
                    if (status == 'Pending')
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => cancelOrder(order['orderId']),
                          icon: Icon(Icons.cancel, color: Colors.red),
                          label: Text("Cancel Order", style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    if (status == 'Accepted')
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => confirmDelivery(order['orderId']),
                          icon: Icon(Icons.check_circle, color: Colors.green),
                          label: Text("Confirm Delivery", style: TextStyle(color: Colors.green)),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Accepted':
        return Colors.green;
      case 'Delivered':
        return Colors.blue;
      case 'Cancelled':
        return Colors.red;
      case 'Declined':
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}
