import 'package:flutter/material.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:jiwar_web/widgets/dialogs/error_dialog.dart';
import 'package:jiwar_web/widgets/dialogs/success_dialog.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';

class PharmacyProfileTab extends StatefulWidget {
  const PharmacyProfileTab({super.key});

  @override
  State<PharmacyProfileTab> createState() => _PharmacyProfileTabState();
}

class _PharmacyProfileTabState extends State<PharmacyProfileTab> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Profile data
  String _name = '';
  String _email = '';
  String _address = '';
  
  // Editable fields
  bool _deliveryAvailable = false;
  final _phoneController = TextEditingController();
  
  // Working hours
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 21, minute: 0);
  final Map<String, bool> _workingDays = {
    'saturday': true,
    'sunday': true,
    'monday': true,
    'tuesday': true,
    'wednesday': true,
    'thursday': true,
    'friday': false,
  };

  final _api = ApiService();

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
      _name = data['name'] ?? '';
      _email = data['email'] ?? '';
      _address = data['address'] ?? '';
      _deliveryAvailable = data['delivery_available'] ?? false;
      _phoneController.text = data['phone'] ?? '';
      
      // Parse working hours if available
      final workingHours = data['working_hours'];
      if (workingHours is Map) {
        // Parse start time
        if (workingHours['start'] != null) {
          final parts = workingHours['start'].toString().split(':');
          if (parts.length >= 2) {
            _startTime = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 9,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
        }
        // Parse end time
        if (workingHours['end'] != null) {
          final parts = workingHours['end'].toString().split(':');
          if (parts.length >= 2) {
            _endTime = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 21,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
        }
        // Parse working days
        if (workingHours['days'] is Map) {
          final days = workingHours['days'] as Map;
          for (final day in _workingDays.keys) {
            if (days[day] != null) {
              _workingDays[day] = days[day] as bool;
            }
          }
        }
      }
      
      setState(() => _isLoading = false);
    } else {
      setState(() => _isLoading = false);
      if (mounted) ErrorDialog.show(context, errorCode: 'LOAD_ERROR', errorMessage: response.errorMessage);
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);
    
    final workingHoursMap = {
      'start': _formatTime(_startTime),
      'end': _formatTime(_endTime),
      'days': _workingDays,
    };
    
    final response = await _api.updatePharmacyProfile(
      deliveryAvailable: _deliveryAvailable,
      workingHours: workingHoursMap,
      phone: _phoneController.text,
    );

    setState(() => _isSaving = false);

    if (response.isSuccess) {
      if (mounted) SuccessDialog.show(context, title: l10n.updateSuccess, message: l10n.updateSuccess);
    } else {
      if (mounted) ErrorDialog.show(context, errorCode: 'UPDATE_ERROR', errorMessage: response.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    // Use l10n for day names
    final dayNames = {
      'saturday': l10n.daySaturday,
      'sunday': l10n.daySunday,
      'monday': l10n.dayMonday,
      'tuesday': l10n.dayTuesday,
      'wednesday': l10n.dayWednesday,
      'thursday': l10n.dayThursday,
      'friday': l10n.dayFriday,
    };

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.updateProfile, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            
            // Name (Read Only)
            TextFormField(
              initialValue: _name,
              readOnly: true,
              style: TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: l10n.name,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.backgroundDark,
                suffixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondaryDark),
                labelStyle: TextStyle(color: AppColors.textSecondaryDark),
              ),
            ),
            const SizedBox(height: 16),
            
            // Email (Read Only)
            TextFormField(
              initialValue: _email,
              readOnly: true,
              style: TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: l10n.email,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.backgroundDark,
                prefixIcon: const Icon(Icons.email, color: AppColors.textSecondaryDark),
                suffixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondaryDark),
                labelStyle: TextStyle(color: AppColors.textSecondaryDark),
              ),
            ),
            const SizedBox(height: 16),
            
            // Address (Read Only)
            TextFormField(
              initialValue: _address,
              readOnly: true,
              style: TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: l10n.address,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.backgroundDark,
                prefixIcon: const Icon(Icons.location_on, color: AppColors.textSecondaryDark),
                suffixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondaryDark),
                labelStyle: TextStyle(color: AppColors.textSecondaryDark),
              ),
            ),
            const SizedBox(height: 24),
            
            const Divider(),
            
            // Delivery Toggle
            SwitchListTile(
              title: Text(l10n.deliveryAvailable),
              subtitle: Text(l10n.enableDeliveryService),
              value: _deliveryAvailable,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _deliveryAvailable = v),
            ),
            
            // Phone (Only visible if delivery is enabled)
            if (_deliveryAvailable) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.deliveryContactNumber,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone, color: AppColors.primary),
                  helperText: l10n.deliveryContactNumberHint,
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // Working Hours Section
            Text(
              l10n.workingHours,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Time Pickers
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(true),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.from,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.access_time),
                      ),
                      child: Text(
                        _startTime.format(context),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(false),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.to,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.access_time),
                      ),
                      child: Text(
                        _endTime.format(context),
                        style: Theme.of(context).textTheme.titleMedium,
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
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _workingDays.entries.map((entry) {
                return FilterChip(
                  label: Text(
                    dayNames[entry.key] ?? entry.key,
                    style: TextStyle(
                      color: entry.value ? AppColors.primary : AppColors.textSecondaryDark,
                      fontWeight: entry.value ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: entry.value,
                  onSelected: (selected) {
                    setState(() => _workingDays[entry.key] = selected);
                  },
                  backgroundColor: AppColors.backgroundDark,
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  checkmarkColor: AppColors.primary,
                  side: BorderSide(
                    color: entry.value ? AppColors.primary : AppColors.dividerDark,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                icon: const Icon(Icons.save),
                label: _isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
