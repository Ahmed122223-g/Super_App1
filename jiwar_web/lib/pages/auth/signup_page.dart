import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/api_service.dart';
import '../../widgets/dialogs/error_dialog.dart';
import '../../widgets/dialogs/success_dialog.dart';

/// User Signup Page
class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSmallScreen = MediaQuery.of(context).size.width < 900;
    
    return Scaffold(
      body: Row(
        children: [
          // Left side - Form
          Expanded(
            flex: isSmallScreen ? 1 : 1,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTopBar(context, ref),
                  Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 24 : 48),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 450),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          
                          // Title
                          Text(
                            l10n.createAccount,
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.createAccountSubtitle,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Form
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Name
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: l10n.name,
                                    prefixIcon: const Icon(Iconsax.user),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.nameRequired;
                                    }
                                    return null;
                                  },
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Email
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: l10n.email,
                                    prefixIcon: const Icon(Iconsax.sms),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.emailRequired;
                                    }
                                    if (!value.contains('@')) {
                                      return l10n.invalidEmail;
                                    }
                                    return null;
                                  },
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Phone (optional)
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    labelText: '${l10n.phone} (${l10n.optional})',
                                    prefixIcon: const Icon(Iconsax.call),
                                  ),
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Age and Address row
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _ageController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: '${l10n.age} (${l10n.optional})',
                                          prefixIcon: const Icon(Iconsax.calendar),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        controller: _addressController,
                                        decoration: InputDecoration(
                                          labelText: '${l10n.address} (${l10n.optional})',
                                          prefixIcon: const Icon(Iconsax.location),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Password
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_isPasswordVisible,
                                  decoration: InputDecoration(
                                    labelText: l10n.password,
                                    prefixIcon: const Icon(Iconsax.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible 
                                            ? Iconsax.eye 
                                            : Iconsax.eye_slash,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible = !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.passwordRequired;
                                    }
                                    if (value.length < 8) {
                                      return l10n.passwordTooShort;
                                    }
                                    if (!value.contains(RegExp(r'[A-Z]'))) {
                                      return l10n.passwordNeedsUppercase;
                                    }
                                    if (!value.contains(RegExp(r'[a-z]'))) {
                                      return l10n.passwordNeedsLowercase;
                                    }
                                    if (!value.contains(RegExp(r'[0-9]'))) {
                                      return l10n.passwordNeedsNumber;
                                    }
                                    return null;
                                  },
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Confirm Password
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: !_isConfirmPasswordVisible,
                                  decoration: InputDecoration(
                                    labelText: l10n.confirmPassword,
                                    prefixIcon: const Icon(Iconsax.lock_1),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isConfirmPasswordVisible 
                                            ? Iconsax.eye 
                                            : Iconsax.eye_slash,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value != _passwordController.text) {
                                      return l10n.passwordsDoNotMatch;
                                    }
                                    return null;
                                  },
                                ),
                                
                                const SizedBox(height: 32),
                                
                                // Signup button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleSignup,
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(l10n.signup),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Login link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.alreadyHaveAccount,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              GestureDetector(
                                onTap: () => context.go('/login'),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Text(
                                    l10n.login,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Right side - Image (desktop only)
          if (!isSmallScreen)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: const Icon(
                          Iconsax.user_add,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        l10n.joinUs,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 300,
                        child: Text(
                          l10n.appDescription,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => context.go('/'),
            icon: const Icon(Iconsax.arrow_left),
            tooltip: 'العودة للرئيسية',
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const Spacer(),
          
          // Language toggle
          IconButton(
            onPressed: () => ref.read(localeProvider.notifier).toggleLocale(),
            icon: const Icon(Iconsax.translate),
            tooltip: isArabic ? 'English' : 'العربية',
          ),
        ],
      ),
    );
  }

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final api = ApiService();
      final response = await api.registerUser(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        age: _ageController.text.isNotEmpty ? int.tryParse(_ageController.text) : null,
        address: _addressController.text.isNotEmpty ? _addressController.text : null,
      );
      
      setState(() => _isLoading = false);
      
      if (response.isSuccess) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        await SuccessDialog.show(
          context,
          title: isArabic ? 'إنشاء حساب' : 'Sign Up Success',
          message: isArabic ? 'تم إنشاء الحساب بنجاح!' : 'Account created successfully!',
          onDismiss: () => context.go('/'),
        );
      } else {
        await ErrorDialog.show(
          context,
          errorCode: response.errorCode ?? 'UNKNOWN_ERROR',
          errorMessage: response.errorMessage,
        );
      }
    }
  }
}
