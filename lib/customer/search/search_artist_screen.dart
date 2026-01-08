import 'package:flutter/material.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/constants/app_strings.dart';
import 'package:artist_hub/core/routes/app_routes.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/widgets/loading_widget.dart';
import 'package:artist_hub/core/widgets/no_data_widget.dart';
import 'package:artist_hub/models/artist_model.dart';
import 'package:artist_hub/utils/helpers.dart';

import '../bookings/booking_screen.dart';

class SearchArtistScreen extends StatefulWidget {
  const SearchArtistScreen({super.key});

  @override
  State<SearchArtistScreen> createState() => _SearchArtistScreenState();
}

class _SearchArtistScreenState extends State<SearchArtistScreen> {
  List<ArtistModel> _artists = [];
  List<ArtistModel> _filteredArtists = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _selectedSort = 'rating';

  final List<String> _categories = [
    'all',
    'Singer',
    'Dancer',
    'Musician',
    'Painter',
    'Performer',
    'Actor',
    'Magician',
    'Comedian',
  ];

  final Map<String, String> _sortOptions = {
    'rating': 'Highest Rating',
    'price': 'Lowest Price',
    'name': 'Name (A-Z)',
  };

  @override
  void initState() {
    super.initState();
    _loadArtists();
  }

  Future<void> _loadArtists() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await ApiService.getAllArtists();
      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> data = result['data'];
        setState(() {
          _artists = data.map((item) => ArtistModel.fromJson(item)).toList();
          _applyFilters();
        });
      } else {
        setState(() => _hasError = true);
      }
    } catch (e) {
      setState(() => _hasError = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<ArtistModel> filtered = _artists;

    // Apply category filter
    if (_selectedCategory != 'all') {
      filtered = filtered.where((artist) {
        final category = artist.category?.toLowerCase() ?? '';
        return category.contains(_selectedCategory.toLowerCase());
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((artist) {
        final name = artist.name.toLowerCase();
        final category = artist.category?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || category.contains(query);
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case 'rating':
          return b.avgRating.compareTo(a.avgRating);
        case 'price':
          final priceA = double.tryParse(a.price ?? '999999') ?? 999999;
          final priceB = double.tryParse(b.price ?? '999999') ?? 999999;
          return priceA.compareTo(priceB);
        case 'name':
          return a.name.compareTo(b.name);
        default:
          return 0;
      }
    });

    setState(() => _filteredArtists = filtered);
  }


  void _openArtistDetail(ArtistModel artist) {
    Navigator.pushNamed(
      context,
      AppRoutes.artistDetail,
      arguments: {'artistId': artist.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: AppColors.primaryColor,
        title: const Text('Find Artists', style: TextStyle(color: AppColors.white),),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadArtists,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search artists by name or category...',
                prefixIcon: const Icon(Icons.search, color: AppColors.darkGrey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _applyFilters();
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.lightGrey),
                ),
                filled: true,
                fillColor: AppColors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredArtists.length} artists found',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.darkGrey,
                  ),
                ),
                if (_selectedCategory != 'all')
                  Chip(
                    label: Text(_selectedCategory),
                    backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                    labelStyle: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 12,
                    ),
                    onDeleted: () {
                      setState(() {
                        _selectedCategory = 'all';
                        _applyFilters();
                      });
                    },
                  ),
              ],
            ),
          ),

          // Artists list
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Loading artists...')
                : _hasError
                ? NoDataWidget(
              message: 'Failed to load artists',
              buttonText: 'Retry',
              onPressed: _loadArtists,
            )
                : _filteredArtists.isEmpty
                ? NoDataWidget(
              message: 'No artists found',
              buttonText: 'Clear Filters',
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'all';
                  _applyFilters();
                });
              },
            )
                : _buildArtistsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredArtists.length,
      itemBuilder: (context, index) {
        return _buildArtistCard(_filteredArtists[index]);
      },
    );
  }

  Widget _buildArtistCard(ArtistModel artist) {
    // Get the valid price for booking
    final bookingPrice = _getBookingPrice(artist.price);
    // /final formattedPrice = _formatPrice(artist.price);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openArtistDetail(artist),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Artist avatar (same as before)
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      Helpers.getInitials(artist.name),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Artist info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artist.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (artist.category != null && artist.category!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            artist.category!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: AppColors.secondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            artist.avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${artist.totalReviews})',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.darkGrey,
                            ),
                          ),
                          const Spacer(),
                          // Display formatted price
                          // Text(
                          //   formattedPrice,
                          //   style: TextStyle(
                          //     fontSize: 16,
                          //     fontWeight: FontWeight.w700,
                          //     color: AppColors.primaryColor,
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Book button - Pass the validated price
                // ElevatedButton(
                //   onPressed: bookingPrice > 0
                //       ? () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (context) => BookingScreen(
                //           artist: artist,
                //           basePrice: bookingPrice, // Pass validated price
                //         ),
                //       ),
                //     );
                //   }
                //       : () {
                //     // Show dialog for contact price
                //     _showContactDialog(artist);
                //   },
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: AppColors.primaryColor,
                //     foregroundColor: AppColors.white,
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 16,
                //       vertical: 8,
                //     ),
                //   ),
                //   child: Text(bookingPrice > 0 ? 'Book' : 'Contact'),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Add this helper method to get validated booking price
  double _getBookingPrice(String? price) {
    if (price == null || price.isEmpty || price.toLowerCase() == 'null') {
      return 0.0;
    }

    // Try to parse as number
    final numPrice = double.tryParse(price);
    if (numPrice == null || numPrice <= 0) {
      return 0.0;
    }

    return numPrice;
  }

// Add this method to show contact dialog
  void _showContactDialog(ArtistModel artist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Artist'),
        content: Text(
          '${artist.name} does not have a fixed price listed. '
              'Please contact them directly to discuss pricing and booking details.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
// Add this helper method to format the price
//   String _formatPrice(String? price) {
//     if (price == null || price.isEmpty || price.toLowerCase() == 'null') {
//       return 'Contact for price';
//     }
//
//     // Check if price is a valid number
//     final cleanedPrice = price.replaceAll(RegExp(r'[^0-9.]'), '');
//     if (cleanedPrice.isEmpty || cleanedPrice == '0') {
//       return 'Contact for price';
//     }
//
//     // Try to parse as number
//     try {
//       final numPrice = double.tryParse(cleanedPrice);
//       if (numPrice == null || numPrice == 0) {
//         return 'Contact for price';
//       }
//       return '₹${numPrice.toStringAsFixed(0)}';
//     } catch (e) {
//       return '₹$price';
//     }
//   }

}
