import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProductManagementScreen extends StatefulWidget {
  @override
  _ProductManagementScreenState createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  String? selectedCategory;
  String? selectedSubcategory;

  final Map<String, List<String>> categoryOptions = {
    'Clothes': ['Men', 'Women', 'Child'],
    'Plants': ['Indoor', 'Outdoor', 'Flowering'],
    'Art & Crafts': ['Painting', 'Handmade', 'Decor'],
  };

  bool isExpiryApplicable = false;

  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate()) {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      String sellerName = userDoc['name'];
      String sellerContact = userDoc['phone'];

      await FirebaseFirestore.instance.collection('products').add({
        'name': _nameController.text.trim(),
        'category': selectedCategory,
        'subcategory': selectedSubcategory,
        'description': _descriptionController.text.trim(),
        'expiryDate': isExpiryApplicable ? _expiryController.text.trim() : '',
        'price': double.parse(_priceController.text.trim()),
        'stock': int.parse(_stockController.text.trim()),
        'colors': _colorController.text.trim(),
        'postedBy': {
          'id': userId,
          'name': sellerName,
          'contact': sellerContact,
        },
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Product Added Successfully")));
      _formKey.currentState!.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Manage Products")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: "Product Name"),
                  validator: (value) => value!.isEmpty ? "Enter product name" : null,
                ),
                SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: "Category"),
                  value: selectedCategory,
                  items: categoryOptions.keys.map((category) {
                    return DropdownMenuItem(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                      selectedSubcategory = null;
                    });
                  },
                  validator: (value) => value == null ? "Select a category" : null,
                ),
                SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: "Subcategory"),
                  value: selectedSubcategory,
                  items: selectedCategory != null
                      ? categoryOptions[selectedCategory]!.map((sub) {
                    return DropdownMenuItem(value: sub, child: Text(sub));
                  }).toList()
                      : [],
                  onChanged: (value) {
                    setState(() {
                      selectedSubcategory = value;
                    });
                  },
                  validator: (value) => value == null ? "Select a subcategory" : null,
                ),
                SizedBox(height: 10),

                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: "Description"),
                  validator: (value) => value!.isEmpty ? "Enter product description" : null,
                ),
                SizedBox(height: 10),

                Row(
                  children: [
                    Checkbox(
                      value: isExpiryApplicable,
                      onChanged: (value) {
                        setState(() {
                          isExpiryApplicable = value!;
                        });
                      },
                    ),
                    Text("Has Expiry Date"),
                  ],
                ),
                if (isExpiryApplicable)
                  TextFormField(
                    controller: _expiryController,
                    decoration: InputDecoration(labelText: "Expiry Date (DD/MM/YYYY)"),
                    validator: (value) {
                      if (isExpiryApplicable && value!.isEmpty) {
                        return "Enter expiry date";
                      }
                      return null;
                    },
                  ),
                SizedBox(height: 10),

                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(labelText: "Price"),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? "Enter price" : null,
                ),
                SizedBox(height: 10),

                TextFormField(
                  controller: _stockController,
                  decoration: InputDecoration(labelText: "Stock Quantity"),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? "Enter stock quantity" : null,
                ),
                SizedBox(height: 10),

                TextFormField(
                  controller: _colorController,
                  decoration: InputDecoration(labelText: "Available Colors (comma separated)"),
                ),
                SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _addProduct,
                  child: Text("Add Product"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
