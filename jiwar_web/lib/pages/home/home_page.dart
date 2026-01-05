import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/navbar/navbar.dart';
import '../../widgets/footer/footer.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final isScrolled = _scrollController.offset > 50;
    if (isScrolled != _isScrolled) {
      setState(() => _isScrolled = isScrolled);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Hero Section
                _HeroSection(l10n: l10n),
                
                // Search Bar Section
                _SearchSection(l10n: l10n),
                
                // Services Section
                _ServicesSection(l10n: l10n),
                
                // How It Works Section
                _HowItWorksSection(l10n: l10n),
                
                // Footer
                const Footer(),
              ],
            ),
          ),
          
          // Fixed Navbar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _isScrolled
                    ? Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95)
                    : Colors.transparent,
                boxShadow: _isScrolled
                    ? [BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      )]
                    : null,
              ),
              child: Navbar(isTransparent: !_isScrolled),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero Section with gradient background
class _HeroSection extends StatelessWidget {
  final AppLocalizations l10n;
  
  const _HeroSection({required this.l10n});
  
  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 24 : 80,
        120,
        isSmallScreen ? 24 : 80,
        isSmallScreen ? 40 : 80,
      ),
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.heroGradient
            : const LinearGradient(
                colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFF8FAFC)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '🌟 ${l10n.appName} - ${l10n.appTagline}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            l10n.heroTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Subtitle
          SizedBox(
            width: isSmallScreen ? double.infinity : 600,
            child: Text(
              l10n.heroSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Stats
          Wrap(
            spacing: isSmallScreen ? 24 : 64,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _StatItem(value: '100+', label: l10n.doctors),
              _StatItem(value: '50+', label: l10n.pharmacies),
              _StatItem(value: '1000+', label: l10n.reviews),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  
  const _StatItem({required this.value, required this.label});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

/// Search Section with Category Buttons
class _SearchSection extends StatelessWidget {
  final AppLocalizations l10n;
  
  const _SearchSection({required this.l10n});
  
  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 900;
    
    // Define categories with their icons, colors, and types
    final categories = [
      {'icon': Iconsax.health, 'label': l10n.doctors, 'type': 'doctor', 'color': AppColors.primary, 'available': true},
      {'icon': Iconsax.hospital, 'label': l10n.pharmacies, 'type': 'pharmacy', 'color': AppColors.secondary, 'available': true},
      {'icon': Iconsax.book_1, 'label': l10n.teachers, 'type': 'teacher', 'color': Colors.green, 'available': true},
      {'icon': Iconsax.reserve, 'label': l10n.restaurants, 'type': 'restaurant', 'color': Colors.orange, 'available': false},
      {'icon': Iconsax.building, 'label': l10n.companies, 'type': 'company', 'color': Colors.blue, 'available': false},
      {'icon': Iconsax.cpu, 'label': l10n.engineers, 'type': 'engineer', 'color': Colors.purple, 'available': false},
      {'icon': Iconsax.setting_2, 'label': l10n.mechanics, 'type': 'mechanic', 'color': Colors.red, 'available': false},
    ];
    
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 40),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Text(
                Localizations.localeOf(context).languageCode == 'ar' ? 'اعثر على' : 'Find',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
            children: categories.map((cat) {
              return _buildCategoryCard(
                context,
                icon: cat['icon'] as IconData,
                label: cat['label'] as String,
                color: cat['color'] as Color,
                onTap: (cat['available'] as bool) 
                    ? () => context.go('/search?type=${cat['type']}')
                    : null,
                isSmallScreen: isSmallScreen,
                isAvailable: cat['available'] as bool,
              );
            }).toList(),
          ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCategoryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    required bool isSmallScreen,
    required bool isAvailable,
  }) {
    // Card width depends on screen size - 2 columns on mobile, up to 6 on desktop
    final width = isSmallScreen 
        ? (MediaQuery.of(context).size.width - 48) / 2 // 2 columns minus padding/spacing
        : 140.0;
        
    return Material(
      color: Theme.of(context).cardColor,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: width,
          height: 150,
          padding: const EdgeInsets.all(16),
          child: Opacity(
            opacity: isAvailable ? 1.0 : 0.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isAvailable) ...[
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.comingSoon,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Services Section
class _ServicesSection extends StatelessWidget {
  final AppLocalizations l10n;
  
  const _ServicesSection({required this.l10n});
  
  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 900;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 24 : 80,
        vertical: 80,
      ),
      child: Column(
        children: [
          // Section header
          Text(
            l10n.servicesTitle,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.servicesSubtitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 48),
          
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _ServiceCard(
                icon: Iconsax.health,
                title: l10n.doctors,
                description: l10n.doctorsDesc,
                color: AppColors.primary,
                available: true,
              ),
              _ServiceCard(
                icon: Iconsax.hospital,
                title: l10n.pharmacies,
                description: l10n.pharmaciesDesc,
                color: AppColors.secondary,
                available: true,
              ),
              _ServiceCard(
                icon: Iconsax.reserve,
                title: l10n.restaurants,
                description: l10n.comingSoon,
                color: AppColors.accentGold,
                available: false,
              ),
              _ServiceCard(
                icon: Iconsax.building,
                title: l10n.companies,
                description: l10n.comingSoon,
                color: AppColors.info,
                available: false,
              ),
              _ServiceCard(
                icon: Iconsax.cpu,
                title: l10n.engineers,
                description: l10n.comingSoon,
                color: AppColors.warning,
                available: false,
              ),
              _ServiceCard(
                icon: Iconsax.setting_2,
                title: l10n.mechanics,
                description: l10n.comingSoon,
                color: AppColors.error,
                available: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool available;
  
  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.available,
  });
  
  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.available ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: widget.available ? (_) => setState(() => _isHovered = true) : null,
      onExit: widget.available ? (_) => setState(() => _isHovered = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 180,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered ? widget.color : Theme.of(context).dividerColor.withOpacity(0.3),
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: _isHovered
              ? [BoxShadow(
                  color: widget.color.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )]
              : null,
        ),
        transform: _isHovered 
            ? Matrix4.translationValues(0, -5, 0)
            : Matrix4.identity(),
        child: Opacity(
          opacity: widget.available ? 1.0 : 0.5,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.icon,
                  size: 32,
                  color: widget.color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// How It Works Section
class _HowItWorksSection extends StatelessWidget {
  final AppLocalizations l10n;
  
  const _HowItWorksSection({required this.l10n});
  
  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 24 : 80,
        vertical: 80,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF8FAFC),
      ),
      child: Column(
        children: [
          Text(
            l10n.howItWorks,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 48),
          
          Wrap(
            spacing: 48,
            runSpacing: 48,
            alignment: WrapAlignment.center,
            children: [
              _StepCard(
                number: '1',
                icon: Iconsax.search_normal,
                title: l10n.step1Title,
                description: l10n.step1Desc,
              ),
              _StepCard(
                number: '2',
                icon: Iconsax.map,
                title: l10n.step2Title,
                description: l10n.step2Desc,
              ),
              _StepCard(
                number: '3',
                icon: Iconsax.call,
                title: l10n.step3Title,
                description: l10n.step3Desc,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String description;
  
  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, size: 36, color: Colors.white),
              ),
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Join Us Section
class _JoinUsSection extends StatelessWidget {
  final AppLocalizations l10n;
  
  const _JoinUsSection({required this.l10n});
  
  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 900;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 24 : 80,
        vertical: 80,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmallScreen ? 32 : 64),
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          children: [
            Text(
              l10n.joinAsProvider,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: isSmallScreen ? double.infinity : 500,
              child: Text(
                l10n.joinDesc,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/signup_admin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              ),
              child: Text(l10n.registerNow),
            ),
          ],
        ),
      ),
    );
  }
}
