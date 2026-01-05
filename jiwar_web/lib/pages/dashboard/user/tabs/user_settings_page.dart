import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiwar_web/core/providers/auth_provider.dart';
import 'package:jiwar_web/core/providers/current_user_provider.dart';
import 'package:jiwar_web/core/providers/app_providers.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';
import 'package:jiwar_web/pages/dashboard/user/profile_edit_page.dart';
import 'package:jiwar_web/pages/settings/about_app_page.dart';
import 'package:jiwar_web/pages/settings/support_page.dart';
import 'package:jiwar_web/pages/settings/legal_pages.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jiwar_web/pages/dashboard/user/tabs/addresses/address_book_page.dart';
import 'package:jiwar_web/core/providers/package_info_provider.dart';



class UserSettingsPage extends ConsumerWidget {
  const UserSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final locale = ref.watch(localeProvider);
    final isArabic = locale.languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: cardColor,
            foregroundColor: textColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
              title: Text(
                l10n.settings,
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                   _buildSectionHeader(context, l10n.accountSection), 
                  _buildSettingItem(
                    context,
                    icon: Iconsax.user_edit,
                    title: l10n.editProfile,
                    subtitle: l10n.editProfileSubtitle,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditPage()));
                    },
                  ),
                  _buildSettingItem(
                    context,
                    icon: Iconsax.location,
                    title: l10n.savedAddresses,
                    subtitle: l10n.savedAddressesSubtitle,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressBookPage()));
                    },
                  ),

                  const SizedBox(height: 24),

                  _buildSectionHeader(context, l10n.appSection),
                  _buildSettingItem(
                    context,
                    icon: Iconsax.translate,
                    title: l10n.languageTitle,
                    subtitle: isArabic ? "العربية" : "English",
                    trailing: Switch(
                      value: isArabic, 
                      activeColor: AppColors.primary,
                      onChanged: (val) => ref.read(localeProvider.notifier).toggleLocale(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionHeader(context, l10n.legalSection),
                  _buildSettingItem(
                    context,
                    icon: Iconsax.document_text,
                    title: l10n.termsOfUse,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsPage())),
                  ),
                  _buildSettingItem(
                    context,
                    icon: Iconsax.shield_tick,
                    title: l10n.privacyPolicy,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPage())),
                  ),
                  _buildSettingItem(
                    context,
                    icon: Iconsax.judge,
                    title: l10n.licenses,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LicensesPage())),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader(context, l10n.otherSection),
                  _buildSettingItem(
                    context,
                    icon: Iconsax.info_circle,
                    title: l10n.aboutApp,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAppPage())),
                  ),
                  _buildSettingItem(
                    context,
                    icon: Iconsax.support,
                    title: l10n.helpSupport,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportPage())),
                  ),
                  
                  // Danger Zone
                  _buildDangerZone(context, ref),

                  const SizedBox(height: 32),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Confirm Dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.logout),
                            content: Text(l10n.confirmLogout),
                            actions: [
                              TextButton(onPressed: ()=>Navigator.pop(context), child: Text(l10n.cancel)),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ref.read(authProvider.notifier).logout();
                                  context.go('/login');
                                }, 
                                child: Text(l10n.yes, style: const TextStyle(color: Colors.red))
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Iconsax.logout),
                      label: Text(l10n.logout),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.withOpacity(0.1),
                        foregroundColor: AppColors.error,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Consumer(
                    builder: (context, ref, _) {
                       final infoAsync = ref.watch(packageInfoProvider);
                       return infoAsync.when(
                         data: (info) => Text(
                           "Version ${info.version}",
                           style: TextStyle(color: Colors.grey[400], fontSize: 12),
                         ),
                         loading: () => const SizedBox.shrink(),
                         error: (_,__) => const SizedBox.shrink(),
                       );
                    }
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final secondaryColor = Colors.grey[400];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.grey[300], size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor),
        ),
        subtitle: subtitle != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  subtitle,
                  style: TextStyle(color: secondaryColor, fontSize: 13),
                ),
              )
            : null,
        trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 16, color: secondaryColor),
      ),
    );
  }
  Widget _buildDangerZone(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dangerZone, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(l10n.deleteAccountWarning, style: const TextStyle(color: Colors.red, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showDeleteConfirmation(context, ref),
              icon: const Icon(Icons.delete_forever),
              label: Text(l10n.deleteAccount),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showEmailVerification(context, ref);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.sureDelete),
          ),
        ],
      ),
    );
  }

  void _showEmailVerification(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l10n.verifyIdentity),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(l10n.enterEmailToDelete),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                       labelText: l10n.email,
                       border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                       if (v == null || v.isEmpty) return l10n.required;
                       final userEmail = ref.read(currentUserProvider).valueOrNull?['email'];
                       if (v != userEmail) return l10n.emailMismatch;
                       return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  
                  setState(() => isLoading = true);
                  final api = ref.read(apiServiceProvider);
                  final res = await api.deleteAccount(emailController.text);
                  
                  if (context.mounted) {
                     setState(() => isLoading = false);
                     if (res.isSuccess) {
                        Navigator.pop(context); // Close dialog
                        // Logout
                        ref.read(authProvider.notifier).logout();
                        context.go('/login');
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text(l10n.accountDeleted), backgroundColor: Colors.red)
                        );
                     } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text(res.errorMessage ?? l10n.errorOccurred), backgroundColor: Colors.red)
                        );
                     }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: isLoading 
                   ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                   : Text(l10n.confirmDelete),
              ),
            ],
          );
        }
      ),
    );
  }
}
