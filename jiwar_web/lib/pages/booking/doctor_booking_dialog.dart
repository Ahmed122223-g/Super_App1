import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jiwar_web/core/providers/current_user_provider.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';
import 'package:jiwar_web/widgets/dialogs/saved_profiles_picker.dart';

class DoctorBookingDialog extends ConsumerStatefulWidget {
  final int doctorId;
  final String doctorName;
  final String specialty;
  final double? examinationFee;
  final double? consultationFee;

  const DoctorBookingDialog({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    this.examinationFee,
    this.consultationFee,
  });

  @override
  ConsumerState<DoctorBookingDialog> createState() => _DoctorBookingDialogState();
}

class _DoctorBookingDialogState extends ConsumerState<DoctorBookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedType = 'examination'; // examination or consultation
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;
  List<String> _availableSlots = [];
  bool _isLoadingSlots = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null) {
        _nameController.text = user['name'] ?? '';
        _phoneController.text = user['phone'] ?? '';
      }
      _loadSlots();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _selectedTimeSlot = null;
      _availableSlots = [];
    });
    
    final api = ApiService();
    final response = await api.getDoctorSlots(
      doctorId: widget.doctorId,
      date: _selectedDate,
    );
    
    if (mounted) {
      setState(() {
        _isLoadingSlots = false;
        if (response.isSuccess && response.data != null) {
          _availableSlots = response.data!;
        }
      });
    }
  }

  Future<void> _pickSavedProfile() async {
    final profile = await SavedProfilesPicker.show(context);
    if (profile != null) {
      if (profile['contact_name'] != null) _nameController.text = profile['contact_name'];
      if (profile['contact_phone'] != null) _phoneController.text = profile['contact_phone'];
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectTimeSlot)),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final timeParts = _selectedTimeSlot!.split(':');
    final visitDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    final api = ApiService();
    final response = await api.createBooking(
      providerId: widget.doctorId,
      providerType: 'doctor',
      bookingType: _selectedType,
      visitDate: visitDateTime,
      patientName: _nameController.text,
      patientPhone: _phoneController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      if (response.isSuccess) {
        Navigator.pop(context);
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.errorMessage ?? l10n.errorOccurred),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeInDown(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.tick_circle, color: Colors.blue, size: 60),
                ),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: const Text(
                  'تم تأكيد الحجز!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  'سيتم إشعارك بتفاصيل الحجز قريباً.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(l10n.ok, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.health, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.bookAppointment,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'د/ ${widget.doctorName}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Booking Type
                       if (widget.examinationFee != null || widget.consultationFee != null) ...[
                        _buildSectionLabel(l10n.selectBookingType),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (widget.examinationFee != null)
                              Expanded(
                                child: _buildTypeCard(
                                  title: l10n.examination,
                                  price: widget.examinationFee!,
                                  isSelected: _selectedType == 'examination',
                                  onTap: () => setState(() => _selectedType = 'examination'),
                                  isDark: isDark,
                                  color: Colors.blue,
                                ),
                              ),
                            if (widget.examinationFee != null && widget.consultationFee != null)
                              const SizedBox(width: 12),
                            if (widget.consultationFee != null)
                              Expanded(
                                child: _buildTypeCard(
                                  title: l10n.consultation,
                                  price: widget.consultationFee!,
                                  isSelected: _selectedType == 'consultation',
                                  onTap: () => setState(() => _selectedType = 'consultation'),
                                  isDark: isDark,
                                  color: Colors.green,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Date Selection
                      _buildSectionLabel(l10n.selectDate),
                      const SizedBox(height: 12),
                      _buildDatePicker(l10n, isDark),
                      const SizedBox(height: 24),

                      // Time Slot
                      _buildSectionLabel(l10n.selectTime),
                      const SizedBox(height: 12),
                      if (_isLoadingSlots)
                        const Center(child: CircularProgressIndicator())
                      else if (_availableSlots.isEmpty)
                         Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(l10n.noSlotsAvailable, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                         )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableSlots.map((slot) {
                            final isSelected = _selectedTimeSlot == slot;
                            return ChoiceChip(
                              label: Text(slot),
                              selected: isSelected,
                              onSelected: (selected) => setState(() => _selectedTimeSlot = selected ? slot : null),
                              selectedColor: Colors.blue,
                              labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black)),
                              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),

                      // Patient Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionLabel(l10n.patientInfo),
                          TextButton.icon(
                            onPressed: _pickSavedProfile,
                            icon: const Icon(Iconsax.import, size: 18),
                            label: Text(l10n.import, style: const TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildAnimatedField(
                        delay: 100,
                        child: _buildTextField(
                          controller: _nameController,
                          label: l10n.fullName,
                          icon: Iconsax.user,
                          validator: (v) => v?.isEmpty == true ? l10n.required : null,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAnimatedField(
                        delay: 200,
                        child: _buildTextField(
                          controller: _phoneController,
                          label: l10n.phone,
                          icon: Iconsax.call,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v?.isEmpty == true ? l10n.required : null,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAnimatedField(
                        delay: 300,
                        child: _buildTextField(
                          controller: _notesController,
                          label: l10n.notesOptional,
                          icon: Iconsax.note,
                          maxLines: 3,
                          isDark: isDark,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Submit Button
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: Colors.blue.withOpacity(0.4),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        l10n.confirmBooking,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Iconsax.calendar_tick),
                                    ],
                                  ),
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
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTypeCard({
    required String title,
    required double price,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : (isDark ? Colors.grey[800] : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? color : (isDark ? Colors.white : Colors.black87), fontSize: 13)),
            const SizedBox(height: 4),
            Text('${price.toInt()} EGP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? color : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(AppLocalizations l10n, bool isDark) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
          _loadSlots();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const Icon(Iconsax.calendar, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('EEEE, d MMMM yyyy', l10n.localeName).format(_selectedDate),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedField({required int delay, required Widget child}) {
    return FadeInUp(
      delay: Duration(milliseconds: delay),
      duration: const Duration(milliseconds: 500),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    required bool isDark,
  }) {
    final fillColor = isDark ? Colors.grey[800]! : Colors.grey[50]!;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        filled: true,
        fillColor: fillColor,
        labelStyle: TextStyle(color: Colors.grey[500]),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    );
  }
}
