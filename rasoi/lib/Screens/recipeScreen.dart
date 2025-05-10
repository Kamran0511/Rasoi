import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Map<String, dynamic>? recipe;
  List<dynamic> steps = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRecipeDetails();
  }

  Future<void> fetchRecipeDetails() async {
    final url = Uri.parse(
      'https://api.spoonacular.com/recipes/${widget.recipeId}/information?apiKey=6897bd7bab874a6ab90d4f5d092a4b71',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      List<dynamic> analyzed = data['analyzedInstructions'];
      if (analyzed.isNotEmpty) {
        steps = analyzed[0]['steps'];
      }

      setState(() {
        recipe = data;
        isLoading = false;
      });
    } else {
      print("Failed to fetch recipe: ${response.statusCode}");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Recipe Details"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Gradient background
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
          // Blur effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          // Main content
          isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.white))
              : recipe == null
              ? Center(
            child: Text(
              "No recipe data available",
              style: TextStyle(color: Colors.white70),
            ),
          )
              : SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + kToolbarHeight + 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recipe!['image'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(recipe!['image']),
                  ),
                SizedBox(height: 16),
                Text(
                  recipe!['title'] ?? 'No Title',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Dish Type: ${recipe!['dishTypes']?.join(', ') ?? 'Unknown'}",
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  "Ready in: ${recipe!['readyInMinutes']} mins",
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  "Servings: ${recipe!['servings'] ?? 'N/A'}",
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 20),
                Text(
                  "Ingredients",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white),
                ),
                SizedBox(height: 8),
                ...?recipe!['extendedIngredients']?.map<Widget>((ingredient) {
                  return Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      "- ${ingredient['original']}",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }).toList(),
                SizedBox(height: 20),
                Text(
                  "Instructions (Step-by-step)",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white),
                ),
                SizedBox(height: 8),
                steps.isNotEmpty
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: steps.map((step) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6.0),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${step['number']}. ",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          Expanded(
                            child: Text(
                              step['step'],
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
                    : Text(
                  "No step-by-step instructions available",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
