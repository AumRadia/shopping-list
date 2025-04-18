import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shoppinglist/data/categories.dart';
import 'package:shoppinglist/models/grocery_item.dart';
import 'package:shoppinglist/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryitems = [];
  var isloading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loaditems();
  }

  void _loaditems() async {
    final url = Uri.https('shopping-list-adf5d-default-rtdb.firebaseio.com',
        'shopping-list.json');

    final response = await http.get(url);

    try {
      if (response.statusCode >= 400) {
        setState(() {
          error = 'Failed to fetch data';
        });
        return;
      }

      if (response.body == 'null') {
        setState(() {
          isloading = false;
        });
        return;
      }

      final Map<String, dynamic> listdata = json.decode(response.body);
      final List<GroceryItem> _loadeditems = [];

      for (final item in listdata.entries) {
        final category = categories.entries
            .firstWhere(
                (catitem) => catitem.value.title == item.value['category'])
            .value;

        _loadeditems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }

      setState(() {
        _groceryitems = _loadeditems;
        isloading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to fetch data';
      });
    }
  }

  void _additem() async {
    final newitem = await Navigator.of(context)
        .push(MaterialPageRoute(builder: (ctx) => const NewItem()));

    if (newitem == null) {
      return;
    }
    setState(() {
      _groceryitems.add(newitem);
    });
  }

  void _removeitem(GroceryItem item) async {
    final index = _groceryitems.indexOf(item);

    setState(() {
      _groceryitems.remove(item);
    });

    final url = Uri.https('shopping-list-adf5d-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryitems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (isloading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (error != null) {
      content = Center(
        child: Text(
          error!,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    } else if (_groceryitems.isEmpty) {
      content = const Center(
        child: Text(
          '🧺 Your grocery list is empty!',
          style: TextStyle(fontSize: 16),
        ),
      );
    } else {
      content = ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _groceryitems.length,
        itemBuilder: (ctx, index) {
          final item = _groceryitems[index];
          return Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              color: Colors.redAccent,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => _removeitem(item),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Container(
                  width: 6,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: item.category.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Text(
                  'x${item.quantity}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🛒 Grocery List'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _additem,
        label: const Text('Add Item'),
        icon: const Icon(Icons.add),
      ),
      body: content,
    );
  }
}
