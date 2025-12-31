import 'package:flutter/foundation.dart';
import 'package:artist_hub/models/category_model.dart';

import '../core/services/api_service.dart';

class CategoryProvider with ChangeNotifier {
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCategories() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get all artists first to count categories
      final artistsResponse = await ApiService.getArtists();

      if (artistsResponse['status'] == true) {
        final List<dynamic> artistsData = artistsResponse['data'] ?? [];

        // Extract unique categories from artists
        final categorySet = <String>{};
        for (var artist in artistsData) {
          if (artist['category'] != null) {
            categorySet.add(artist['category'].toString());
          }
        }

        // Convert to CategoryModel list with artist counts
        _categories = _processCategories(categorySet.toList(), artistsData);
        _error = null;
      } else {
        _error = artistsResponse['message'] ?? 'Failed to load categories';
        _categories = _getSampleCategories();
      }
    } catch (e) {
      _error = e.toString();
      _categories = _getSampleCategories();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<CategoryModel> _processCategories(List<String> categoryNames, List<dynamic> artistsData) {
    final List<CategoryModel> categories = [];
    int idCounter = 1;

    for (var categoryName in categoryNames) {
      // Count artists in this category
      final artistCount = artistsData.where((artist) =>
      artist['category']?.toString() == categoryName
      ).length;

      categories.add(CategoryModel(
        id: (idCounter++).toString(),
        name: categoryName,
        artistCount: artistCount,
        isActive: true,
      ));
    }

    return categories;
  }

  List<CategoryModel> _getSampleCategories() {
    return [
      CategoryModel(id: '1', name: 'Singers', artistCount: 25),
      CategoryModel(id: '2', name: 'Musicians', artistCount: 18),
      CategoryModel(id: '3', name: 'Painters', artistCount: 32),
      CategoryModel(id: '4', name: 'Dancers', artistCount: 15),
      CategoryModel(id: '5', name: 'Photographers', artistCount: 22),
      CategoryModel(id: '6', name: 'Performers', artistCount: 12),
    ];
  }

  // If you have a specific API endpoint for categories, use this instead:
  Future<void> fetchCategoriesFromApi() async {
    try {
      _isLoading = true;
      notifyListeners();

      // If you have a categories endpoint, use:
      // final response = await ApiService.getCategories(); // You'll need to add this to ApiService
      // Otherwise, use the artists method above

      // For now, using sample data
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay
      _categories = _getSampleCategories();
      _error = null;

    } catch (e) {
      _error = e.toString();
      _categories = _getSampleCategories();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}