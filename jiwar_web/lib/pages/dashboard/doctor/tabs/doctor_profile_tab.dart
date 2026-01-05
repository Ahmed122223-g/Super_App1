import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:jiwar_web/widgets/dialogs/error_dialog.dart';
import 'package:jiwar_web/widgets/dialogs/success_dialog.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';

class DoctorProfileTab extends StatefulWidget {
  const DoctorProfileTab({super.key});

  @override
  State<DoctorProfileTab> createState() => _DoctorProfileTabState();
}

class _DoctorProfileTabState extends State<DoctorProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _phoneController = TextEditingController(); 
  final _addressController = TextEditingController();
  final _feeController = TextEditingController();
  final _examFeeController = TextEditingController();
  final _descController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _profileImageUrl;
  
  // Working hours
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  Map<String, bool> _workingDays = {
    'saturday': true,
    'sunday': true,
    'monday': true,
    'tuesday': true,
    'wednesday': true,
    'thursday': true,
    'friday': false,
  };

  final _api = ApiService();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final response = await _api.getProfile();
    
    if (response.isSuccess) {
      final data = response.data!;
      _nameController.text = data['name'] ?? '';
      _emailController.text = data['email'] ?? '';
      _specialtyController.text = data['specialty']?['name_ar'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _addressController.text = data['address'] ?? '';
      _descController.text = data['description'] ?? '';
      _feeController.text = data['consultation_fee']?.toString() ?? '0.0';
      _examFeeController.text = data['examination_fee']?.toString() ?? '0.0';
      _profileImageUrl = data['profile_image'];
      
      // Load working hours
      if (data['working_hours'] != null) {
        final wh = data['working_hours'];
        if (wh['start'] != null) {
          final parts = (wh['start'] as String).split(':');
          _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
        if (wh['end'] != null) {
          final parts = (wh['end'] as String).split(':');
          _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
        if (wh['days'] != null) {
          _workingDays = Map<String, bool>.from(wh['days']);
        }
      }
      
      setState(() => _isLoading = false);
    } else {
      setState(() => _isLoading = false);
      if (mounted) ErrorDialog.show(context, errorCode: 'LOAD_ERROR', errorMessage: response.errorMessage);
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() => _isSaving = true);
        
        final bytes = await pickedFile.readAsBytes();
        final response = await _api.uploadFile(bytes.toList(), pickedFile.name);
        
        if (response.isSuccess) {
          setState(() {
            _profileImageUrl = response.data!['url'];
            _isSaving = false;
          });
        } else {
          setState(() => _isSaving = false);
          if (mounted) ErrorDialog.show(context, errorCode: 'UPLOAD_ERROR', errorMessage: response.errorMessage);
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ErrorDialog.show(context, errorCode: 'IMAGE_ERROR', errorMessage: e.toString());
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isSaving = true);

    final response = await _api.updateDoctorProfile(
      phone: _phoneController.text,
      address: _addressController.text,
      description: _descController.text,
      consultationFee: double.tryParse(_feeController.text),
      examinationFee: double.tryParse(_examFeeController.text),
      profileImage: _profileImageUrl,
      workingHours: {
        'start': '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        'end': '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        'days': _workingDays,
      },
    );

    setState(() => _isSaving = false);

    if (response.isSuccess) {
      if (mounted) {
        SuccessDialog.show(
          context,
          title: l10n.updateSuccess,
          message: l10n.updateSuccess,
        );
      }
    } else {
      if (mounted) ErrorDialog.show(context, errorCode: 'UPDATE_ERROR', errorMessage: response.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                l10n.updateProfile,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              // Profile Image Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Profile Image
                    Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 3),
                            image: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(ApiService.staticUrl + _profileImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                              ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            color: AppColors.primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: _pickImage,
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    // Name Display
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _specialtyController.text.isNotEmpty ? _specialtyController.text : l10n.doctors,
                            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.upload),
                            label: Text(l10n.profileImage),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Form Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name (Read Only)
                      TextFormField(
                        controller: _nameController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: l10n.name,
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: AppColors.backgroundDark,
                          prefixIcon: const Icon(Icons.person, color: AppColors.textSecondaryDark),
                          suffixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondaryDark),
                          labelStyle: TextStyle(color: AppColors.textSecondaryDark),
                        ),
                        style: TextStyle(color: AppColors.textPrimaryDark),
                      ),
                      const SizedBox(height: 16),
                      
                      // Email (Read Only)
                      TextFormField(
                        controller: _emailController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: l10n.email,
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: AppColors.backgroundDark,
                          prefixIcon: const Icon(Icons.email, color: AppColors.textSecondaryDark),
                          suffixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondaryDark),
                          labelStyle: TextStyle(color: AppColors.textSecondaryDark),
                        ),
                        style: TextStyle(color: AppColors.textPrimaryDark),
                      ),
                      const SizedBox(height: 16),
                      
                      // Specialty (Read Only)
                      TextFormField(
                        controller: _specialtyController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: l10n.specialty,
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: AppColors.backgroundDark,
                          prefixIcon: const Icon(Icons.medical_services, color: AppColors.textSecondaryDark),
                          suffixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondaryDark),
                          labelStyle: TextStyle(color: AppColors.textSecondaryDark),
                        ),
                        style: TextStyle(color: AppColors.textPrimaryDark),
                      ),
                      const SizedBox(height: 24),
                      
                      // Examination Fee (سعر الكشف)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.info.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.examinationFeeTitle,
                              style: TextStyle(
                                color: AppColors.info,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.local_hospital, color: AppColors.info, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _examFeeController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      hintText: '100.0',
                                      border: InputBorder.none,
                                      suffixText: 'EGP',
                                      suffixStyle: TextStyle(color: AppColors.textSecondaryDark, fontWeight: FontWeight.bold),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return l10n.required;
                                      if (double.tryParse(v) == null) return l10n.invalidNumber;
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Consultation Fee (سعر الاستشارة)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.consultationFeeTitle,
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.chat, color: AppColors.success, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _feeController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      hintText: '50.0',
                                      border: InputBorder.none,
                                      suffixText: 'EGP',
                                      suffixStyle: TextStyle(color: AppColors.textSecondaryDark, fontWeight: FontWeight.bold),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return l10n.required;
                                      if (double.tryParse(v) == null) return l10n.invalidNumber;
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Phone
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: l10n.phone,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Address
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: l10n.address,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.location_on),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Description / Bio
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: l10n.description,
                          hintText: l10n.aboutYouHint,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.info_outline),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Working Hours Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.workingHours,
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Time Pickers Row
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: _startTime,
                                      );
                                      if (time != null) setState(() => _startTime = time);
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: l10n.from,
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.access_time),
                                      ),
                                      child: Text(
                                        '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: _endTime,
                                      );
                                      if (time != null) setState(() => _endTime = time);
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: l10n.to,
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.access_time),
                                      ),
                                      child: Text(
                                        '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Working Days
                            Text(
                              l10n.workingDaysLabel,
                              style: TextStyle(color: AppColors.textSecondaryDark),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final entry in _workingDays.entries)
                                  FilterChip(
                                    label: Text(
                                      _getDayName(entry.key, l10n),
                                      style: TextStyle(
                                        color: entry.value ? AppColors.secondary : AppColors.textSecondaryDark,
                                        fontWeight: entry.value ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    selected: entry.value,
                                    onSelected: (selected) {
                                      setState(() => _workingDays[entry.key] = selected);
                                    },
                                    backgroundColor: AppColors.backgroundDark,
                                    selectedColor: AppColors.secondary.withOpacity(0.2),
                                    checkmarkColor: AppColors.secondary,
                                    side: BorderSide(
                                      color: entry.value ? AppColors.secondary : AppColors.dividerDark,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _saveProfile,
                          icon: _isSaving ? null : const Icon(Icons.save),
                          label: _isSaving 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(l10n.save, style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getDayName(String day, AppLocalizations l10n) {
    final names = {
      'saturday': l10n.daySaturday,
      'sunday': l10n.daySunday,
      'monday': l10n.dayMonday,
      'tuesday': l10n.dayTuesday,
      'wednesday': l10n.dayWednesday,
      'thursday': l10n.dayThursday,
      'friday': l10n.dayFriday,
    };
    return names[day] ?? day;
  }
}
