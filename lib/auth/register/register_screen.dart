import 'package:flutter/material.dart';
import 'package:artist_hub/core/constants/app_colors.dart';
import 'package:artist_hub/core/constants/app_strings.dart';
import 'package:artist_hub/core/routes/app_routes.dart';
import 'package:artist_hub/core/services/api_service.dart';
import 'package:artist_hub/core/services/shared_pref.dart';
import 'package:artist_hub/core/widgets/custom_button.dart';
import 'package:artist_hub/core/widgets/custom_textfield.dart';
import 'package:artist_hub/utils/helpers.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedRole = 'artist';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // Get role from arguments if passed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['role'] != null) {
        setState(() {
          _selectedRole = args['role'];
        });
      }
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      Helpers.showSnackbar(context, 'Passwords do not match', isError: true);
      return;
    }

    final hasInternet = await Helpers.checkInternetBeforeApiCall(context);
    if (!hasInternet) return;

    setState(() => _isLoading = true);

    final result = await ApiService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      role: _selectedRole,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true && result['data'] != null) {
      // Save user data
      await SharedPref.saveUserData(result['data']);

      if (!mounted) return;

      Helpers.showSnackbar(context, result['message'] ?? 'Registration successful');

      // Show appropriate message based on role
      if (_selectedRole == 'artist') {
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.customerDashboard);
      }
    } else {
      Helpers.showSnackbar(context, result['message'] ?? 'Registration failed', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  color: AppColors.textColor,
                ),

                const SizedBox(height: 20),

                // Header
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Register as $_selectedRole',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.darkGrey,
                  ),
                ),

                const SizedBox(height: 32),

                // Role toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightGrey),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildRoleButton('artist', 'Artist'),
                      ),
                      Expanded(
                        child: _buildRoleButton('customer', 'Customer'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Name field
                CustomTextField(
                  controller: _nameController,
                  labelText: AppStrings.name,
                  hintText: 'Enter your full name',
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.darkGrey),
                  validator: (value) => Helpers.validateRequired(value, 'Name'),
                ),

                const SizedBox(height: 20),

                // Email field
                CustomTextField(
                  controller: _emailController,
                  labelText: AppStrings.email,
                  hintText: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.darkGrey),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!Helpers.isValidEmail(value)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Phone field
                CustomTextField(
                  controller: _phoneController,
                  labelText: AppStrings.phone,
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

                // Address field
                CustomTextField(
                  controller: _addressController,
                  labelText: AppStrings.address,
                  hintText: 'Enter your address',
                  maxLines: 2,
                  prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.darkGrey),
                  validator: (value) => Helpers.validateRequired(value, 'Address'),
                ),

                const SizedBox(height: 20),

                // Password field
                CustomTextField(
                  controller: _passwordController,
                  labelText: AppStrings.password,
                  hintText: 'Enter your password',
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.darkGrey),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Confirm password field
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  hintText: 'Confirm your password',
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.darkGrey),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.darkGrey,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Terms and conditions
                Row(
                  children: [
                    Checkbox(
                      value: true,
                      onChanged: null,
                      activeColor: AppColors.primaryColor,
                    ),
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          text: 'I agree to the ',
                          style: TextStyle(
                            color: AppColors.darkGrey,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Register button
                CustomButton(
                  text: AppStrings.register,
                  onPressed: _register,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 32),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkGrey,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, AppRoutes.login);
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
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

  Widget _buildRoleButton(String role, String label) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () {
        setState(() => _selectedRole = role);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.white : AppColors.darkGrey,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}