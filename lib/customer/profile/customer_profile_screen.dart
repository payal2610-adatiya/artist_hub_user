import 'package:flutter/material.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/routes/app_routes.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/services/shared_pref.dart';
import 'package:artist_hub/core/widgets/custom_button.dart';
import 'package:artist_hub/core/widgets/custom_textfield.dart';
import 'package:artist_hub/utils/helpers.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final userData = SharedPref.getUserData();
    setState(() {
      _nameController.text = userData['name'] ?? '';
      _emailController.text = userData['email'] ?? '';
      _phoneController.text = userData['phone'] ?? '';
      _addressController.text = userData['address'] ?? '';
    });
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
      final result = await ApiService.updateUser(
        id: int.parse(userId),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (result['success'] == true) {
        final updatedUserData = {
          'id': userId,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'role': 'customer',
          'is_approved': true,
        };
        await SharedPref.saveUserData(updatedUserData);

        Helpers.showSnackbar(context, 'Profile updated successfully');
        setState(() => _isEditing = false);
      } else {
        Helpers.showSnackbar(
          context,
          result['message'] ?? 'Failed to update profile',
          isError: true,
        );
      }
    } catch (e) {
      Helpers.showSnackbar(context, 'Error: $e', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _logout() async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      'Logout',
      'Are you sure you want to logout?',
    );

    if (!confirmed) return;

    await SharedPref.clearUserData();
    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.roleSelection,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        iconTheme: IconThemeData(color: AppColors.white),
        backgroundColor: AppColors.primaryColor,
        title: const Text('My Profile', style: TextStyle(color: AppColors.white)),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.white,),
              onPressed: () {
                setState(() => _isEditing = true);
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  enabled: _isEditing,
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: AppColors.darkGrey,
                  ),
                  validator: (value) => Helpers.validateRequired(value, 'Name'),
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  enabled: false,
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppColors.darkGrey,
                  ),
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  enabled: _isEditing,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.darkGrey,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone number is required';
                    }
                    if (!Helpers.isValidPhone(value)) {
                      return 'Enter valid 10-digit phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  controller: _addressController,
                  labelText: 'Address',
                  enabled: _isEditing,
                  maxLines: 2,
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.darkGrey,
                  ),
                  validator: (value) =>
                      Helpers.validateRequired(value, 'Address'),
                ),
                const SizedBox(height: 32),

                if (_isEditing) _buildEditActions(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildLogoutSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final userName = _nameController.text.isNotEmpty
        ? _nameController.text
        : SharedPref.getUserName();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primaryColor.withOpacity(0.1),
            child: Text(
              Helpers.getInitials(userName),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Customer',
                style: TextStyle(color: AppColors.darkGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _isEditing = false;
                _loadProfile();
              });
            },
            child: const Text('Cancel', style: TextStyle(color: AppColors.primaryColor),),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomButton(
            text: _isSaving ? 'Saving...' : 'Save Changes',
            onPressed: _saveProfile,
            isLoading: _isSaving,
          ),
        ),
      ],
    );
  }

  /// 🔴 LOGOUT DESIGN
  Widget _buildLogoutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.errorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.logout, color: AppColors.errorColor),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.errorColor,
          ),
        ),
        onTap: _logout,
      ),
    );
  }
}
