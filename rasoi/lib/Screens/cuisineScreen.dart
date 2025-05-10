import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rasoi/Screens/recipeScreen.dart';
import '../models/favorite_manager.dart';

class CuisineScreen extends StatefulWidget {
  final String cuisine;

  CuisineScreen({required this.cuisine});

  @override
  _CuisineScreenState createState() => _CuisineScreenState();
}

class _CuisineScreenState extends State<CuisineScreen> {
  List<Map<String, dynamic>> cuisineRecipes = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCuisineRecipes();
  }

  Future<bool> isFavorite(int recipeId) async {
    return await FavoriteManager.isFavorite(recipeId);
  }

  Future<void> fetchCuisineRecipes() async {
    const apiKey = '6897bd7bab874a6ab90d4f5d092a4b71';
    final url = Uri.parse(
      'https://api.spoonacular.com/recipes/complexSearch?cuisine=${widget.cuisine}&number=10&apiKey=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          setState(() {
            cuisineRecipes = List<Map<String, dynamic>>.from(data['results']);
          });
        }
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching recipes: $e");
    }
  }

  Future<void> searchRecipes(String query) async {
    const apiKey = '6897bd7bab874a6ab90d4f5d092a4b71';
    final url = Uri.parse(
      'https://api.spoonacular.com/recipes/complexSearch?query=$query&cuisine=${widget.cuisine}&number=10&apiKey=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          setState(() {
            cuisineRecipes = List<Map<String, dynamic>>.from(data['results']);
          });
        }
      } else {
        print("Search error: ${response.statusCode}");
      }
    } catch (e) {
      print("Search error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("${widget.cuisine} Recipes"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Glassmorphism background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.3),
                  Colors.blueGrey,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.only(top: kToolbarHeight+65, left: 16, right: 16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: searchController,
                  cursorColor: Colors.white,
                  style: TextStyle(color: Colors.white),
                  onChanged: (value) {
                    if (value.trim().isNotEmpty) {
                      searchRecipes(value.trim());
                    } else {
                      fetchCuisineRecipes();
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
                SizedBox(height: 16), // Add this to control the spacing
                Expanded(
                  child: cuisineRecipes.isEmpty
                      ? Center(child: CircularProgressIndicator(color: Colors.white))
                      : GridView.builder(
                    itemCount: cuisineRecipes.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 3 / 4,
                    ),
                    itemBuilder: (context, index) {
                      final recipe = cuisineRecipes[index];
                      return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecipeDetailScreen(
                                  recipeId: recipe['id'].toString(),
                                ),
                              ),
                            );
                          },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                  child: Image.network(
                                    recipe['image'],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  recipe['title'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: FutureBuilder<bool>(
                                  key: ValueKey(recipe['id'].toString() + DateTime.now().toString()),
                                  future: isFavorite(recipe['id']),
                                  builder: (context, snapshot) {
                                    final isFav = snapshot.data ?? false;
                                    return IconButton(
                                      icon: Icon(
                                        isFav ? Icons.favorite : Icons.favorite_border,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () async {
                                        if (isFav) {
                                          await FavoriteManager.removeFavorite(recipe['id']);
                                        } else {
                                          await FavoriteManager.addFavorite(recipe);
                                        }
                                        setState(() {}); // Refresh
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
