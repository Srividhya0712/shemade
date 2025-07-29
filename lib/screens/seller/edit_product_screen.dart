import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  EditProductScreen({required this.productId, required this.productData});

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  String? _selectedCategory;
  String? _selectedSubcategory;
  List<String> _imageUrls = [];  // Changed from String? to List<String>
  List<File> _newImages = [];  // New images to be uploaded
  bool _isUploading = false;

  final Map<String, List<String>> categorySubcategory = {
    'Plants': [],
    'Clothes': ['Men', 'Women', 'Child'],
    'Art & Crafts': [],
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.productData['name']);
    _priceController = TextEditingController(text: widget.productData['price'].toString());
    _stockController = TextEditingController(text: widget.productData['stockQuantity'].toString());

    _selectedCategory = widget.productData['category'];
    _selectedSubcategory = widget.productData['subcategory'];
    _imageUrls = List<String>.from(widget.productData['imageUrls'] ?? []);
  }

  // Pick new images
  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _newImages.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  // Remove existing image
  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  // Remove new image
  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  // Upload new images to Firebase Storage
  Future<List<String>> _uploadNewImages() async {
    List<String> newImageUrls = [];
    for (var image in _newImages) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '_${_newImages.indexOf(image)}';
      try {
        Reference storageRef = FirebaseStorage.instance.ref().child('products/$fileName.jpg');
        UploadTask uploadTask = storageRef.putFile(image);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        newImageUrls.add(downloadUrl);
      } catch (e) {
        print("Error uploading image: $e");
      }
    }
    return newImageUrls;
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUploading = true;
      });

      try {
        List<String> newImageUrls = await _uploadNewImages();
        List<String> allImageUrls = [..._imageUrls, ...newImageUrls];

        await FirebaseFirestore.instance.collection('products').doc(widget.productId).update({
          'name': _nameController.text.trim(),
          'price': double.parse(_priceController.text.trim()),
          'stockQuantity': int.parse(_stockController.text.trim()),
          'category': _selectedCategory,
          'subcategory': _selectedSubcategory,
          'imageUrls': allImageUrls,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product Updated Successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        print('Error updating product: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update product')),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Product')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Existing Images
              if (_imageUrls.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Existing Images:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Container(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imageUrls.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                margin: EdgeInsets.only(right: 10),
                                width: 150,
                                child: Image.network(_imageUrls[index], fit: BoxFit.cover),
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
                    SizedBox(height: 20),
                  ],
                ),

              // New Images
              if (_newImages.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Images:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Container(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _newImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                margin: EdgeInsets.only(right: 10),
                                width: 150,
                                child: Image.file(_newImages[index], fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed: () => _removeNewImage(index),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),

              TextButton.icon(
                icon: Icon(Icons.image),
                label: Text('Add More Images'),
                onPressed: _pickImages,
              ),
              SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Product Name'),
                validator: (value) => value!.isEmpty ? 'Enter product name' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter price' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _stockController,
                decoration: InputDecoration(labelText: 'Stock Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter stock quantity' : null,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(labelText: 'Category'),
                items: categorySubcategory.keys.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _selectedSubcategory = null;
                  });
                },
              ),
              if (_selectedCategory != null && categorySubcategory[_selectedCategory]!.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedSubcategory,
                  decoration: InputDecoration(labelText: 'Subcategory'),
                  items: categorySubcategory[_selectedCategory]!.map((subcategory) {
                    return DropdownMenuItem(value: subcategory, child: Text(subcategory));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubcategory = value;
                    });
                  },
                ),
              SizedBox(height: 20),
              Center(
                child: _isUploading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _updateProduct,
                        child: Text('Update Product'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
