import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shemadev2/screens/seller/sellerHome.dart';

class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final List<TextEditingController> _colorControllers = [];

  String? _selectedCategory;
  String? _selectedSubcategory;
  DateTime? _expiryDate;
  List<File> _images = [];
  bool _isUploading = false;

  final List<String> categories = ['Plants', 'Clothes', 'Art & Crafts'];
  final Map<String, List<String>> subcategories = {
    'Clothes': ['Men', 'Women', 'Child'],
    'Plants': ['Indoor', 'Outdoor'],
    'Art & Crafts': ['Handmade', 'Decorative']
  };

  // Pick Image
  Future<void> _pickImage() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  // Remove Image
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  // Pick Expiry Date (Optional)
  Future<void> _pickExpiryDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _expiryDate = pickedDate;
      });
    }
  }

  // Upload Images to Firebase Storage
  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    for (var image in _images) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '_${_images.indexOf(image)}';
      try {
        // Create storage reference
        Reference storageRef = FirebaseStorage.instance.ref().child('products/$fileName.jpg');

        // Set metadata
        SettableMetadata metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'picked-file-path': image.path}
        );

        // Upload file with metadata
        UploadTask uploadTask = storageRef.putFile(image, metadata);

        // Listen for state changes
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          print('Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
        }, onError: (e) {
          print('Upload error: $e');
        });

        // Wait for upload to complete
        TaskSnapshot snapshot = await uploadTask;
        
        // Get download URL
        String downloadUrl = await snapshot.ref.getDownloadURL();
        
        // Validate URL format
        Uri uri = Uri.parse(downloadUrl);
        if (!uri.isAbsolute) {
          throw Exception('Invalid URL format');
        }

        imageUrls.add(downloadUrl);
        print('Successfully uploaded image: $downloadUrl');
      } catch (e) {
        print("Error uploading image: $e");
        // Show error in UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
        );
      }
    }
    return imageUrls;
  }

  // Submit Product
  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please upload at least one image!')));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    List<String> imageUrls = await _uploadImages();
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User not logged in!')));
      return;
    }

    String sellerName = user.displayName ?? "Unknown Seller";

    try {
      // Create a new document reference
      DocumentReference productRef = FirebaseFirestore.instance.collection('products').doc();
      
      // Create the product with the document ID
      await productRef.set({
        'id': productRef.id, // Set the ID field
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'subcategory': _selectedSubcategory,
        'description': _descriptionController.text.trim(),
        'expiryDate': _expiryDate != null ? Timestamp.fromDate(_expiryDate!) : null,
        'price': double.parse(_priceController.text.trim()),
        'stockQuantity': int.parse(_stockController.text.trim()),
        'initialStock': int.parse(_stockController.text.trim()),
        'colors': _colorControllers.map((controller) => controller.text.trim()).toList(),
        'imageUrls': imageUrls,
        'sellerId': user.uid,
        'sellerName': sellerName,
        'sellerContact': user.email ?? '',
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product added successfully!')));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SellerHome()),
      );

    } catch (e) {
      print('Error adding product: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add product!')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Product')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Product Name'),
                validator: (value) => value!.isEmpty ? 'Enter product name' : null,
              ),
              SizedBox(height: 10),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: categories.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                decoration: InputDecoration(labelText: 'Category'),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _selectedSubcategory = null;
                  });
                },
              ),

              // Subcategory Dropdown
              if (_selectedCategory != null && subcategories.containsKey(_selectedCategory))
                DropdownButtonFormField<String>(
                  value: _selectedSubcategory,
                  items: subcategories[_selectedCategory]!.map((sub) {
                    return DropdownMenuItem(value: sub, child: Text(sub));
                  }).toList(),
                  decoration: InputDecoration(labelText: 'Subcategory'),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubcategory = value;
                    });
                  },
                ),

              SizedBox(height: 10),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(labelText: 'Description'),
                validator: (value) => value!.isEmpty ? 'Enter description' : null,
              ),
              SizedBox(height: 10),

              // Expiry Date Picker (Optional)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _expiryDate == null
                          ? 'No expiry date selected'
                          : 'Expiry Date: ${DateFormat('yyyy-MM-dd').format(_expiryDate!)}',
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.calendar_today),
                    label: Text('Pick Date'),
                    onPressed: _pickExpiryDate,
                  ),
                ],
              ),

              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Price'),
                validator: (value) => value!.isEmpty ? 'Enter price' : null,
              ),
              SizedBox(height: 10),

              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Stock Quantity'),
                validator: (value) => value!.isEmpty ? 'Enter stock quantity' : null,
              ),
              SizedBox(height: 10),

              // Image Upload
              if (_images.isNotEmpty)
                Container(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 10),
                            width: 150,
                            child: Image.file(_images[index], fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () => _removeImage(index),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              TextButton.icon(
                icon: Icon(Icons.image),
                label: Text('Upload Images'),
                onPressed: _pickImage,
              ),
              SizedBox(height: 10),

              // Colors Input
              Text('Colors:'),
              ..._colorControllers.asMap().entries.map((entry) {
                int index = entry.key;
                TextEditingController controller = entry.value;
                return TextFormField(
                  controller: controller,
                  decoration: InputDecoration(labelText: 'Color ${index + 1}'),
                );
              }).toList(),

              TextButton.icon(
                icon: Icon(Icons.add),
                label: Text('Add Color'),
                onPressed: () => setState(() => _colorControllers.add(TextEditingController())),
              ),

              SizedBox(height: 20),
              _isUploading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _submitProduct,
                child: Text('ADD Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
