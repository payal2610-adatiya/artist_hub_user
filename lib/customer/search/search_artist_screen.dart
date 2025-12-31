import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/constants/app_strings.dart';
import 'package:artist_hub/models/artist_model.dart';
import 'package:artist_hub/providers/artist_provider.dart';
import 'package:artist_hub/customer/bookings/booking_screen.dart';

class SearchArtistScreen extends StatefulWidget {
  const SearchArtistScreen({Key? key}) : super(key: key);

  @override
  _SearchArtistScreenState createState() => _SearchArtistScreenState();
}

class _SearchArtistScreenState extends State<SearchArtistScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Singers',
    'Musicians',
    'Painters',
    'Dancers',
    'Performers',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final artistProvider = Provider.of<ArtistProvider>(context, listen: false);
    artistProvider.filterArtists(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final artistProvider = Provider.of<ArtistProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Search Artists',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppColors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search artists...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: AppColors.grey),
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear, color: AppColors.grey, size: 20),
                            onPressed: () {
                              _searchController.clear();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category Filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                      _filterByCategory(category);
                    },
                    selectedColor: AppColors.primaryColor,
                    labelStyle: TextStyle(
                      color: _selectedCategory == category
                          ? Colors.white
                          : AppColors.textColor,
                    ),
                    backgroundColor: AppColors.backgroundColor,
                  ),
                );
              },
            ),
          ),

          // Artists List
          Expanded(
            child: _buildArtistsList(artistProvider),
          ),
        ],
      ),
    );
  }

  void _filterByCategory(String category) {
    final artistProvider = Provider.of<ArtistProvider>(context, listen: false);

    if (category == 'All') {
      artistProvider.filterArtists('');
    } else {
      final filtered = artistProvider.artists.where((artist) {
        return artist.category?.toLowerCase().contains(category.toLowerCase()) ?? false;
      }).toList();

      // Update filtered list in provider
      // Note: This is a simplified approach - you might want to add category filter to provider
    }
  }

  Widget _buildArtistsList(ArtistProvider artistProvider) {
    if (artistProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (artistProvider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: AppColors.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              artistProvider.errorMessage!,
              style: TextStyle(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                artistProvider.fetchArtists();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (artistProvider.artists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: AppColors.lightGrey,
            ),
            const SizedBox(height: 16),
            Text(
              'No artists found',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(color: AppColors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: artistProvider.artists.length,
      itemBuilder: (context, index) {
        final artist = artistProvider.artists[index];
        return _buildArtistCard(artist);
      },
    );
  }

  Widget _buildArtistCard(ArtistModel artist) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingScreen(artist: artist),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Artist Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.primaryColor.withOpacity(0.1),
                  image: const DecorationImage(
                    image: NetworkImage('https://picsum.photos/200/200'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Artist Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.name ?? 'Artist',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      artist.category ?? 'Category',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(Icons.star, color: AppColors.secondaryColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          artist.avgRating?.toStringAsFixed(1) ?? '0.0',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${artist.totalReviews ?? 0} reviews)',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Experience: ${artist.experience ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textColor,
                          ),
                        ),
                        Text(
                          '₹${artist.price ?? '0'}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}