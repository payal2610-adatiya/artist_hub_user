import 'package:flutter/material.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/constants/app_strings.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/services/shared_pref.dart';
import 'package:artist_hub/core/widgets/custom_button.dart';
import 'package:artist_hub/core/widgets/custom_textfield.dart';
import 'package:artist_hub/models/artist_model.dart';
import 'package:artist_hub/utils/helpers.dart';

class EditArtistProfileScreen extends StatefulWidget {
  final ArtistModel? artist;
  final Map<String, dynamic>? profile;

  const EditArtistProfileScreen({
    super.key,
    this.artist,
    this.profile,
  });

  @override
  State<EditArtistProfileScreen> createState() => _EditArtistProfileScreenState();
}

class _EditArtistProfileScreenState extends State<EditArtistProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _categoryController = TextEditingController();
  final _experienceController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isNewProfile = false;

  final List<String> _categories = [
    'Singer',
    'Dancer',
    'Musician',
    'Painter',
    'Performer',
    'Actor',
    'Magician',
    'Comedian',
    'Photographer',
    'Videographer',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    // Load artist data
    if (widget.artist != null) {
      _nameController.text = widget.artist!.name;
      _phoneController.text = widget.artist!.phone;
      _addressController.text = widget.artist!.address;
    } else {
      final userData = SharedPref.getUserData();
      _nameController.text = userData['name'] ?? '';
      _phoneController.text = userData['phone'] ?? '';
      _addressController.text = userData['address'] ?? '';
    }

    // Load profile data
    if (widget.profile != null) {
      _categoryController.text = widget.profile!['category'] ?? '';
      _experienceController.text = widget.profile!['experience'] ?? '';
      _priceController.text = widget.profile!['price']?.toString() ?? '';
      _descriptionController.text = widget.profile!['description'] ?? '';
      _isNewProfile = false;
    } else {
      _isNewProfile = true;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final hasInternet = await Helpers.checkInternetBeforeApiCall(context);
    if (!hasInternet) return;

    setState(() => _isSaving = true);

    final userId = SharedPref.getUserId();
    if (userId.isEmpty) {
      Helpers.showSnackbar(context, 'User not found', isError: true);
      setState(() => _isSaving = false);
      return;
    }

    try {
      // First update user info
      final userUpdateResult = await ApiService.updateUser(
        id: int.parse(userId),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (userUpdateResult['success'] != true) {
        Helpers.showSnackbar(
          context,
          'Failed to update user info',
          isError: true,
        );
        setState(() => _isSaving = false);
        return;
      }

      // Update user data in shared preferences
      final updatedUserData = {
        'id': userId,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
      };
      await SharedPref.saveUserData(updatedUserData);

      // Then update/create artist profile
      if (_isNewProfile) {
        final profileResult = await ApiService.addArtistProfile(
          userId: int.parse(userId),
          category: _categoryController.text.trim(),
          experience: _experienceController.text.trim(),
          price: _priceController.text.trim(),
          description: _descriptionController.text.trim(),
        );

        if (profileResult['success'] == true) {
          Helpers.showSnackbar(context, 'Profile created successfully');
          Navigator.pop(context);
        } else {
          Helpers.showSnackbar(
            context,
            profileResult['message'] ?? 'Failed to create profile',
            isError: true,
          );
        }
      } else {
        final profileResult = await ApiService.updateArtistProfile(
          userId: int.parse(userId),
          category: _categoryController.text.trim(),
          experience: _experienceController.text.trim(),
          price: _priceController.text.trim(),
          description: _descriptionController.text.trim(),
        );

        if (profileResult['success'] == true) {
          Helpers.showSnackbar(context, 'Profile updated successfully');
          Navigator.pop(context);
        } else {
          Helpers.showSnackbar(
            context,
            profileResult['message'] ?? 'Failed to update profile',
            isError: true,
          );
        }
      }
    } catch (e) {
      Helpers.showSnackbar(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteProfile() async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      'Delete Profile',
      'Are you sure you want to delete your artist profile? This action cannot be undone.',
    );

    if (!confirmed) return;

    final hasInternet = await Helpers.checkInternetBeforeApiCall(context);
    if (!hasInternet) return;

    // Note: You'll need to add a delete profile API endpoint
    Helpers.showSnackbar(context, 'Delete functionality coming soon');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: Text(_isNewProfile ? 'Create Profile' : 'Edit Profile',style: TextStyle(color: Colors.white),),
        actions: [
          if (!_isNewProfile)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteProfile,
              color: AppColors.errorColor,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildFormContent(),
    );
  }

  Widget _buildFormContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 16),

            // Name
            CustomTextField(
              controller: _nameController,
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: const Icon(Icons.person_outline, color: AppColors.darkGrey),
              validator: (value) => Helpers.validateRequired(value, 'Name'),
            ),

            const SizedBox(height: 20),

            // Phone
            CustomTextField(
              controller: _phoneController,
              labelText: 'Phone Number',
              hintText: 'Enter your phone number',
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.darkGrey),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number is required';
                }
                if (!Helpers.isValidPhone(value)) {
                  return 'Enter a valid 10-digit phone number';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Address
            CustomTextField(
              controller: _addressController,
              labelText: 'Address',
              hintText: 'Enter your address',
              maxLines: 2,
              prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.darkGrey),
              validator: (value) => Helpers.validateRequired(value, 'Address'),
            ),

            const SizedBox(height: 32),

            const Text(
              'Artist Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 16),

            // Category dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _categoryController.text.isNotEmpty
                      ? _categoryController.text
                      : null,
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _categoryController.text = value ?? '';
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Select your category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.lightGrey),
                    ),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Category is required';
                    }
                    return null;
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Experience
            CustomTextField(
              controller: _experienceController,
              labelText: 'Experience',
              hintText: 'e.g., 5 years, Beginner, Professional',
              prefixIcon: const Icon(Icons.work_history_outlined, color: AppColors.darkGrey),
              validator: (value) => Helpers.validateRequired(value, 'Experience'),
            ),

            const SizedBox(height: 20),

            // Price
            CustomTextField(
              controller: _priceController,
              labelText: 'Starting Price (₹)',
              hintText: 'Enter your starting price',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.currency_rupee, color: AppColors.darkGrey),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Price is required';
                }
                if (double.tryParse(value) == null) {
                  return 'Enter a valid price';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Description
            CustomTextField(
              controller: _descriptionController,
              labelText: 'Description',
              hintText: 'Tell us about your skills, style, and experience...',
              maxLines: 5,
              prefixIcon: const Icon(Icons.description_outlined, color: AppColors.darkGrey),
              validator: (value) => Helpers.validateRequired(value, 'Description'),
            ),

            const SizedBox(height: 32),

            // Save button
            CustomButton(
              text: _isSaving ? 'Saving...' : 'Save Profile',
              isLoading: _isSaving,
              onPressed: _saveProfile,
            ),

            const SizedBox(height: 12),

            // Cancel button
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.darkGrey,
                side: const BorderSide(color: AppColors.lightGrey),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _categoryController.dispose();
    _experienceController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}