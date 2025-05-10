import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rasoi/Screens/recipeScreen.dart';
import 'package:rasoi/models/favorite_manager.dart';

import 'cuisineScreen.dart';
import 'favoritesScreen.dart';
import 'groceryScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isVeg = true;
  List<Map<String, dynamic>> famousRecipes = [];
  TextEditingController searchController = TextEditingController();
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    fetchFamousRecipes();
    _timer = Timer.periodic(Duration(minutes: 30), (timer) {
      fetchFamousRecipes();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> searchRecipes(String query) async {
    const apiKey = '6897bd7bab874a6ab90d4f5d092a4b71';
    final dietParam = isVeg ? '&diet=vegetarian' : '';
    final url = Uri.parse(
      'https://api.spoonacular.com/recipes/complexSearch?query=$query&number=10&addRecipeInformation=true$dietParam&apiKey=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null) {
          setState(() {
            famousRecipes = List<Map<String, dynamic>>.from(data['results']);
          });
        }
      } else {
        print("Search Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Search Exception: $e");
    }
  }

  Future<void> fetchFamousRecipes({bool append = false}) async {
    const apiKey = '6897bd7bab874a6ab90d4f5d092a4b71';
    final url = Uri.parse(
      'https://api.spoonacular.com/recipes/random?number=10&tags=${isVeg ? "vegetarian" : "main course"}&apiKey=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['recipes'] != null) {
          setState(() {
            if (append) {
              famousRecipes.addAll(List<Map<String, dynamic>>.from(data['recipes']));
            } else {
              famousRecipes = List<Map<String, dynamic>>.from(data['recipes']);
            }
          });
        }
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Fetch error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Scaffold(
            backgroundColor: Colors.transparent.withOpacity(.3),
            appBar: AppBar(
              title: Text(
                "𝚁𝚊𝚜𝚘𝚒",
                style: TextStyle(fontSize: 30, color: Colors.white),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            drawer: Drawer(
              backgroundColor: Colors.blueGrey.withOpacity(0.5),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(height: 50),
                  ...[
                    ListTile(
                      leading: Icon(Icons.home, color: Colors.white),
                      title: Text('Home', style: TextStyle(color: Colors.white)),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      leading: Icon(Icons.favorite, color: Colors.white),
                      title: Text('Favorites', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => FavoritesScreen()));
                      },
                    ),
                    ExpansionTile(
                      leading: Icon(Icons.category, color: Colors.white),
                      title: Text('Categories', style: TextStyle(color: Colors.white)),
                      children: allCategories.map((category) {
                        return ListTile(
                          leading: Icon(category["icon"], color: Colors.white),
                          title: Text(category["title"], style: TextStyle(color: Colors.white)),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CuisineScreen(cuisine: category["title"]),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            body: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: searchController,
                        cursorColor: Colors.white,
                        style: TextStyle(color: Colors.white),
                        onChanged: (value) {
                          if (value.trim().isNotEmpty) {
                            searchRecipes(value.trim());
                          } else {
                            fetchFamousRecipes();
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
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text("Non-Veg", style: TextStyle(color: Colors.white)),
                          Switch(
                            value: isVeg,
                            onChanged: (val) {
                              setState(() {
                                isVeg = val;
                                fetchFamousRecipes();
                              });
                            },
                            activeColor: Colors.greenAccent,
                            inactiveThumbColor: Colors.red,
                            inactiveTrackColor: Colors.red.shade300,
                          ),
                          Text("Veg", style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: famousRecipes.isEmpty
                            ? Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                            : GridView.builder(
                          itemCount: famousRecipes.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 3 / 4,
                          ),
                          itemBuilder: (context, index) {
                            final recipe = famousRecipes[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RecipeDetailScreen(recipeId: recipe['id'].toString()),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: Image.network(
                                              recipe['image'],
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              recipe['title'],
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: FutureBuilder<bool>(
                                          future: FavoriteManager.isFavorite(recipe['id']),
                                          builder: (context, snapshot) {
                                            final isFav = snapshot.data ?? false;
                                            return IconButton(
                                              icon: Icon(
                                                isFav ? Icons.favorite : Icons.favorite_border,
                                                color: Colors.white,
                                              ),
                                              onPressed: () async {
                                                if (isFav) {
                                                  await FavoriteManager.removeFavorite(recipe['id']);
                                                } else {
                                                  await FavoriteManager.addFavorite(recipe);
                                                }
                                                setState(() {});
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: FloatingActionButton.extended(
                    backgroundColor: Colors.blueGrey.withOpacity(0.7),
                    onPressed: () => fetchFamousRecipes(append: true),
                    icon: Icon(Icons.refresh, color: Colors.white),
                    label: Text("Load More", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),

            floatingActionButton: FloatingActionButton(
              backgroundColor: Colors.blueGrey.withOpacity(0.7),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GroceryListScreen()),
                );
              },
              child: Icon(Icons.shopping_basket, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  final List<Map<String, dynamic>> allCategories = [
    {"title": "African", "icon": Icons.public},
    {"title": "American", "icon": Icons.flag},
    {"title": "British", "icon": Icons.cake},
    {"title": "Cajun", "icon": Icons.local_dining},
    {"title": "Caribbean", "icon": Icons.emoji_food_beverage},
    {"title": "Chinese", "icon": Icons.ramen_dining},
    {"title": "Eastern European", "icon": Icons.restaurant},
    {"title": "European", "icon": Icons.public},
    {"title": "French", "icon": Icons.bakery_dining},
    {"title": "German", "icon": Icons.emoji_food_beverage},
    {"title": "Greek", "icon": Icons.lunch_dining},
    {"title": "Indian", "icon": Icons.spa},
    {"title": "Irish", "icon": Icons.local_bar},
    {"title": "Italian", "icon": Icons.local_pizza},
    {"title": "Japanese", "icon": Icons.ramen_dining},
    {"title": "Jewish", "icon": Icons.dinner_dining},
    {"title": "Korean", "icon": Icons.kebab_dining},
    {"title": "Latin American", "icon": Icons.rice_bowl},
    {"title": "Mediterranean", "icon": Icons.grass},
    {"title": "Mexican", "icon": Icons.local_dining},
    {"title": "Middle Eastern", "icon": Icons.breakfast_dining},
    {"title": "Nordic", "icon": Icons.ac_unit},
    {"title": "Southern", "icon": Icons.soup_kitchen},
    {"title": "Spanish", "icon": Icons.dinner_dining},
    {"title": "Thai", "icon": Icons.ramen_dining},
    {"title": "Vietnamese", "icon": Icons.lunch_dining},
  ];
}
