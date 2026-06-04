import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/dummy_data.dart';
import '../../../core/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddEditItemScreen extends StatefulWidget {
  final String? itemId;
  const AddEditItemScreen({super.key, this.itemId});

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _image;
  bool _isAvailable = true;
  String _selectedCategory = 'Coffee';
  
  final List<String> _categories = ['Coffee', 'Food', 'Snacks', 'Drinks', 'Desserts'];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Item' : 'Add New Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker Box
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!, style: BorderStyle.none),
                  ),
                  child: _image != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('Tap to add photo', style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                ),
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'e.g. Hazelnut Latte',
                ),
                validator: (value) => value!.isEmpty ? 'Please enter name' : null,
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: 'PKR ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Please enter price' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              SwitchListTile(
                title: const Text('Available'),
                subtitle: const Text('Toggle item visibility in the menu'),
                value: _isAvailable,
                activeColor: AppTheme.secondaryColor,
                onChanged: (value) => setState(() => _isAvailable = value),
              ),
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Saving item...')),
                    );
                    context.pop();
                  }
                },
                child: Text(isEditing ? 'Save Changes' : 'Add Item'),
              ),
              
              if (isEditing) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Item'),
                        content: const Text('Are you sure you want to remove this item from the menu?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      DummyData.removeProduct(widget.itemId!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Item deleted')),
                      );
                      context.pop();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Delete Item'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
