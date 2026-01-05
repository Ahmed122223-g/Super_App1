import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jiwar_web/core/services/api_service.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:jiwar_web/widgets/dialogs/error_dialog.dart';

class SavedProfilesPicker extends StatefulWidget {
  const SavedProfilesPicker({super.key});

  /// Shows the picker dialog and returns the selected profile (Map<String, dynamic>)
  static Future<Map<String, dynamic>?> show(BuildContext context) async {
    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const SavedProfilesPicker(),
    );
  }

  @override
  State<SavedProfilesPicker> createState() => _SavedProfilesPickerState();
}

class _SavedProfilesPickerState extends State<SavedProfilesPicker> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<dynamic> _profiles = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _api.getAddresses(); // Uses same API endpoint
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (response.isSuccess) {
          _profiles = response.data ?? [];
        } else {
          _error = response.errorMessage;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Iconsax.profile_2user, color: AppColors.primary),
                  const SizedBox(width: 12),
                  const Text(
                    "اختر من المحفوظات",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.grey),
            
            // List
            Flexible(
              child: _isLoading
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ))
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Iconsax.warning_2, color: Colors.orange, size: 32),
                                const SizedBox(height: 8),
                                Text(_error!, style: const TextStyle(color: Colors.grey)),
                                TextButton(
                                  onPressed: _loadProfiles,
                                  child: const Text("إعادة المحاولة"),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _profiles.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  "لا توجد بيانات محفوظة",
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(8),
                              itemCount: _profiles.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final profile = _profiles[index];
                                return _buildProfileItem(profile);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(Map<String, dynamic> profile) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context, profile),
        borderRadius: BorderRadius.circular(12),
        hoverColor: Colors.white.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[800]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.user, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile['label'] ?? 'بدون اسم',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile['contact_name'] ?? profile['label'] ?? '-',
                      style: TextStyle(color: Colors.grey[300], fontSize: 13),
                    ),
                    Text(
                      profile['contact_phone'] ?? '-',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Iconsax.arrow_left_2, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
