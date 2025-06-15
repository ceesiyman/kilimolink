import 'package:flutter/material.dart';
import '../model/tip_model.dart';
import '../model/tip_category_model.dart';
import '../service/api_service.dart';
import '../service/auth_storage_service.dart';

class CreateTipScreen extends StatefulWidget {
  @override
  _CreateTipScreenState createState() => _CreateTipScreenState();
}

class _CreateTipScreenState extends State<CreateTipScreen> {
  final ApiService apiService = ApiService();
  final AuthStorageService authStorage = AuthStorageService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  
  late Future<Map<String, dynamic>> _categoriesFuture;
  TipCategory? _selectedCategory;
  List<String> _tags = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = apiService.fetchTipCategoriesFromApi();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _createTip() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await apiService.createTipFromApi(
        title: _titleController.text,
        content: _contentController.text,
        categoryId: _selectedCategory!.id,
        tags: _tags,
        isFeatured: false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tip created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating tip: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Tip'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Tip Title *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter tip title';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Content
                    TextFormField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: 'Tip Content *',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 6,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter tip content';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Category Selection
                    Text(
                      'Category *',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _categoriesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error loading categories: ${snapshot.error}');
                        } else if (snapshot.hasData) {
                          final categories = snapshot.data!['categories'] as List<TipCategory>;
                          return DropdownButtonFormField<TipCategory>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            hint: Text('Select a category'),
                            items: categories.map((category) {
                              return DropdownMenuItem<TipCategory>(
                                value: category,
                                child: Text('${category.name} (${category.tipsCount} tips)'),
                              );
                            }).toList(),
                            onChanged: (TipCategory? value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                          );
                        }
                        return Text('No categories available');
                      },
                    ),
                    SizedBox(height: 16),

                    // Tags
                    Text(
                      'Tags',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _tagsController,
                            decoration: InputDecoration(
                              labelText: 'Add tag',
                              border: OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.add),
                                onPressed: _addTag,
                              ),
                            ),
                            onFieldSubmitted: (_) => _addTag(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (_tags.isNotEmpty) ...[
                      Text(
                        'Added Tags:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            deleteIcon: Icon(Icons.close, size: 16),
                            onDeleted: () => _removeTag(tag),
                            backgroundColor: Colors.green[50],
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Create Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createTip,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Create Tip',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 