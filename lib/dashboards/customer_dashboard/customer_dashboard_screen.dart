import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/constants/app_strings.dart';
import 'package:artist_hub/models/artist_model.dart';
import 'package:artist_hub/providers/artist_provider.dart';
import 'package:artist_hub/providers/auth_provider.dart';

import 'package:artist_hub/customer/search/search_artist_screen.dart';
import 'package:artist_hub/customer/bookings/booking_list_screen.dart';
import 'package:artist_hub/customer/profile/customer_profile_screen.dart';
import 'package:artist_hub/customer/bookings/booking_screen.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CustomerHomeTab(),
    SearchArtistScreen(),
    CustomerBookingsTab(),
    CustomerProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ArtistProvider>().fetchArtists();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primaryColor,
          unselectedItemColor: AppColors.grey,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: AppStrings.home,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: AppStrings.search,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: AppStrings.bookings,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: AppStrings.profile,
            ),
          ],
        ),
      ),
    );
  }
}

/* ================= HOME TAB ================= */

class CustomerHomeTab extends StatelessWidget {
  const CustomerHomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 120,
          toolbarHeight: 60,
          backgroundColor: AppColors.primaryColor,
          centerTitle: false,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${user?.name ?? 'User'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find the perfect artist for your event',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const _SearchBar(),
              const SizedBox(height: 24),
              //const _CategoriesSection(),
              //const SizedBox(height: 28),
              const _FeaturedArtistsSection(),
              const SizedBox(height: 28),
              const _PopularArtistsSection(),
            ]),
          ),
        ),
      ],
    );
  }
}

/* ================= SEARCH BAR ================= */

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchArtistScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: _cardDecoration(),
        child: Row(
          children: const [
            Icon(Icons.search, color: Colors.grey),
            SizedBox(width: 12),
            Text(
              'Search artists, categories...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}


/* ================= FEATURED ARTISTS ================= */

class _FeaturedArtistsSection extends StatelessWidget {
  const _FeaturedArtistsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<ArtistProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final artists = provider.artists.take(3).toList();
        if (artists.isEmpty) {
          return const Center(child: Text('No artists available'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Featured Artists'),
            const SizedBox(height: 14),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: artists.length,
                itemBuilder: (_, i) =>
                    _ArtistCard(artist: artists[i], isHorizontal: true),
              ),
            ),
          ],
        );
      },
    );
  }
}

/* ================= POPULAR ARTISTS ================= */

class _PopularArtistsSection extends StatelessWidget {
  const _PopularArtistsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<ArtistProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final artists = provider.artists.skip(3).take(4).toList();
        if (artists.isEmpty) {
          return const Center(child: Text('No artists available'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Popular Artists'),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: artists.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (_, i) =>
                  _ArtistCard(artist: artists[i]),
            ),
          ],
        );
      },
    );
  }
}

/* ================= ARTIST CARD ================= */

class _ArtistCard extends StatelessWidget {
  final ArtistModel artist;
  final bool isHorizontal;

  const _ArtistCard({
    required this.artist,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        right: isHorizontal ? 12 : 0, // Space between horizontal cards
        bottom: isHorizontal ? 0 : 12, // Space between vertical cards
      ),
      child: InkWell(
        onTap: () => _showDetails(context),
        child: Container(
          width: isHorizontal ? 160 : null,
          height: 120,
          decoration: _cardDecoration(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Artist name
                Text(
                  artist.name ?? 'Artist',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),

                const SizedBox(height: 4),

                // Category
                Text(
                  artist.category ?? 'Artist',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),

                const SizedBox(height: 8),

                // Price and rating row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price
                    Text(
                      '₹${artist.price ?? 0}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primaryColor,
                      ),
                    ),

                    // Rating if available
                    if (artist.avgRating != null && artist.avgRating! > 0)
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            artist.avgRating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => ArtistDetailsBottomSheet(artist: artist),
    );
  }
}

/* ================= DETAILS BOTTOM SHEET ================= */

class ArtistDetailsBottomSheet extends StatelessWidget {
  final ArtistModel artist;
  const ArtistDetailsBottomSheet({Key? key, required this.artist})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            artist.name ?? '',
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(artist.category ?? '',
              style: TextStyle(color: AppColors.grey)),
          const SizedBox(height: 16),
          Text(artist.description ?? 'No description'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BookingScreen(artist: artist)),
                );
              },
              child: const Text('Book Now'),
            ),
          )
        ],
      ),
    );
  }
}

/* ================= OTHER TABS ================= */

class CustomerBookingsTab extends StatelessWidget {
  const CustomerBookingsTab({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const BookingListScreen();
}

class CustomerProfileTab extends StatelessWidget {
  const CustomerProfileTab({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => const CustomerProfileScreen();
}

/* ================= COMMON ================= */

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
