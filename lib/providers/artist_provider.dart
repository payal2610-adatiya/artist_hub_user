import 'package:flutter/material.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/models/artist_model.dart';

class ArtistProvider with ChangeNotifier {
  List<ArtistModel> _artists = [];
  List<ArtistModel> _filteredArtists = [];
  ArtistModel? _selectedArtist;
  bool _isLoading = false;
  String? _errorMessage;

  List<ArtistModel> get artists => _filteredArtists;
  ArtistModel? get selectedArtist => _selectedArtist;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  static Future<List<String>> fetchCategoriesFromArtists(List<ArtistModel> artists) async {
  final categorySet = <String>{};

  for (var artist in artists) {
  if (artist.category != null && artist.category!.isNotEmpty) {
  categorySet.add(artist.category!);
  }
  }

  return categorySet.toList();
  }

  static Future<List<Map<String, dynamic>>> fetchCategoriesWithCount(List<ArtistModel> artists) async {
  // Count artists per category
  final categoryMap = <String, int>{};

  for (var artist in artists) {
  if (artist.category != null && artist.category!.isNotEmpty) {
  final category = artist.category!;
  categoryMap[category] = (categoryMap[category] ?? 0) + 1;
  }
  }

  // Convert to list of maps
  return categoryMap.entries.map((entry) {
  return {
  'name': entry.key,
  'count': entry.value,
  'icon': _getCategoryIcon(entry.key),
  };
  }).toList();
  }

  static IconData _getCategoryIcon(String category) {
  final lowerCategory = category.toLowerCase();

  if (lowerCategory.contains('singer') || lowerCategory.contains('voice')) {
  return Icons.mic;
  } else if (lowerCategory.contains('music') || lowerCategory.contains('instrument')) {
  return Icons.music_note;
  } else if (lowerCategory.contains('painter') || lowerCategory.contains('artist') || lowerCategory.contains('draw')) {
  return Icons.brush;
  } else if (lowerCategory.contains('dancer') || lowerCategory.contains('dance')) {
  return Icons.directions_run;
  } else if (lowerCategory.contains('photo') || lowerCategory.contains('camera')) {
  return Icons.camera_alt;
  } else if (lowerCategory.contains('actor') || lowerCategory.contains('performer') || lowerCategory.contains('theater')) {
  return Icons.theater_comedy;
  } else {
  return Icons.category;
  }
  }


  Future<void> fetchArtists() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getArtists();

      _isLoading = false;

      if (response['status'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        _artists = data.map((artistJson) => ArtistModel.fromJson(artistJson)).toList();
        _filteredArtists = List.from(_artists);
        notifyListeners();
      } else {
        _errorMessage = response['message'];
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to fetch artists: $e';
      notifyListeners();
    }
  }

  Future<void> fetchArtistDetails(int artistId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getArtistDetails(artistId);

      _isLoading = false;

      if (response['status'] == true) {
        _selectedArtist = ArtistModel.fromJson(response['data']);
        notifyListeners();
      } else {
        _errorMessage = response['message'];
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to fetch artist details: $e';
      notifyListeners();
    }
  }

  void filterArtists(String query) {
    if (query.isEmpty) {
      _filteredArtists = List.from(_artists);
    } else {
      _filteredArtists = _artists.where((artist) {
        final name = artist.name?.toLowerCase() ?? '';
        final category = artist.category?.toLowerCase() ?? '';
        return name.contains(query.toLowerCase()) ||
            category.contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setSelectedArtist(ArtistModel artist) {
    _selectedArtist = artist;
    notifyListeners();
  }
}