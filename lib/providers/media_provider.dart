import 'dart:io';
import 'package:flutter/material.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/models/media_model.dart';

class MediaProvider with ChangeNotifier {
  List<MediaModel> _mediaList = [];
  MediaModel? _selectedMedia;
  bool _isLoading = false;
  String? _errorMessage;

  List<MediaModel> get mediaList => _mediaList;
  MediaModel? get selectedMedia => _selectedMedia;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMediaByArtist(int artistId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.getArtistMedia(artistId: artistId);

      _isLoading = false;

      if (response['status'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        _mediaList = data.map((mediaJson) => MediaModel.fromJson(mediaJson)).toList();
        notifyListeners();
      } else {
        _errorMessage = response['message'];
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to fetch media: $e';
      notifyListeners();
    }
  }

  Future<bool> addMedia({
    required int artistId,
    required String mediaType,
    required File mediaFile,
    String caption = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.addArtistMedia(
        artistId: artistId,
        mediaType: mediaType,
        mediaFile: mediaFile,
        caption: caption,
      );

      _isLoading = false;

      if (response['status'] == true) {
        final mediaData = response['data'];
        if (mediaData != null) {
          final newMedia = MediaModel.fromJson(mediaData);
          _mediaList.insert(0, newMedia);
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = response['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to add media: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMedia({
    required int mediaId,
    required int artistId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Implement delete media API call
      // For now, just simulate deletion
      await Future.delayed(const Duration(seconds: 1));

      _isLoading = false;
      _mediaList.removeWhere((media) => media.id == mediaId);
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete media: $e';
      notifyListeners();
      return false;
    }
  }

  void setSelectedMedia(MediaModel media) {
    _selectedMedia = media;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}