import 'package:cloud_firestore/cloud_firestore.dart';


class Product {
  String id;
  String name;
  String category;
  String subcategory;
  String description;
  DateTime? expiryDate;
  double price;
  int stockQuantity;
  int initialStock;
  List<String> colors;
  String sellerId;
  String sellerName;
  String sellerContact;
  List<String> imageUrls;
  Timestamp createdAt;


  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.subcategory,
    required this.description,
    this.expiryDate,
    required this.price,
    required this.stockQuantity,
    required this.initialStock, // 🔥 Added initialStock field
    this.colors = const [], // Default to empty list
    required this.sellerId,
    required this.sellerName,
    required this.sellerContact,
    required this.imageUrls,
    required this.createdAt,
  });


  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'subcategory': subcategory,
      'description': description,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'price': price,
      'stockQuantity': stockQuantity,
      'initialStock': initialStock, // 🔥 Ensure initialStock is stored
      'colors': colors,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerContact': sellerContact,
      'imageUrls': imageUrls,
      'createdAt': createdAt,
    };
  }


  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      subcategory: map['subcategory'] ?? '',
      description: map['description'] ?? '',
      expiryDate: map['expiryDate'] != null ? (map['expiryDate'] as Timestamp).toDate() : null,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: map['stockQuantity'] ?? 0,
      initialStock: map['initialStock'] ?? 0, // 🔥 Default to 0 if null
      colors: List<String>.from(map['colors'] ?? []),
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerContact: map['sellerContact'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }
}
