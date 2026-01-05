import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';

import '../../widgets/navbar/navbar.dart';
import '../../widgets/footer/footer.dart';

/// Terms of Use Page
class TermsPage extends ConsumerWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isSmallScreen = MediaQuery.of(context).size.width < 900;
    
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Navbar(isTransparent: false),
            
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 24 : 80),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.termsOfUse,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'آخر تحديث: ديسمبر 2024 | Last updated: December 2024',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildSection(
                      context,
                      title: '1. قبول الشروط',
                      titleEn: '1. Acceptance of Terms',
                      content: '''
باستخدام تطبيق جوار، فإنك توافق على الالتزام بهذه الشروط والأحكام. إذا كنت لا توافق على أي جزء من هذه الشروط، يرجى عدم استخدام التطبيق.

By using the Jiwar app, you agree to be bound by these terms and conditions. If you do not agree to any part of these terms, please do not use the app.
                      ''',
                    ),
                    
                    _buildSection(
                      context,
                      title: '2. استخدام الخدمة',
                      titleEn: '2. Use of Service',
                      content: '''
يجب عليك:
- تقديم معلومات صحيحة ودقيقة
- الحفاظ على سرية حسابك
- عدم استخدام الخدمة لأغراض غير قانونية
- الالتزام بجميع القوانين المحلية

You must:
- Provide accurate and truthful information
- Keep your account confidential
- Not use the service for illegal purposes
- Comply with all local laws
                      ''',
                    ),
                    
                    _buildSection(
                      context,
                      title: '3. حسابات مقدمي الخدمات',
                      titleEn: '3. Service Provider Accounts',
                      content: '''
لمقدمي الخدمات (أطباء، صيدليات، إلخ):
- يجب تقديم وثائق صحيحة للتحقق
- الالتزام بمعايير الجودة
- تحديث المعلومات بانتظام
- الرد على استفسارات المستخدمين

For service providers (doctors, pharmacies, etc.):
- Must provide valid documents for verification
- Commit to quality standards
- Update information regularly
- Respond to user inquiries
                      ''',
                    ),
                    
                    _buildSection(
                      context,
                      title: '4. إخلاء المسؤولية',
                      titleEn: '4. Disclaimer',
                      content: '''
جوار هو منصة وساطة فقط:
- لا نتحمل مسؤولية جودة الخدمات المقدمة
- لا نضمن دقة المعلومات المقدمة من مقدمي الخدمات
- المستخدم مسؤول عن التحقق من المعلومات

Jiwar is a mediation platform only:
- We are not responsible for the quality of services provided
- We do not guarantee the accuracy of information provided by service providers
- Users are responsible for verifying information
                      ''',
                    ),
                    
                    _buildSection(
                      context,
                      title: '5. حقوق الملكية الفكرية',
                      titleEn: '5. Intellectual Property',
                      content: '''
جميع المحتويات والتصميمات والشعارات هي ملك لجوار:
- لا يجوز نسخ أو توزيع أي محتوى بدون إذن
- العلامات التجارية محمية قانونياً

All content, designs, and logos are property of Jiwar:
- Content may not be copied or distributed without permission
- Trademarks are legally protected
                      ''',
                    ),
                    
                    _buildSection(
                      context,
                      title: '6. تعديل الشروط',
                      titleEn: '6. Modification of Terms',
                      content: '''
نحتفظ بالحق في تعديل هذه الشروط في أي وقت. سيتم إخطارك بأي تغييرات جوهرية.

We reserve the right to modify these terms at any time. You will be notified of any substantial changes.
                      ''',
                    ),
                    
                    _buildSection(
                      context,
                      title: '7. القانون المطبق',
                      titleEn: '7. Applicable Law',
                      content: '''
تخضع هذه الشروط للقانون المصري. أي نزاع سيتم حله في المحاكم المصرية المختصة.

These terms are governed by Egyptian law. Any dispute will be resolved in the competent Egyptian courts.
                      ''',
                    ),
                  ],
                ),
              ),
            ),
            
            const Footer(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(BuildContext context, {
    required String title,
    required String titleEn,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title / $titleEn',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.8,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
