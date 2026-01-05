import 'package:flutter/material.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/widgets/dialogs/error_dialog.dart';
import 'package:jiwar_web/widgets/dialogs/success_dialog.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';

class TeacherProfileTab extends StatefulWidget {
  const TeacherProfileTab({super.key});

  @override
  State<TeacherProfileTab> createState() => _TeacherProfileTabState();
}

class _TeacherProfileTabState extends State<TeacherProfileTab> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Controllers
  final _descController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  
  List<Map<String, dynamic>> _pricing = [];
  String? _profileImageUrl;
  
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
      _subjectController.text = data['subject']?['name_ar'] ?? data['subject_name'] ?? '';
      _descController.text = data['description'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _whatsappController.text = data['whatsapp'] ?? '';
      _profileImageUrl = data['profile_image'];
      
      if (data['pricing'] is List) {
        _pricing = List<Map<String, dynamic>>.from(data['pricing'].map((x) => {
          'grade_name': x['grade_name'],
          'price': x['price'],
          'id': x['id'],
        }));
      }
      
      setState(() => _isLoading = false);
    } else {
      setState(() => _isLoading = false);
      if (mounted) ErrorDialog.show(context, errorCode: 'LOAD_ERROR', errorMessage: response.errorMessage);
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
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
      if (mounted) ErrorDialog.show(context, errorCode: 'UPLOAD_ERROR', errorMessage: e.toString());
    }
  }

  /// Edit only the price for a class (grade name is read-only)
  void _editPriceOnly(int index) {
    final l10n = AppLocalizations.of(context)!;
    final item = _pricing[index];
    final priceController = TextEditingController(text: item['price']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.edit} ${item['grade_name']}'),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l10n.price),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              if (priceController.text.isEmpty) return;
              
              setState(() {
                _pricing[index] = {
                  ..._pricing[index],
                  'price': double.tryParse(priceController.text) ?? 0,
                };
              });
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);

    final response = await _api.updateTeacherProfile(
      description: _descController.text,
      phone: _phoneController.text,
      whatsapp: _whatsappController.text,
      profileImage: _profileImageUrl,
      pricing: _pricing,
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

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.updateProfile, 
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.textPrimaryDark)
            ),
            const SizedBox(height: 24),
            
            // Image Picker
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _profileImageUrl != null
                        ? NetworkImage(ApiService.staticUrl + _profileImageUrl!)
                        : null,
                    backgroundColor: AppColors.backgroundDark,
                    child: _profileImageUrl == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        onPressed: _pickImage,
                        tooltip: l10n.uploadImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Name (Read Only)
            TextFormField(
              controller: _nameController,
              readOnly: true,
              style: const TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: l10n.name,
                labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.backgroundDark,
                suffixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondaryDark),
              ),
            ),
            const SizedBox(height: 16),
            
            // Email (Read Only)
            TextFormField(
              controller: _emailController,
              readOnly: true,
              style: const TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: l10n.email,
                labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.backgroundDark,
                prefixIcon: const Icon(Icons.email, color: AppColors.textSecondaryDark),
                suffixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondaryDark),
              ),
            ),
            const SizedBox(height: 16),
            
            // Subject (Read Only)
            TextFormField(
              controller: _subjectController,
              readOnly: true,
              style: const TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: l10n.subjectLabel,
                labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.backgroundDark,
                prefixIcon: const Icon(Icons.school, color: AppColors.textSecondaryDark),
                suffixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondaryDark),
              ),
            ),
            const SizedBox(height: 16),
            
            // Phone (Editable)
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: l10n.phone,
                labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.phone, color: AppColors.primary),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.dividerDark)),
              ),
            ),
            const SizedBox(height: 16),
             
            // WhatsApp (Editable)
            TextFormField(
              controller: _whatsappController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: "WhatsApp",
                labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.message, color: Colors.green),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.dividerDark)),
              ),
            ),
            const SizedBox(height: 16),
            
            // Description (Editable)
            TextFormField(
              controller: _descController,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: l10n.description,
                labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.info_outline, color: AppColors.primary),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.dividerDark)),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            
            // Pricing Section - Only Edit Price
            Text(
              l10n.pricing, 
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.textPrimaryDark)
            ),
            const SizedBox(height: 8),
            Text(
              l10n.editPricesOnly,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 16),
            
            if (_pricing.isEmpty)
              Text(
                l10n.noClassesRegistered,
                style: const TextStyle(color: AppColors.textSecondaryDark),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pricing.length,
                itemBuilder: (context, index) {
                  final item = _pricing[index];
                  return Card(
                    color: AppColors.backgroundDark,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.class_, color: Colors.white),
                      ),
                      title: Text(item['grade_name'] ?? '', style: const TextStyle(color: AppColors.textPrimaryDark)),
                      subtitle: Text('${item['price']} EGP', style: const TextStyle(color: AppColors.primary)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
                        onPressed: () => _editPriceOnly(index),
                        tooltip: l10n.editPrice,
                      ),
                    ),
                  );
                },
              ),
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
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

