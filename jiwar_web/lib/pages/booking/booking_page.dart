import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/providers/current_user_provider.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:jiwar_web/widgets/dialogs/saved_profiles_picker.dart';

class BookingPage extends ConsumerStatefulWidget {
  final int providerId;
  final String providerType; // "doctor" or "teacher"
  final String providerName;
  final String? specialty;
  final double? examinationFee;
  final double? consultationFee;

  const BookingPage({
    super.key,
    required this.providerId,
    required this.providerType,
    required this.providerName,
    this.specialty,
    this.examinationFee,
    this.consultationFee,
  });

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedType = 'examination'; // examination or consultation
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot; // Now stores specific time like "14:00"
  List<String> _availableSlots = [];
  bool _isLoadingSlots = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null) {
        _nameController.text = user['name'] ?? '';
        _phoneController.text = user['phone'] ?? '';
      }
      if (widget.providerType == 'doctor') {
        _loadSlots();
      }
    });
  }

  Future<void> _loadSlots() async {
    if (widget.providerType != 'doctor') return;
    
    setState(() {
      _isLoadingSlots = true;
      _selectedTimeSlot = null;
      _availableSlots = [];
    });
    
    final api = ApiService();
    final response = await api.getDoctorSlots(
      doctorId: widget.providerId,
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
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
    
    // Parse selected time slot (HH:MM)
    final timeParts = _selectedTimeSlot!.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    DateTime visitDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    );
    
    final api = ApiService();
    final response = await api.createBooking(
      providerId: widget.providerId,
      providerType: widget.providerType,
      bookingType: _selectedType,
      visitDate: visitDateTime,
      patientName: _nameController.text,
      patientPhone: _phoneController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      if (response.isSuccess) {
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'تم إرسال الحجز بنجاح!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'سيتم إشعارك عند تأكيد الحجز',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close booking page
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDoctor = widget.providerType == 'doctor';
    final primaryColor = isDoctor ? Colors.blue : Colors.purple;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Premium Header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDoctor ? Iconsax.health : Iconsax.teacher,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.providerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.specialty != null)
                      Text(
                        widget.specialty!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Booking Type Selection (for doctors)
                    if (isDoctor && (widget.examinationFee != null || widget.consultationFee != null)) ...[
                      _buildSectionTitle(l10n.selectBookingType, textColor),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (widget.examinationFee != null)
                            Expanded(
                              child: _buildTypeCard(
                                title: l10n.examination,
                                price: widget.examinationFee!,
                                icon: Iconsax.health,
                                color: Colors.blue,
                                isSelected: _selectedType == 'examination',
                                onTap: () => setState(() => _selectedType = 'examination'),
                                cardColor: cardColor,
                                borderColor: borderColor,
                                textColor: textColor,
                              ),
                            ),
                          if (widget.examinationFee != null && widget.consultationFee != null)
                            const SizedBox(width: 12),
                          if (widget.consultationFee != null)
                            Expanded(
                              child: _buildTypeCard(
                                title: l10n.consultation,
                                price: widget.consultationFee!,
                                icon: Iconsax.message,
                                color: Colors.green,
                                isSelected: _selectedType == 'consultation',
                                onTap: () => setState(() => _selectedType = 'consultation'),
                                cardColor: cardColor,
                                borderColor: borderColor,
                                textColor: textColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Date Selection
                    _buildSectionTitle(l10n.selectDate, textColor),
                    const SizedBox(height: 12),
                    _buildDatePicker(cardColor, borderColor, textColor, l10n),
                    const SizedBox(height: 24),
                    
                    // Time Slot Selection
                    _buildSectionTitle(l10n.selectTime, textColor),
                    const SizedBox(height: 12),
                    if (_isLoadingSlots)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ))
                    else if (_availableSlots.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            Icon(Iconsax.calendar_remove, size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 10),
                            Text(
                              l10n.noSlotsAvailable,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _availableSlots.map((slot) {
                          final isSelected = _selectedTimeSlot == slot;
                          return ChoiceChip(
                            label: Text(
                              slot, 
                              style: TextStyle(
                                color: isSelected ? Colors.white : textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedTimeSlot = selected ? slot : null);
                            },
                            selectedColor: primaryColor,
                            backgroundColor: cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? primaryColor : borderColor,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 24),
                    
                    // Patient Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle(l10n.patientInfo, textColor),
                        TextButton.icon(
                          onPressed: _pickSavedProfile,
                          icon: const Icon(Iconsax.import, size: 18),
                          label: Text(l10n.import, style: const TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _nameController,
                      label: l10n.fullName,
                      icon: Iconsax.user,
                      validator: (v) => v == null || v.isEmpty ? l10n.required : null,
                      fillColor: isDark ? Colors.grey[800]! : Colors.white,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _notesController,
                      label: l10n.notesOptional,
                      icon: Iconsax.note,
                      maxLines: 3,
                      fillColor: isDark ? Colors.grey[800]! : Colors.white,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 32),
                    
                    // Summary Card
                    _buildSummaryCard(primaryColor, cardColor, borderColor, textColor, l10n),
                    const SizedBox(height: 24),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                l10n.confirmBooking,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  Widget _buildTypeCard({
    required String title,
    required double price,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : color.withOpacity(0.7), size: 32),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? color : textColor)),
            const SizedBox(height: 4),
            Text(
              '${price.toInt()} ${AppLocalizations.of(context)!.egp}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? color : textColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(Color cardColor, Color borderColor, Color textColor, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: AppColors.primary),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
          if (widget.providerType == 'doctor') {
            _loadSlots();
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Iconsax.calendar, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.selectedDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM yyyy', Localizations.localeOf(context).languageCode).format(_selectedDate),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
    required Color fillColor,
    required Color borderColor,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: fillColor,
        labelStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Color primaryColor, Color cardColor, Color borderColor, Color textColor, AppLocalizations l10n) {
    final isDoctor = widget.providerType == 'doctor';
    final price = _selectedType == 'examination' 
        ? widget.examinationFee 
        : widget.consultationFee;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Iconsax.receipt, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                l10n.bookingSummary,
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 16),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildSummaryRow(l10n.doctorLabel, widget.providerName, textColor),
          if (isDoctor && price != null)
            _buildSummaryRow(l10n.selectBookingType, _selectedType == 'examination' ? l10n.examination : l10n.consultation, textColor),
          _buildSummaryRow(l10n.dateLabel, DateFormat('d MMMM yyyy', Localizations.localeOf(context).languageCode).format(_selectedDate), textColor),
          _buildSummaryRow(l10n.timeLabel, _selectedTimeSlot ?? l10n.notSelected, textColor),
          if (isDoctor && price != null) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.totalAmount, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                Text(
                  '${price.toInt()} ${l10n.egp}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
        ],
      ),
    );
  }
}
