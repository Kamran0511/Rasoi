import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GroceryListScreen extends StatefulWidget {
  @override
  _GroceryListScreenState createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  List<Map<String, String>> groceryItems = [];
  final TextEditingController controller = TextEditingController();
  final List<dynamic> searchResults = [];
  bool isSearching = false;
  Set<int> selectedItems = Set<int>();

  @override
  void initState() {
    super.initState();
    loadSavedList();
  }

  Future<void> loadSavedList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('groceryList');
    if (savedData != null) {
      List<dynamic> decoded = json.decode(savedData);
      setState(() {
        groceryItems = decoded.map((e) => Map<String, String>.from(e)).toList();
      });
    }
  }

  Future<void> saveList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(groceryItems);
    await prefs.setString('groceryList', encoded);
  }

  Future<void> searchIngredient(String query) async {
    if (query.trim().isEmpty) return;

    final url = Uri.parse(
      'https://api.spoonacular.com/food/ingredients/search?query=${Uri.encodeComponent(query)}&number=10&apiKey=6897bd7bab874a6ab90d4f5d092a4b71',
    );

    setState(() => isSearching = true);

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      setState(() {
        searchResults.clear();
        if (result['results'] != null) {
          searchResults.addAll(result['results']);
        }
        isSearching = false;
      });
    } else {
      print("Error: ${response.statusCode}");
      setState(() => isSearching = false);
    }
  }

  void addItem(String name, String imageUrl) {
    setState(() {
      groceryItems.add({"name": name, "image": imageUrl});
      controller.clear();
      searchResults.clear();
    });
    saveList();
  }

  void removeItem(int index) {
    setState(() {
      groceryItems.removeAt(index);
    });
    saveList();
  }

  void deleteSelectedItems() {
    setState(() {
      groceryItems.removeWhere(
              (item) => selectedItems.contains(groceryItems.indexOf(item)));
      selectedItems.clear();
    });
    saveList();
  }

  void toggleSelection(int index) {
    setState(() {
      if (selectedItems.contains(index)) {
        selectedItems.remove(index);
      } else {
        selectedItems.add(index);
      }
    });
  }

  void deleteAll() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('groceryList');
    setState(() {
      groceryItems.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Grocery List"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (selectedItems.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_forever),
              onPressed: deleteSelectedItems,
              tooltip: "Delete Selected",
            ),
        ],
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(.3),
                  Colors.blueGrey,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Glass layer
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
            child: Container(
              color: Colors.black.withOpacity(0.1),
            ),
          ),

          // Foreground content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Glass search bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: TextField(
                        controller: controller,
                        cursorColor: Colors.white,
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          if (value.trim().isNotEmpty) {
                            searchIngredient(value);
                          }
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          hintText: 'Search Recipes...',
                          hintStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(Icons.search, color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Search results or grocery list
                  Expanded(
                    child: isSearching
                        ? Center(child: CircularProgressIndicator(
                      color: Colors.white,
                    ))
                        : searchResults.isNotEmpty
                        ? ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final item = searchResults[index];
                        final imageUrl =
                            'https://spoonacular.com/cdn/ingredients_100x100/${item['image']}';
                        return ListTile(
                          leading: item['image'] != null
                              ? Image.network(imageUrl, width: 40, height: 40)
                              : Icon(Icons.shopping_basket, color: Colors.white),
                          title: Text(item['name'], style: TextStyle(color: Colors.white)),
                          trailing: IconButton(
                            icon: Icon(Icons.add, color: Colors.green),
                            onPressed: () => addItem(item['name'], imageUrl),
                          ),
                        );
                      },
                    )
                        : groceryItems.isNotEmpty
                        ? ListView.builder(
                      itemCount: groceryItems.length,
                      itemBuilder: (context, index) {
                        final item = groceryItems[index];
                        return GestureDetector(
                          onTap: () => toggleSelection(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:  selectedItems.contains(index) ? Colors.black38 : Colors.white.withOpacity(0.2),                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            item['image'] ?? '',
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Icon(Icons.image_not_supported,
                                                    size: 70, color: Colors.white54),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            item['name'] ?? '',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Colors.redAccent),
                                          onPressed: () => removeItem(index),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                        : Center(
                      child: Text(
                        "Start searching ingredients...",
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
