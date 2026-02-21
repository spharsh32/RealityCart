import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:reality_cart/services/fcm_service.dart';

class AddProductScreen extends StatefulWidget {
  final String? productId;
  final Map<String, dynamic>? initialData;

  const AddProductScreen({super.key, this.productId, this.initialData});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;
  late TextEditingController _stockController;
  late TextEditingController _descController;
  late TextEditingController _arModelController;
  
  // Multiple Image Controllers
  late List<TextEditingController> _imageControllers;

  // State
  String _selectedCategory = 'Electronics';
  final List<String> _categories = ['Electronics', 'Fashion', 'Home', 'Books', 'Toys', 'Accessories'];
  bool _isFeatured = false;
  
  // Variants: List of {type: 'Size', values: ['S', 'M']}
  List<Map<String, dynamic>> _variants = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?['name'] ?? '');
    _priceController = TextEditingController(text: widget.initialData?['price']?.toString() ?? '');
    _discountController = TextEditingController(text: widget.initialData?['discount']?.toString() ?? '0');
    _stockController = TextEditingController(text: widget.initialData?['stock']?.toString() ?? '10');
    _descController = TextEditingController(text: widget.initialData?['description'] ?? '');
    _arModelController = TextEditingController(text: widget.initialData?['arModelUrl'] ?? '');
    _selectedCategory = widget.initialData?['category'] ?? 'Electronics';
    _isFeatured = widget.initialData?['isFeatured'] ?? false;

    if (widget.initialData?['variants'] != null) {
      _variants = List<Map<String, dynamic>>.from(widget.initialData!['variants']);
    }

    final List<dynamic>? initialImages = widget.initialData?['imageUrls'];
    if (initialImages != null && initialImages.isNotEmpty) {
      _imageControllers = initialImages
          .map((url) => TextEditingController(text: url.toString()))
          .toList();
    } else {
      _imageControllers = [TextEditingController()];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    _descController.dispose();
    _arModelController.dispose();
    for (var controller in _imageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFromDrive(int index) async {
    try {
      final googleSignIn = GoogleSignIn(scopes: [drive.DriveApi.driveReadonlyScope]);
      final account = await googleSignIn.signIn();
      
      if (account == null) return;

      final authHeaders = await account.authHeaders;
      final authenticateClient = _GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      // Show a file picker dialog
      if (!mounted) return;
      final selectedFile = await showDialog<drive.File>(
        context: context,
        builder: (context) => _DriveFilePicker(driveApi: driveApi),
      );

      if (selectedFile != null && selectedFile.id != null) {
        // Construct the direct display link
        final link = "https://lh3.googleusercontent.com/u/0/d/${selectedFile.id}=w1000";
        
        setState(() {
          _imageControllers[index].text = link;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Drive Error: $e")),
        );
      }
    }
  }

  void _addImageField() {
    setState(() {
      _imageControllers.add(TextEditingController());
    });
  }

  void _removeImageField(int index) {
    if (_imageControllers.length > 1) {
      setState(() {
        _imageControllers[index].dispose();
        _imageControllers.removeAt(index);
      });
    }
  }

  void _addVariant() {
    setState(() {
      _variants.add({'type': '', 'values': ''});
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        List<String> imageUrls = _imageControllers
            .map((c) => c.text.trim())
            .where((t) => t.isNotEmpty)
            .toList();

        final productData = {
          'name': _nameController.text.trim(),
          'price': double.parse(_priceController.text.trim()),
          'discount': double.tryParse(_discountController.text.trim()) ?? 0.0,
          'stock': int.tryParse(_stockController.text.trim()) ?? 0,
          'category': _selectedCategory,
          'description': _descController.text.trim(),
          'imageUrls': imageUrls,
          'arModelUrl': _arModelController.text.trim(),
          'isFeatured': _isFeatured,
          'variants': _variants,
          if (widget.productId == null) 'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (widget.productId != null) {
          await FirebaseFirestore.instance
              .collection('products')
              .doc(widget.productId)
              .update(productData);
        } else {
          await FirebaseFirestore.instance.collection('products').add(productData);
          
          await FCMService.sendGlobalNotification(
            "New Product Alert!",
            "Check out our new ${_nameController.text.trim()} in $_selectedCategory!",
            "promo",
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.productId != null ? "Product updated successfully!" : "Product added successfully!")),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const brandOrange = Color(0xFFFB8C00);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.productId != null ? "Edit Product" : "Add New Product", 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: brandOrange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, "Basic Information"),
                  const SizedBox(height: 15),
                  _buildTextField(context, "Product Name", _nameController, Icons.label),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(context, "Price (₹)", _priceController, Icons.currency_rupee, isNumber: true)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildTextField(context, "Discount (%)", _discountController, Icons.percent, isNumber: true)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                     children: [
                       Expanded(child: _buildTextField(context, "Stock Quantity", _stockController, Icons.inventory, isNumber: true)),
                       const SizedBox(width: 15),
                       Expanded(child: _buildDropdown(context)),
                     ],
                  ),
                  const SizedBox(height: 15),
                  SwitchListTile(
                    title: const Text("Mark as Featured"),
                    value: _isFeatured,
                    onChanged: (val) => setState(() => _isFeatured = val),
                    activeColor: brandOrange,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(context, "Description", _descController, Icons.description, maxLines: 3),
                  
                  const SizedBox(height: 30),
                  _buildSectionTitle(context, "Variants"),
                  const SizedBox(height: 10),
                  ..._variants.asMap().entries.map((entry) {
                    int index = entry.key;
                    // MapEntry<String, dynamic> variant = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                initialValue: _variants[index]['type'],
                                decoration: const InputDecoration(labelText: "Type (e.g. Size, Color)"),
                                onChanged: (val) => _variants[index]['type'] = val,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                initialValue: _variants[index]['values'],
                                decoration: const InputDecoration(labelText: "Values (comma separated)"),
                                onChanged: (val) => _variants[index]['values'] = val,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeVariant(index),
                            )
                          ],
                        ),
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: _addVariant,
                    icon: const Icon(Icons.add_circle),
                    label: const Text("Add Variant"),
                    style: TextButton.styleFrom(foregroundColor: brandOrange),
                  ),

                  const SizedBox(height: 20),
                  _buildSectionTitle(context, "Product Images"),
                  const SizedBox(height: 10),
                  Text(
                    "Select images from your Google Drive.",
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                  const SizedBox(height: 15),
                  
                  ..._imageControllers.asMap().entries.map((entry) {
                    int index = entry.key;
                    TextEditingController controller = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: "Drive Image Link ${index + 1}",
                                prefixIcon: const Icon(Icons.image, color: brandOrange),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                filled: true,
                                fillColor: theme.cardColor,
                                suffixIcon: IconButton(
                                  icon: const Icon(FontAwesomeIcons.googleDrive, color: Colors.blue),
                                  onPressed: () => _pickFromDrive(index),
                                  tooltip: "Pick from Drive",
                                ),
                              ),
                              validator: (value) => (value == null || value.isEmpty) ? 'Link required' : null,
                            ),
                          ),
                          const SizedBox(width: 5),
                          if (_imageControllers.length > 1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _removeImageField(index),
                            ),
                        ],
                      ),
                    );
                  }),
                  
                  if (!_isLoading)
                    TextButton.icon(
                      onPressed: _addImageField,
                      icon: const Icon(Icons.add_circle, color: brandOrange),
                      label: const Text("Add Another Image Slot", style: TextStyle(color: brandOrange)),
                    ),

                  const SizedBox(height: 30),
                  _buildSectionTitle(context, "AR & Media"),
                  const SizedBox(height: 15),
                  
                  Text("3D Model (GLB/GLTF)", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _arModelController,
                    decoration: InputDecoration(
                      hintText: "Enter URL for .glb file",
                      prefixIcon: const Icon(FontAwesomeIcons.cube, color: brandOrange),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: theme.cardColor,
                      suffixIcon: IconButton(
                        icon: const Icon(FontAwesomeIcons.googleDrive, color: Colors.blue),
                        onPressed: () {
                           // Allow picking AR model from drive too if needed
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(widget.productId != null ? "Update Product" : "Save Product", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: brandOrange)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title, 
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
    );
  }

  Widget _buildTextField(BuildContext context, String label, TextEditingController controller, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFFB8C00)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: theme.cardColor,
      ),
      validator: (value) => (value == null || value.isEmpty) ? 'Enter $label' : null,
    );
  }

  Widget _buildDropdown(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: InputDecoration(
        labelText: "Category",
        prefixIcon: const Icon(Icons.category, color: Color(0xFFFB8C00)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: theme.cardColor,
      ),
      items: _categories.map((String category) => DropdownMenuItem<String>(value: category, child: Text(category))).toList(),
      onChanged: (String? newValue) => setState(() => _selectedCategory = newValue!),
    );
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class _DriveFilePicker extends StatefulWidget {
  final drive.DriveApi driveApi;
  const _DriveFilePicker({required this.driveApi});

  @override
  State<_DriveFilePicker> createState() => _DriveFilePickerState();
}

class _DriveFilePickerState extends State<_DriveFilePicker> {
  List<drive.File> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    try {
      final list = await widget.driveApi.files.list(
        q: "mimeType contains 'image/'",
        spaces: 'drive',
        $fields: 'files(id, name, thumbnailLink, webViewLink)',
      );
      setState(() {
        _files = list.files ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      backgroundColor: theme.cardColor,
      title: Text("Select Image from Drive", style: theme.textTheme.titleLarge),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: _loading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFB8C00)))
          : _files.isEmpty 
            ? const Center(child: Text("No images found"))
            : ListView.builder(
                itemCount: _files.length,
                itemBuilder: (context, index) {
                  final file = _files[index];
                  return ListTile(
                    leading: file.thumbnailLink != null 
                      ? Image.network(file.thumbnailLink!, width: 40)
                      : Icon(Icons.image, color: theme.disabledColor),
                    title: Text(file.name ?? "Unnamed File", style: theme.textTheme.bodyMedium),
                    onTap: () => Navigator.pop(context, file),
                  );
                },
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Color(0xFFFB8C00)))),
      ],
    );
  }
}
