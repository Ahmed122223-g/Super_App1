import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiwar_web/core/theme/app_theme.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
import 'package:jiwar_web/core/services/api_service.dart';

class SupportPage extends ConsumerStatefulWidget {
  const SupportPage({super.key});

  @override
  ConsumerState<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends ConsumerState<SupportPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController(); // Added email field
  bool _isLoading = false;
  int? _expandedIndex;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final faqs = [
      {'q': l10n.faq1Q, 'a': l10n.faq1A},
      {'q': l10n.faq2Q, 'a': l10n.faq2A},
      {'q': l10n.faq3Q, 'a': l10n.faq3A},
      {'q': l10n.faq4Q, 'a': l10n.faq4A},
      {'q': l10n.faq5Q, 'a': l10n.faq5A},
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.supportTitle, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: isDark ? Colors.white : Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Iconsax.support, size: 50, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.contactSubtitle,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // FAQs
            Text(
              l10n.faqTitle,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: faqs.length,
              itemBuilder: (context, index) {
                final isExpanded = _expandedIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isExpanded ? AppColors.primary : (isDark ? Colors.grey[800]! : Colors.grey[200]!)),
                    boxShadow: isExpanded ? [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 10)] : [],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      key: Key(index.toString()),
                      initiallyExpanded: isExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() => _expandedIndex = expanded ? index : null);
                      },
                      leading: Icon(
                        isExpanded ? Iconsax.minus_square : Iconsax.add_square,
                        color: isExpanded ? AppColors.primary : Colors.grey[500],
                      ),
                      title: Text(
                        faqs[index]['q']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isExpanded ? AppColors.primary : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Text(
                            faqs[index]['a']!,
                            style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[600], height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Contact Form
            Text(
              l10n.contactTitle,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.email,
                        prefixIcon: const Icon(Iconsax.sms),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return l10n.required;
                        if (!value.contains('@')) return l10n.invalidEmail;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Subject Field
                    TextFormField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        labelText: l10n.subjectLabel,
                        hintText: l10n.subjectHint,
                        prefixIcon: const Icon(Iconsax.message_text),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
                      ),
                      validator: (value) => value!.isEmpty ? l10n.required : null,
                    ),
                    const SizedBox(height: 16),

                    // Message Field
                    TextFormField(
                      controller: _messageController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: l10n.messageLabel,
                        hintText: l10n.messageHint,
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
                      ),
                      validator: (value) => value!.isEmpty ? l10n.required : null,
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 5,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Iconsax.send_1, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Text(
                                    l10n.sendMessage,
                                    style: const TextStyle(
                                      fontSize: 16, 
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        // Prepare data
        final data = {
          "email": _emailController.text,
          "subject": _subjectController.text,
          "message": _messageController.text,
        };

        // Call Backend API
        final dio = Dio(BaseOptions(baseUrl: ApiService.baseUrl));
        await dio.post('/utils/contact-support', data: data); // Using the new endpoint

        setState(() => _isLoading = false);
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                   const Icon(Icons.check_circle, color: Colors.white),
                   const SizedBox(width: 12),
                   Expanded(child: Text(AppLocalizations.of(context)!.contactSuccessMessage)),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          _subjectController.clear();
          _messageController.clear();
          // Email controller kept as users might send multiple messages
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.messageError),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
