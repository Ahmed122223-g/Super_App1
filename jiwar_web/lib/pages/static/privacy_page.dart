import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';

import '../../widgets/navbar/navbar.dart';
import '../../widgets/footer/footer.dart';

/// Privacy Policy Page
class PrivacyPage extends ConsumerWidget {
  const PrivacyPage({super.key});

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
                      l10n.privacyPolicy,
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
                      title: '1. جمع المعلومات',
                      titleEn: '1. Information Collection',
                      content: '''
نقوم بجمع المعلومات التالية:
- معلومات الحساب: الاسم، البريد الإلكتروني، رقم الهاتف
- معلومات الموقع: لعرض الخدمات القريبة منك
- معلومات الاستخدام: لتحسين تجربة المستخدم

We collect the following information:
- Account information: Name, email, phone number
- Location information: To display services near you
- Usage information: To improve user experience
                      ''',
                    ),
                    
                    _buildSection(
                      context,
                      title: '2. استخدام المعلومات',
                      titleEn: '2. Use of Information',
                      content: '''
نستخدم معلوماتك من أجل:
- توفير الخدمات وتحسينها
- التواصل معك بشأن حسابك
- إرسال إشعارات مهمة
- حماية حسابك وأمانك

We use your information to:
- Provide and improve services
- Communicate with you about your account
- Send important notifications
- Protect your account and security
                      ''',
                    ),
                    
                    _buildSection(
                      context,
                      title: '3. حماية المعلومات',
                      titleEn: '3. Information Protection',
                      content: '''
نتخذ إجراءات أمنية صارمة لحماية معلوماتك الشخصية:
- تشفير البيانات
- تخزين آمن
- الوصول المحدود للموظفين
- مراجعات أمنية دورية

We take strict security measures to protect your personal information:
- Data encryption
- Secure storage
- Limited employee access
- Regular security audits
                      ''',
                    ),
                    
                    _buildSection(
                      context,
                      title: '4. مشاركة المعلومات',
                      titleEn: '4. Information Sharing',
                      content: '''
لا نبيع أو نشارك معلوماتك الشخصية مع أطراف ثالثة إلا في الحالات التالية:
- بموافقتك الصريحة
- للامتثال للقانون
- لحماية حقوقنا

We do not sell or share your personal information with third parties except:
- With your explicit consent
- To comply with the law
- To protect our rights
                      ''',
                    ),
                    
                    _buildSection(
                      context,
                      title: '5. حقوقك',
                      titleEn: '5. Your Rights',
                      content: '''
لديك الحق في:
- الوصول إلى معلوماتك
- تصحيح معلوماتك
- حذف حسابك
- الاعتراض على المعالجة

You have the right to:
- Access your information
- Correct your information
- Delete your account
- Object to processing
                      ''',
                    ),
                    
                    _buildSection(
                      context,
                      title: '6. التواصل',
                      titleEn: '6. Contact',
                      content: '''
للاستفسارات المتعلقة بالخصوصية:
البريد الإلكتروني: ahmedmohamed1442006m@gmail.com

For privacy-related inquiries:
Email: ahmedmohamed1442006m@gmail.com
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
