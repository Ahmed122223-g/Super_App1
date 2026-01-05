import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jiwar_web/core/providers/current_user_provider.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:jiwar_web/widgets/dialogs/saved_profiles_picker.dart';

class TeacherBookingDialog extends ConsumerStatefulWidget {
  final int teacherId;
  final String teacherName;
  final List<Map<String, dynamic>> availableGrades; // [{'grade': '...', 'price': 100}]

  const TeacherBookingDialog({
    super.key,
    required this.teacherId,
    required this.teacherName,
    required this.availableGrades,
  });

  @override
  ConsumerState<TeacherBookingDialog> createState() => _TeacherBookingDialogState();
}

class _TeacherBookingDialogState extends ConsumerState<TeacherBookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedGradeLevel;
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
    });

    // Auto-select if only one grade is available
    if (widget.availableGrades.length == 1) {
      _selectedGradeLevel = widget.availableGrades.first['grade'];
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

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final api = ApiService();
    // Default time to current time as date picker is removed
    final requestedDateTime = DateTime.now();

    final response = await api.requestTeacherBooking(
      teacherId: widget.teacherId,
      studentName: _nameController.text,
      studentPhone: _phoneController.text,
      gradeLevel: _selectedGradeLevel,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      requestedDate: requestedDateTime,
    );
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      if (response.isSuccess) {
        Navigator.pop(context); // Close dialog
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.errorMessage ?? 'حدث خطأ'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
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
                    color: Colors.purple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.tick_circle, color: Colors.purple, size: 60),
                ),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: const Text(
                  'تم إرسال طلبك بنجاح!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  'سيقوم المعلم بمراجعة طلبك وإرسال قائمة بالمواعيد المتاحة لتختار منها.',
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
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('حسناً، فهمت', style: TextStyle(fontWeight: FontWeight.bold)),
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
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
                  colors: [Colors.purple, Colors.deepPurple],
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
                    child: const Icon(Iconsax.teacher, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'حجز درس خصوصي',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'مع أ/${widget.teacherName}',
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
                      // Student Info Card
                      // Student Info Card
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionLabel('بيانات الطالب'),
                          TextButton.icon(
                            onPressed: _pickSavedProfile,
                            icon: const Icon(Iconsax.import, size: 18),
                            label: const Text("استيراد", style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.purple,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      _buildAnimatedField(
                        delay: 0,
                        child: _buildTextField(
                          controller: _nameController,
                          label: 'اسم الطالب ثلاثي',
                          icon: Iconsax.user,
                          validator: (v) => v?.isEmpty == true ? 'يرجى إدخال اسم الطالب' : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildAnimatedField(
                        delay: 100,
                        child: _buildTextField(
                          controller: _phoneController,
                          label: 'رقم ولي الأمر / الطالب',
                          icon: Iconsax.call,
                          keyboardType: TextInputType.phone,
                          validator: (v) => v?.isEmpty == true ? 'يرجى إدخال رقم التواصل' : null,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Academic Info
                      _buildSectionLabel('تفاصيل الدراسة'),
                      const SizedBox(height: 12),

                      _buildAnimatedField(
                        delay: 200,
                        child: DropdownButtonFormField<String>(
                          value: _selectedGradeLevel,
                          decoration: _getInputDecoration('الصف الدراسي', Iconsax.book),
                          items: widget.availableGrades.map((item) {
                            final grade = item['grade'] as String;
                            final price = item['price']; // numeric or string
                            
                            String label = grade;
                            if (price != null) {
                              label += ' (${price.toString()} ج.م)';
                            }

                            return DropdownMenuItem(
                              value: grade,
                              child: Text(label, style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedGradeLevel = val),
                          validator: (val) => val == null ? 'يجب اختيار الصف الدراسي' : null,
                          icon: const Icon(Iconsax.arrow_down_1, size: 18),
                          isExpanded: true,
                          hint: const Text('اختر الصف الدراسي'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildAnimatedField(
                        delay: 300,
                        child: _buildTextField(
                          controller: _notesController,
                          label: 'ملاحظات إضافية للمعلم',
                          icon: Iconsax.note,
                          maxLines: 3,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Submit Button
                      FadeInUp(
                        delay: const Duration(milliseconds: 500),
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: Colors.purple.withOpacity(0.4),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'إرسال طلب الحجز',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Iconsax.send_2),
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
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
        letterSpacing: 0.5,
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: _getInputDecoration(label, icon),
    );
  }

  InputDecoration _getInputDecoration(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? Colors.grey[800]! : Colors.grey[50]!;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;

    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      prefixIcon: Icon(icon, color: Colors.purple),
      filled: true,
      fillColor: fillColor,
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
        borderSide: const BorderSide(color: Colors.purple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}
