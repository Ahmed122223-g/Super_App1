import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:jiwar_web/widgets/dialogs/confirm_dialog.dart';
import 'package:jiwar_web/widgets/dialogs/error_dialog.dart';
import 'package:jiwar_web/widgets/dialogs/success_dialog.dart';

class AddressBookPage extends StatefulWidget {
  const AddressBookPage({super.key});

  @override
  State<AddressBookPage> createState() => _AddressBookPageState();
}

class _AddressBookPageState extends State<AddressBookPage> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _addresses = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _api.getAddresses();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.isSuccess) {
          _addresses = response.data ?? [];
        } else {
          _error = response.errorMessage;
        }
      });
    }
  }

  Future<void> _deleteAddress(int id) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await ConfirmDialog.show(
      context,
      title: l10n.deleteAddressTitle,
      message: l10n.deleteAddressConfirm,
      confirmText: l10n.delete,
      isDestructive: true,
    );

    if (confirmed == true) {
      final response = await _api.deleteAddress(id);
      if (response.isSuccess) {
        if (mounted) {
          SuccessDialog.show(
            context,
            title: l10n.delete,
            message: l10n.deleteSuccess,
          );
        }
        _loadAddresses();
      } else {
        if (mounted) {
          ErrorDialog.show(
            context,
            errorCode: response.errorCode ?? 'UNKNOWN_ERROR',
            errorMessage: response.errorMessage,
          );
        }
      }
    }
  }

  void _showAddressDialog([Map<String, dynamic>? address]) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => _AddressDialog(
        address: address,
        onSave: (data) async {
          final isEdit = address != null;
          final response = isEdit 
              ? await _api.updateAddress(address['id'], data)
              : await _api.createAddress(data);

          if (mounted) {
            Navigator.pop(context);
            if (response.isSuccess) {
              SuccessDialog.show(
                context,
                title: isEdit ? l10n.edit : l10n.add,
                message: isEdit ? l10n.updateSuccessMessage : l10n.addSuccess,
              );
              _loadAddresses();
            } else {
              ErrorDialog.show(
                context,
                errorCode: response.errorCode ?? 'UNKNOWN_ERROR',
                errorMessage: response.errorMessage,
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(l10n.addressBookTitle, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            onPressed: () => _showAddressDialog(),
            icon: const Icon(Iconsax.add_circle, color: AppColors.primary),
            tooltip: l10n.addNewAddress,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.warning_2, size: 48, color: Colors.grey[500]),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: Colors.grey[400])),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAddresses,
                        child: const Text("إعادة المحاولة"),
                      ),
                    ],
                  ),
                )
              : _addresses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.location_slash, size: 64, color: Colors.grey[500]),
                          const SizedBox(height: 16),
                          Text(l10n.noSavedAddresses, style: TextStyle(color: Colors.grey[400])),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showAddressDialog(),
                            icon: const Icon(Iconsax.add),
                            label: Text(l10n.addAddress),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _addresses.length,
                      itemBuilder: (context, index) {
                        final address = _addresses[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: AppColors.surfaceDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[700]!),
                          ),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Iconsax.location, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            address['label'] ?? 'جهة اتصال',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          // Show Name and Phone
                                          if (address['contact_name'] != null)
                                            Row(
                                              children: [
                                                Icon(Iconsax.user, size: 14, color: Colors.grey[400]),
                                                const SizedBox(width: 4),
                                                Text(address['contact_name'], style: TextStyle(color: Colors.grey[300], fontSize: 13)),
                                              ],
                                            ),
                                          if (address['contact_phone'] != null)
                                            Row(
                                              children: [
                                                Icon(Iconsax.call, size: 14, color: Colors.grey[400]),
                                                const SizedBox(width: 4),
                                                Text(address['contact_phone'], style: TextStyle(color: Colors.grey[300], fontSize: 13)),
                                              ],
                                            ),
                                            
                                          if (address['is_default'] == true)
                                            Container(
                                              margin: const EdgeInsets.only(top: 4),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                "الافتراضي",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton(
                                      icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                                      color: AppColors.surfaceDark,
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Iconsax.edit, size: 18, color: Colors.grey[300]),
                                              const SizedBox(width: 8),
                                              Text(l10n.edit, style: TextStyle(color: Colors.grey[300])),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Iconsax.trash, size: 18, color: Colors.red),
                                              const SizedBox(width: 8),
                                              Text(l10n.delete, style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showAddressDialog(address);
                                        } else if (value == 'delete') {
                                          _deleteAddress(address['id']);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                Divider(height: 24, color: Colors.grey[700]),
                                Text(
                                  address['address_line'] ?? '',
                                  style: const TextStyle(fontSize: 14, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${address['city'] ?? ''} - ${address['district'] ?? ''}",
                                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _AddressDialog extends StatefulWidget {
  final Map<String, dynamic>? address;
  final Function(Map<String, dynamic>) onSave;

  const _AddressDialog({this.address, required this.onSave});

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _districtController;
  late TextEditingController _addressLineController;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.address?['label'] ?? '');
    _nameController = TextEditingController(text: widget.address?['contact_name'] ?? '');
    _phoneController = TextEditingController(text: widget.address?['contact_phone'] ?? '');
    
    // Parse address string roughly if city/district not separate (old data)
    // For now assuming existing fields or empty
    _cityController = TextEditingController(text: widget.address?['city'] ?? '');
    _districtController = TextEditingController(text: widget.address?['district'] ?? '');
    _addressLineController = TextEditingController(text: widget.address?['address_line'] ?? widget.address?['address'] ?? '');
    
    _isDefault = widget.address?['is_default'] ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _addressLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.address == null ? l10n.addNewAddress : l10n.editAddress,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _labelController,
                  decoration: InputDecoration(
                    labelText: l10n.labelHint,
                    prefixIcon: const Icon(Iconsax.tag),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty == true ? l10n.required : null,
                ),
                const SizedBox(height: 16),
                
                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.name,
                    prefixIcon: const Icon(Iconsax.user),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty == true ? l10n.required : null,
                ),
                const SizedBox(height: 16),
                
                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: l10n.phone,
                    prefixIcon: const Icon(Iconsax.call),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v?.isEmpty == true ? l10n.required : null,
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: l10n.city,
                          prefixIcon: const Icon(Iconsax.building),
                          border: const OutlineInputBorder(),
                        ),
                        // Address fields optional now? User said contact info, address "if booking requires it". 
                        // But let's keep it required for now as it's useful for pharmacy/home visit.
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _districtController,
                        decoration: InputDecoration(
                          labelText: l10n.district,
                          prefixIcon: const Icon(Iconsax.map),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _addressLineController,
                  decoration: InputDecoration(
                    labelText: l10n.addressDetails,
                    prefixIcon: const Icon(Iconsax.location),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                
                SwitchListTile(
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                  title: Text(l10n.setDefaultContext),
                  contentPadding: EdgeInsets.zero,
                ),
                
                const SizedBox(height: 24),
                
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Combine into 'address' field
                      final fullAddress = [
                        _addressLineController.text,
                        _districtController.text,
                        _cityController.text,
                      ].where((s) => s.isNotEmpty).join(', ');
                      
                      widget.onSave({
                        'label': _labelController.text,
                        'contact_name': _nameController.text,
                        'contact_phone': _phoneController.text,
                        'address': fullAddress,
                        'is_default': _isDefault,
                        if (widget.address?['latitude'] != null) 'latitude': widget.address!['latitude'],
                        if (widget.address?['longitude'] != null) 'longitude': widget.address!['longitude'],
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(widget.address == null ? l10n.add : l10n.saveChanges),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
