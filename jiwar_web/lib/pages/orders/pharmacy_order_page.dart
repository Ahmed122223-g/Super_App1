import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/providers/current_user_provider.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:jiwar_web/widgets/dialogs/saved_profiles_picker.dart';

class PharmacyOrderPage extends ConsumerStatefulWidget {
  final int pharmacyId;
  final String pharmacyName;
  final double? rating;

  const PharmacyOrderPage({
    super.key,
    required this.pharmacyId,
    required this.pharmacyName,
    this.rating,
  });

  @override
  ConsumerState<PharmacyOrderPage> createState() => _PharmacyOrderPageState();
}

class _PharmacyOrderPageState extends ConsumerState<PharmacyOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _notesController = TextEditingController();

  String _orderType = 'text'; // 'text' or 'prescription'
  String? _prescriptionBase64;
  String? _prescriptionFileName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null) {
        _nameController.text = user['name'] ?? '';
        _phoneController.text = user['phone'] ?? '';
        _addressController.text = user['address'] ?? '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _medicationsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'اختر مصدر الصورة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Iconsax.camera,
                  label: 'الكاميرا',
                  onTap: () => _getImage(ImageSource.camera),
                ),
                _buildSourceOption(
                  icon: Iconsax.gallery,
                  label: 'الاستوديو',
                  onTap: () => _getImage(ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _pickSavedProfile() async {
    final profile = await SavedProfilesPicker.show(context);
    if (profile != null) {
      if (profile['contact_name'] != null) _nameController.text = profile['contact_name'];
      if (profile['contact_phone'] != null) _phoneController.text = profile['contact_phone'];
      if (profile['address'] != null) _addressController.text = profile['address'];
    }
  }


  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 80, // Basic compression
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _prescriptionBase64 = base64Encode(bytes);
          _prescriptionFileName = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في اختيار الصورة: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate order content
    if (_orderType == 'text' && _medicationsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة اسم الأدوية المطلوبة'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_orderType == 'prescription' && _prescriptionBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى رفع صورة الروشتة'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    final api = ApiService();
    final response = await api.createOrder(
      pharmacyId: widget.pharmacyId,
      itemsText: _orderType == 'text' ? _medicationsController.text : null,
      prescriptionImage: _orderType == 'prescription' ? _prescriptionBase64 : null,
      customerName: _nameController.text,
      customerPhone: _phoneController.text,
      customerAddress: _addressController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (response.isSuccess) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.errorMessage ?? 'حدث خطأ'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog() {
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
              child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 20),
            const Text(
              'تم إرسال طلبك بنجاح!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'ستقوم الصيدلية بتسعير الطلب وإرساله إليك',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green, Colors.green.shade700],
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
                      child: const Icon(Iconsax.hospital, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.pharmacyName,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    if (widget.rating != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            widget.rating!.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
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
                    // Order Type Selection
                    _buildSectionTitle('طريقة الطلب', textColor),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildOrderTypeCard(
                            title: 'كتابة الأدوية',
                            subtitle: 'اكتب اسم الأدوية المطلوبة',
                            icon: Iconsax.edit,
                            isSelected: _orderType == 'text',
                            onTap: () => setState(() => _orderType = 'text'),
                            cardColor: cardColor,
                            borderColor: borderColor,
                            textColor: textColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOrderTypeCard(
                            title: 'رفع روشتة',
                            subtitle: 'ارفع صورة الروشتة',
                            icon: Iconsax.gallery,
                            isSelected: _orderType == 'prescription',
                            onTap: () => setState(() => _orderType = 'prescription'),
                            cardColor: cardColor,
                            borderColor: borderColor,
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Order Content based on type
                    if (_orderType == 'text') ...[
                      _buildSectionTitle('الأدوية المطلوبة', textColor),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _medicationsController,
                        label: 'اكتب اسم الأدوية (كل دواء في سطر)',
                        icon: Iconsax.document_text,
                        maxLines: 5,
                        hint: 'مثال:\nبنادول 500mg - علبة واحدة\nفيتامين سي - عبوتين',
                        fillColor: isDark ? Colors.grey[800]! : Colors.white,
                        borderColor: borderColor,
                      ),
                    ] else ...[
                      _buildSectionTitle('صورة الروشتة', textColor),
                      const SizedBox(height: 12),
                      _buildPrescriptionUpload(cardColor, borderColor, textColor),
                    ],
                    const SizedBox(height: 24),

                    // Delivery Info
                    // Delivery Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle('بيانات التوصيل', textColor),
                        TextButton.icon(
                          onPressed: _pickSavedProfile,
                          icon: const Icon(Iconsax.import, size: 18),
                          label: const Text("استيراد من المحفوظات"),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _nameController,
                      label: 'الاسم الكامل',
                      icon: Iconsax.user,
                      validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                      fillColor: isDark ? Colors.grey[800]! : Colors.white,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'رقم الهاتف',
                      icon: Iconsax.call,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                      fillColor: isDark ? Colors.grey[800]! : Colors.white,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _addressController,
                      label: 'عنوان التوصيل',
                      icon: Iconsax.location,
                      maxLines: 2,
                      validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                      fillColor: isDark ? Colors.grey[800]! : Colors.white,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _notesController,
                      label: 'ملاحظات إضافية (اختياري)',
                      icon: Iconsax.note,
                      maxLines: 2,
                      fillColor: isDark ? Colors.grey[800]! : Colors.white,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 32),

                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Iconsax.info_circle, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'ستقوم الصيدلية بمراجعة طلبك وإرسال السعر الإجمالي قبل التأكيد',
                              style: TextStyle(color: Colors.blue[700], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitOrder,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Iconsax.send_1),
                        label: const Text('إرسال الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
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
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
    );
  }

  Widget _buildOrderTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
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
          color: isSelected ? Colors.green.withOpacity(0.1) : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green : borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.green : Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.green : textColor),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionUpload(Color cardColor, Color borderColor, Color textColor) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _prescriptionBase64 != null ? Colors.green : borderColor,
            width: 2,
            style: _prescriptionBase64 != null ? BorderStyle.solid : BorderStyle.none,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            if (_prescriptionBase64 != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(_prescriptionBase64!),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100]?.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Icon(
                  Iconsax.gallery_add,
                  color: Colors.grey,
                  size: 40,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              _prescriptionBase64 != null ? 'تم رفع الصورة' : 'اضغط لرفع صورة الروشتة أو تصويرها',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _prescriptionBase64 != null ? Colors.green : textColor.withOpacity(0.7),
              ),
            ),
            if (_prescriptionFileName != null) ...[
              const SizedBox(height: 4),
              Text(
                _prescriptionFileName!,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
            if (_prescriptionBase64 != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() {
                  _prescriptionBase64 = null;
                  _prescriptionFileName = null;
                }),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('إزالة'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
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
        prefixIcon: Icon(icon, color: Colors.green),
        filled: true,
        fillColor: fillColor,
        labelStyle: TextStyle(color: Colors.grey[600]), // Ensures label is readable
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
          borderSide: const BorderSide(color: Colors.green),
        ),
      ),
    );
  }

}
