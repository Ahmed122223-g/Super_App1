import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';

import '../../widgets/navbar/navbar.dart';
import '../../widgets/footer/footer.dart';

/// About Us Page
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

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
                      l10n.aboutUs,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildSection(
                      context,
                      title: 'من نحن',
                      titleEn: 'Who We Are',
                      content: '''
جوار هو تطبيق شامل يهدف إلى ربط سكان مدينة الواسطي بمقدمي الخدمات المحليين. نسعى لتسهيل الوصول إلى الأطباء والصيدليات والخدمات الأخرى في منطقتك.

Jiwar is a comprehensive app that aims to connect residents of El-Wasty city with local service providers. We strive to make it easier to find doctors, pharmacies, and other services in your area.
                      ''',
                    ),
                    
                    _buildSection(
                      context,
                      title: 'رؤيتنا',
                      titleEn: 'Our Vision',
                      content: '''
نطمح لأن نكون المنصة الأولى التي يلجأ إليها المواطنون للعثور على أي خدمة محلية. نريد أن نجعل الحياة أسهل من خلال التكنولوجيا.

We aspire to be the first platform that citizens turn to for finding any local service. We want to make life easier through technology.
                      ''',
                    ),
                    
                    _buildSection(
                      context,
                      title: 'فريقنا',
                      titleEn: 'Our Team',
                      content: '''
فريق متحمس من المطورين والمصممين الذين يؤمنون بقوة التكنولوجيا في خدمة المجتمع. نعمل بجد لتقديم أفضل تجربة ممكنة للمستخدمين.

A passionate team of developers and designers who believe in the power of technology to serve the community. We work hard to provide the best possible experience for users.
                      ''',
                    ),
                    
                    _buildSection(
                      context,
                      title: 'تواصل معنا',
                      titleEn: 'Contact Us',
                      content: '''
البريد الإلكتروني: info@jiwar.app
الهاتف: +20 123 456 789
العنوان: الواسطي، بني سويف، مصر

Email: info@jiwar.app
Phone: +20 123 456 789
Address: El-Wasty, Beni Suef, Egypt
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
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title / $titleEn',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
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
