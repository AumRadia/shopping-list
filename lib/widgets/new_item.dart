import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shoppinglist/data/categories.dart';
import 'package:shoppinglist/models/category.dart';
import 'package:http/http.dart' as http;
import 'package:shoppinglist/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final _formkey = GlobalKey<FormState>();
  var _enteredname = '';
  var _enteredquantity = 1;
  var _selectedcategory = categories[Categories.vegetables]!;
  var issending = false;

  void _saveitem() async {
    if (_formkey.currentState!.validate()) {
      _formkey.currentState!.save();

      setState(() {
        issending = true;
      });
      final url = Uri.https('shopping-list-adf5d-default-rtdb.firebaseio.com',
          'shopping-list.json');
      final response = await http.post(url,
          headers: {'content-type': 'application/json'},
          body: json.encode({
            'name': _enteredname,
            'quantity': _enteredquantity,
            'category': _selectedcategory.title
          }));

      final Map<String, dynamic> resdaata = json.decode(response.body);

      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop(GroceryItem(
          id: resdaata['name'],
          name: _enteredname,
          quantity: _enteredquantity,
          category: _selectedcategory));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add new item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formkey,
          child: Column(
            children: [
              TextFormField(
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length <= 1 ||
                      value.trim().length > 50) {
                    return 'Must be B/W 1 to 50 characters';
                  }
                  return null;
                },
                onSaved: (value) {
                  _enteredname = value!;
                },
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: '1',
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return 'Must be a valid positive number';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _enteredquantity = int.parse(value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Category>(
                      value: _selectedcategory,
                      items: [
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: category.value.color,
                                ),
                                const SizedBox(width: 6),
                                Text(category.value.title),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedcategory = value!;
                        });
                      },
                      onSaved: (value) {
                        _selectedcategory = value!;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 11, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed:
                        issending ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: issending ? null : _saveitem,
                    child: issending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator())
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
