import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';
import '../../core/providers/app_providers.dart';

import '../../core/theme/app_theme.dart';
import 'package:animate_do/animate_do.dart';
import '../../widgets/navbar/navbar.dart';
import '../../widgets/map/map_location_picker.dart';
import '../../core/services/api_service.dart';
import '../../widgets/dialogs/error_dialog.dart';
import '../../widgets/dialogs/success_dialog.dart';

/// Admin Signup Page - Multi-step registration
class AdminSignupPage extends ConsumerStatefulWidget {
  const AdminSignupPage({super.key});

  @override
  ConsumerState<AdminSignupPage> createState() => _AdminSignupPageState();
}

class _AdminSignupPageState extends ConsumerState<AdminSignupPage> {
  int _currentStep = 0;
  String? _selectedType;
  bool _codeVerified = false;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  
  // Controllers
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  
  int? _selectedSpecialty;  // Primary subject (used for API)
  final List<int> _selectedSubjects = [];  // Max 2 subjects
  LatLng? _selectedLocation;

  // Teacher specific
  final List<SelectedGrade> _selectedGrades = [];
  
  // Standard Egyptian Grades
  final List<String> _primaryGrades = [
    '1st Primary (الاول الابتدائي)', '2nd Primary (الثاني الابتدائي)', 
    '3rd Primary (الثالث الابتدائي)', '4th Primary (الرابع الابتدائي)',
    '5th Primary (الخامس الابتدائي)', '6th Primary (السادس الابتدائي)'
  ];
  final List<String> _prepGrades = [
    '1st Prep (الاول الاعدادي)', '2nd Prep (الثاني الاعدادي)', '3rd Prep (الثالث الاعدادي)'
  ];
  final List<String> _secGrades = [
    '1st Secondary (الاول الثانوي)', '2nd Secondary (الثاني الثانوي)', '3rd Secondary (الثالث الثانوي)'
  ];

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSmallScreen = MediaQuery.of(context).size.width < 900;
    
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Navbar(isTransparent: false),
            
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 24 : 48),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      l10n.adminSignup,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                      Text(
                        l10n.registerAsProvider,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    
                    const SizedBox(height: 32),
                    
                    // Stepper
                    _buildStepper(context, l10n),
                    
                    const SizedBox(height: 32),
                    
                    // Step content
                    _buildStepContent(context, l10n),
                    
                    const SizedBox(height: 32),
                    
                    // Navigation buttons
                    _buildNavigationButtons(context, l10n),
                    
                    const SizedBox(height: 24),
                    
                    // Login link
                    Center(
                      child: Row(
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
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStepper(BuildContext context, AppLocalizations l10n) {
    final steps = [
      l10n.selectType,
      l10n.registrationCode,
      l10n.aboutYou,
      l10n.accountDetails,
    ];
    
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        
        return Expanded(
          child: Row(
            children: [
              // Step indicator
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? AppColors.primary
                      : isActive 
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.transparent,
                  border: Border.all(
                    color: isActive || isCompleted 
                        ? AppColors.primary 
                        : Theme.of(context).dividerColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive 
                                ? AppColors.primary 
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              // Line
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted 
                        ? AppColors.primary 
                        : Theme.of(context).dividerColor,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
  
  Widget _buildStepContent(BuildContext context, AppLocalizations l10n) {
    // Wrap content in KeyedSubtree to force rebuild and animation on step change
    return KeyedSubtree(
      key: ValueKey(_currentStep),
      child: FadeInUp(
        duration: const Duration(milliseconds: 500),
        child: _buildStepContentBody(context, l10n),
      ),
    );
  }

  Widget _buildStepContentBody(BuildContext context, AppLocalizations l10n) {
    switch (_currentStep) {
      case 0:
        return _buildTypeSelection(context, l10n);
      case 1:
        return _buildCodeVerification(context, l10n);
      case 2:
        return _buildProfileInfo(context, l10n);
      case 3:
        return _buildAccountDetails(context, l10n);
      default:
        return const SizedBox();
    }
  }
  
  Widget _buildTypeSelection(BuildContext context, AppLocalizations l10n) {
    final types = [
      _TypeOption(
        id: 'doctor',
        icon: Iconsax.health,
        title: l10n.clinic,
        available: true,
      ),
      _TypeOption(
        id: 'pharmacy',
        icon: Iconsax.hospital,
        title: l10n.pharmacy,
        available: true,
      ),
       _TypeOption(
        id: 'teacher',
        icon: Iconsax.book_1,
        title: l10n.teachers,
        available: true,
      ),
      _TypeOption(
        id: 'restaurant',
        icon: Iconsax.reserve,
        title: l10n.restaurant,
        available: false,
      ),
      _TypeOption(
        id: 'company',
        icon: Iconsax.building,
        title: l10n.company,
        available: false,
      ),
      _TypeOption(
        id: 'engineer',
        icon: Iconsax.cpu,
        title: l10n.engineer,
        available: false,
      ),
      _TypeOption(
        id: 'mechanic',
        icon: Iconsax.setting_2,
        title: l10n.mechanic,
        available: false,
      ),
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectType,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: types.asMap().entries.map((entry) {
            final index = entry.key;
            final type = entry.value;
            final isSelected = _selectedType == type.id;
            
            return FadeInUp(
              delay: Duration(milliseconds: index * 100),
              child: GestureDetector(
              onTap: type.available 
                  ? () {
                      if (_selectedType != type.id) {
                        setState(() {
                          _selectedType = type.id;
                          _codeVerified = false;
                          _codeController.clear();
                        });
                      }
                    }
                  : null,
              child: MouseRegion(
                cursor: type.available 
                    ? SystemMouseCursors.click 
                    : SystemMouseCursors.basic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 160,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.primary.withOpacity(0.1)
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? AppColors.primary 
                          : Theme.of(context).dividerColor.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Opacity(
                    opacity: type.available ? 1.0 : 0.4,
                    child: Column(
                      children: [
                        Icon(
                          type.icon,
                          size: 40,
                          color: isSelected 
                              ? AppColors.primary 
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          type.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (!type.available) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.comingSoon,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildCodeVerification(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.registrationCode,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.enterCode,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 24),
        
        TextFormField(
          controller: _codeController,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
          decoration: InputDecoration(
            hintText: 'XXXXXXXXXX',
            prefixIcon: const Icon(Iconsax.key),
            suffixIcon: _codeVerified 
                ? const Icon(Icons.check_circle, color: AppColors.success)
                : null,
          ),
        ),
        
        const SizedBox(height: 16),
        
        if (_codeVerified)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.codeVerified,
                  style: const TextStyle(color: AppColors.success),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 16),
        
        if (!_codeVerified)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyCode,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.verifyCode),
            ),
          ),
      ],
    );
  }
  
  Widget _buildProfileInfo(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.aboutYou,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        
        // Name
        FadeInUp(
          delay: const Duration(milliseconds: 100),
          child: TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l10n.name,
              prefixIcon: Icon(
                _selectedType == 'doctor' ? Iconsax.user : Iconsax.building,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Description
        FadeInUp(
          delay: const Duration(milliseconds: 200),
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.description,
              prefixIcon: const Icon(Iconsax.document_text),
              alignLabelWithHint: true,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Specialty (doctors only)
        if (_selectedType == 'doctor') ...[
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: DropdownButtonFormField<int>(
              value: _selectedSpecialty,
              decoration: InputDecoration(
                labelText: l10n.specialty,
                prefixIcon: const Icon(Iconsax.health),
              ),
              items: [
                DropdownMenuItem(value: 1, child: Text(l10n.specialtyDentist)),
                DropdownMenuItem(value: 2, child: Text(l10n.specialtyOphthalmologist)),
                DropdownMenuItem(value: 3, child: Text(l10n.specialtyPediatrician)),
                DropdownMenuItem(value: 4, child: Text(l10n.specialtyCardiologist)),
                DropdownMenuItem(value: 5, child: Text(l10n.specialtyDermatologist)),
                DropdownMenuItem(value: 6, child: Text(l10n.specialtyOrthopedist)),
                DropdownMenuItem(value: 7, child: Text(l10n.specialtyNeurologist)),
                DropdownMenuItem(value: 8, child: Text(l10n.specialtyGynecologist)),
                DropdownMenuItem(value: 9, child: Text(l10n.specialtyInternist)),
                DropdownMenuItem(value: 10, child: Text(l10n.specialtyENT)),
                DropdownMenuItem(value: 14, child: Text(l10n.specialtyGeneral)),
              ],
              onChanged: (value) => setState(() => _selectedSpecialty = value),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Phone
        FadeInUp(
          delay: const Duration(milliseconds: 400),
          child: TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.phone,
              prefixIcon: const Icon(Iconsax.call),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Address
        FadeInUp(
          delay: const Duration(milliseconds: 500),
          child: TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: l10n.address,
              prefixIcon: const Icon(Iconsax.location),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Map Location Picker
        FadeInUp(
          delay: const Duration(milliseconds: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.selectLocation,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              MapLocationPicker(
                initialLocation: _selectedLocation,
                height: 300,
                onLocationSelected: (location) {
                  setState(() => _selectedLocation = location);
                },
              ),
            ],
          ),
        ),

        // Teacher Specific Fields (Subject and Grades)
        if (_selectedType == 'teacher') ...[
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          
          // Subject Selection Title
          Row(
            children: [
              Text(
                l10n.subjects,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedSubjects.length}/2',
                  style: TextStyle(
                    color: _selectedSubjects.length >= 2 ? Colors.red : Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.selectUpToTwoSubjects,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          
          // Subject Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kSubjects.map((subject) {
              final isSelected = _selectedSubjects.contains(subject.id);
              final canSelect = isSelected || _selectedSubjects.length < 2;
              
              return FilterChip(
                label: Text('${subject.nameAr} - ${subject.nameEn}'),
                selected: isSelected,
                onSelected: canSelect ? (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSubjects.add(subject.id);
                      _selectedSpecialty ??= subject.id;
                    } else {
                      _selectedSubjects.remove(subject.id);
                      _selectedGrades.removeWhere((g) => g.subjectId == subject.id);
                      if (_selectedSpecialty == subject.id) {
                        _selectedSpecialty = _selectedSubjects.isNotEmpty ? _selectedSubjects.first : null;
                      }
                    }
                  });
                } : null,
                selectedColor: Colors.blue.withOpacity(0.2),
                checkmarkColor: Colors.blue,
                disabledColor: Colors.grey.withOpacity(0.1),
              );
            }).toList(),
          ),
          
          // Grade Selection (only show if subjects selected)
          if (_selectedSubjects.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildDynamicGradeSelection(context, l10n),
          ],
        ],
      ],
    );
  }
  
  Widget _buildDynamicGradeSelection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectGrades,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.selectGradesSubtext,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        
        // Show grades for each selected subject
        ..._selectedSubjects.map((subjectId) {
          final subject = kSubjects.firstWhere((s) => s.id == subjectId);
          final allowedGrades = subject.getAllowedGrades(
            primary1_3: [_primaryGrades[0], _primaryGrades[1], _primaryGrades[2]],
            primary4_6: [_primaryGrades[3], _primaryGrades[4], _primaryGrades[5]],
            preparatory: _prepGrades,
            secondary: _secGrades,
          );
          
          return _buildSubjectGrades(context, subject, allowedGrades);
        }),
        
        // Selected Grades Summary
        if (_selectedGrades.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            l10n.selectedGrades,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._selectedGrades.map((grade) {
            final subject = kSubjects.firstWhere((s) => s.id == grade.subjectId);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(subject.nameAr, style: const TextStyle(fontSize: 10)),
                ),
                title: Text(grade.name),
                subtitle: Text('${grade.price} EGP / Month'),
                trailing: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _selectedGrades.remove(grade);
                    });
                  },
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildSubjectGrades(BuildContext context, SubjectData subject, List<String> allowedGrades) {
    return ExpansionTile(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(subject.nameAr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '(${allowedGrades.length} grades)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
      initiallyExpanded: true,
      children: allowedGrades.map((gradeName) {
        final isSelected = _selectedGrades.any((g) => g.name == gradeName && g.subjectId == subject.id);
        return CheckboxListTile(
          title: Text(gradeName),
          value: isSelected,
          onChanged: (bool? value) {
            if (value == true) {
              _showPriceDialog(context, gradeName, subject.id);
            } else {
              setState(() {
                _selectedGrades.removeWhere((g) => g.name == gradeName && g.subjectId == subject.id);
              });
            }
          },
        );
      }).toList(),
    );
  }

  Future<void> _showPriceDialog(BuildContext context, String gradeName, int subjectId) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.setPriceFor(gradeName)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.monthlyPriceEgp,
            suffixText: 'EGP',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final price = double.tryParse(controller.text);
              if (price != null && price > 0) {
                setState(() {
                  _selectedGrades.add(SelectedGrade(name: gradeName, price: price, subjectId: subjectId));
                });
                Navigator.pop(context);
              }
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetails(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountDetails,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        
        // Email
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: l10n.email,
            prefixIcon: const Icon(Iconsax.sms),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Password
        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: l10n.password,
            prefixIcon: const Icon(Iconsax.lock),
            suffixIcon: IconButton(
              icon: Icon(_showPassword ? Iconsax.eye : Iconsax.eye_slash),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Confirm Password
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_showConfirmPassword,
          decoration: InputDecoration(
            labelText: l10n.confirmPassword,
            prefixIcon: const Icon(Iconsax.lock_1),
            suffixIcon: IconButton(
              icon: Icon(_showConfirmPassword ? Iconsax.eye : Iconsax.eye_slash),
              onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildNavigationButtons(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        if (_currentStep > 0)
          OutlinedButton.icon(
            onPressed: () => setState(() => _currentStep--),
            icon: const Icon(Iconsax.arrow_left),
            label: Text(l10n.previous),
          ),
        
        const SizedBox(width: 16),
        
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleNext,
            icon: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Icon(_currentStep == 3 ? Iconsax.tick_circle : Iconsax.arrow_right_3),
            label: Text(_currentStep == 3 ? l10n.createAccount : l10n.next),
          ),
        ),
      ],
    );
  }
  
  void _handleNext() {
    if (_currentStep == 0) {
      if (_selectedType != null) {
        setState(() => _currentStep++);
      } else {
        ErrorDialog.show(context, errorCode: 'SELECT_TYPE_REQUIRED', errorMessage: 'Please select a service type');
      }
    } else if (_currentStep == 1) {
      if (_codeVerified) {
        setState(() => _currentStep++);
      } else {
        ErrorDialog.show(context, errorCode: 'VERIFY_CODE_REQUIRED', errorMessage: 'Please verify valid registration code');
      }
    } else if (_currentStep == 2) {
      if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty && _addressController.text.isNotEmpty && _selectedLocation != null) {
         if (_selectedType == 'doctor' && _selectedSpecialty == null) {
            ErrorDialog.show(context, errorCode: 'SPECIALTY_REQUIRED', errorMessage: 'Please select a specialty');
            return;
         }
         setState(() => _currentStep++);
      } else {
        ErrorDialog.show(context, errorCode: 'PROFILE_INFO_INCOMPLETE', errorMessage: 'Please fill all required fields and select location');
      }
    } else if (_currentStep == 3) {
      _handleSubmit();
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length < 5) {
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
       await ErrorDialog.show(
        context,
        errorCode: 'INVALID_CODE',
        errorMessage: isArabic ? 'الكود غير صحيح' : 'Invalid Code',
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.verifyCode(
        code: _codeController.text,
        type: _selectedType!.toLowerCase(),
      );
      
      setState(() => _isLoading = false);
      
      if (response.isSuccess) {
          setState(() => _codeVerified = true);
          final isArabic = Localizations.localeOf(context).languageCode == 'ar';
          await SuccessDialog.show(
          context,
          title: isArabic ? 'كود صحيح' : 'Valid Code',
          message: isArabic ? 'تم التحقق من الكود بنجاح' : 'Registration code verified successfully',
        );
      } else {
         await ErrorDialog.show(
          context,
          errorCode: response.errorCode ?? 'UNKNOWN_ERROR',
          errorMessage: response.errorMessage ?? 'Unknown error',
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      await ErrorDialog.show(context, errorCode: 'NETWORK_ERROR', errorMessage: e.toString());
    }
  }
  
  Future<void> _handleSubmit() async {
    // Validate passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      await ErrorDialog.show(
        context,
        errorCode: 'PASSWORDS_DO_NOT_MATCH',
      );
      return;
    }
    
    // Validate password length
    if (_passwordController.text.length < 8) {
       await ErrorDialog.show(
        context,
        errorCode: 'WEAK_PASSWORD',
        errorMessage: 'Password must be at least 8 characters',
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final api = ref.read(apiServiceProvider);
      final ApiResponse<Map<String, dynamic>> response;
      
      if (_selectedType == 'doctor') {
        response = await api.registerDoctor(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          registrationCode: _codeController.text,
          specialtyId: _selectedSpecialty!,
          phone: _phoneController.text,
          address: _addressController.text,
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
          description: _descriptionController.text.isNotEmpty 
              ? _descriptionController.text 
              : null,
        );
      } else if (_selectedType == 'pharmacy') {
        response = await api.registerPharmacy(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          registrationCode: _codeController.text,
          phone: _phoneController.text,
          address: _addressController.text,
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
          description: _descriptionController.text.isNotEmpty 
              ? _descriptionController.text 
              : null,
        );
      } else if (_selectedType == 'teacher') {
        if (_selectedGrades.isEmpty) {
           await ErrorDialog.show(context, errorCode: 'NO_GRADES_SELECTED', errorMessage: 'Please select at least one grade.');
           setState(() => _isLoading = false);
           return;
        }

        response = await api.registerTeacher(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          registrationCode: _codeController.text,
          subjectId: _selectedSpecialty!,
          phone: _phoneController.text,
          address: _addressController.text,
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
          pricing: _selectedGrades.map((g) => {'grade_name': g.name, 'price': g.price}).toList(),
          description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        );
      } else {
        setState(() => _isLoading = false);
        await ErrorDialog.show(
          context,
          errorCode: 'FEATURE_COMING_SOON',
        );
        return;
      }
      
      setState(() => _isLoading = false);
      
      if (response.isSuccess) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        await SuccessDialog.show(
          context,
          title: isArabic ? 'تم التسجيل بنجاح' : 'Registration Successful',
          message: isArabic ? 'يرجى تسجيل الدخول' : 'Please login to continue',
          onDismiss: () => context.go('/login'),
        );
      } else {
        await ErrorDialog.show(
          context,
          errorCode: response.errorCode ?? 'REGISTRATION_FAILED',
          errorMessage: response.errorMessage ?? 'Registration failed',
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      await ErrorDialog.show(context, errorCode: 'NETWORK_ERROR', errorMessage: e.toString());
    }
  }
}

class _TypeOption {
  final String id;
  final IconData icon;
  final String title;
  final bool available;
  
  const _TypeOption({
    required this.id,
    required this.icon,
    required this.title,
    required this.available,
  });
}

class SelectedGrade {
  final String name;
  final double price;
  final int subjectId;
  
  SelectedGrade({required this.name, required this.price, required this.subjectId});
}

/// Subject data with grade level restrictions
class SubjectData {
  final int id;
  final String nameAr;
  final String nameEn;
  final List<String> gradeLevels;
  
  const SubjectData({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.gradeLevels,
  });
  
  /// Get list of allowed grades for this subject
  List<String> getAllowedGrades({
    required List<String> primary1_3,
    required List<String> primary4_6,
    required List<String> preparatory,
    required List<String> secondary,
  }) {
    final grades = <String>[];
    
    for (final level in gradeLevels) {
      switch (level) {
        case 'primary':
          grades.addAll(primary1_3);
          grades.addAll(primary4_6);
          break;
        case 'primary_1_3':
          grades.addAll(primary1_3);
          break;
        case 'primary_4_6':
          grades.addAll(primary4_6);
          break;
        case 'preparatory':
          grades.addAll(preparatory);
          break;
        case 'secondary':
          grades.addAll(secondary);
          break;
      }
    }
    
    return grades;
  }
}

/// All available subjects with their grade restrictions
const List<SubjectData> kSubjects = [
  // All levels
  SubjectData(id: 1, nameAr: 'لغة عربية', nameEn: 'Arabic', gradeLevels: ['primary', 'preparatory', 'secondary']),
  SubjectData(id: 2, nameAr: 'لغة إنجليزية', nameEn: 'English', gradeLevels: ['primary', 'preparatory', 'secondary']),
  SubjectData(id: 3, nameAr: 'رياضيات', nameEn: 'Mathematics', gradeLevels: ['primary', 'preparatory', 'secondary']),
  SubjectData(id: 4, nameAr: 'تحفيظ قرآن', nameEn: 'Quran', gradeLevels: ['primary', 'preparatory', 'secondary']),
  // Primary 1-3 only
  SubjectData(id: 5, nameAr: 'تأسيس أطفال', nameEn: 'Kids Foundation', gradeLevels: ['primary_1_3']),
  // Primary 4-6 + Prep
  SubjectData(id: 6, nameAr: 'دراسات اجتماعية', nameEn: 'Social Studies', gradeLevels: ['primary_4_6', 'preparatory']),
  SubjectData(id: 7, nameAr: 'علوم', nameEn: 'Science', gradeLevels: ['primary_4_6', 'preparatory']),
  // Prep + Secondary
  SubjectData(id: 8, nameAr: 'لغة فرنسية', nameEn: 'French', gradeLevels: ['preparatory', 'secondary']),
  SubjectData(id: 9, nameAr: 'لغة ألمانية', nameEn: 'German', gradeLevels: ['preparatory', 'secondary']),
  SubjectData(id: 10, nameAr: 'برمجة', nameEn: 'Programming', gradeLevels: ['preparatory', 'secondary']),
  // Secondary only
  SubjectData(id: 11, nameAr: 'فيزياء', nameEn: 'Physics', gradeLevels: ['secondary']),
  SubjectData(id: 12, nameAr: 'كيمياء', nameEn: 'Chemistry', gradeLevels: ['secondary']),
  SubjectData(id: 13, nameAr: 'أحياء', nameEn: 'Biology', gradeLevels: ['secondary']),
  SubjectData(id: 14, nameAr: 'جغرافيا', nameEn: 'Geography', gradeLevels: ['secondary']),
  SubjectData(id: 15, nameAr: 'تاريخ', nameEn: 'History', gradeLevels: ['secondary']),
  SubjectData(id: 16, nameAr: 'فلسفة ومنطق', nameEn: 'Philosophy', gradeLevels: ['secondary']),
  SubjectData(id: 17, nameAr: 'علم نفس واجتماع', nameEn: 'Psychology & Sociology', gradeLevels: ['secondary']),
  SubjectData(id: 18, nameAr: 'إحصاء', nameEn: 'Statistics', gradeLevels: ['secondary']),
];

