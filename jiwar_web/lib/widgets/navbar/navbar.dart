import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/theme/app_theme.dart';
import '../../core/providers/app_providers.dart';

/// Premium Navbar Widget
class Navbar extends ConsumerWidget {
  final bool isTransparent;
  
  const Navbar({
    super.key,
    this.isTransparent = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final isSmallScreen = MediaQuery.of(context).size.width < 1050;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 48,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: isTransparent 
            ? Colors.transparent 
            : Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
        border: isTransparent 
            ? null 
            : Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
      ),
      child: Row(
        children: [
          // Logo
          _buildLogo(context, l10n),
          
          const Spacer(),
          
          // Navigation links (desktop only)
          if (!isSmallScreen) ...[
            _buildNavLinks(context, l10n),
            const SizedBox(width: 24),
          ],
          
          // Language toggle
          _buildLanguageToggle(context, ref, isArabic, l10n),
          const SizedBox(width: 16),
          
          // Auth buttons
          if (!isSmallScreen) ...[
            _buildLoginButton(context, l10n),
            const SizedBox(width: 12),
            _buildSignupButton(context, l10n),
          ] else ...[
            _buildMobileMenu(context, ref, l10n, isArabic),
          ],
        ],
      ),
    );
  }
  
  Widget _buildLogo(BuildContext context, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => context.go('/'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Iconsax.location5,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.appName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavLinks(BuildContext context, AppLocalizations l10n) {
    return Row(
      children: [
        _NavLink(text: l10n.home, onTap: () => context.go('/')),
        _NavLink(text: l10n.aboutUs, onTap: () => context.go('/about')),
        _NavLink(text: l10n.privacyPolicy, onTap: () => context.go('/privacy')),
        _NavLink(text: l10n.termsOfUse, onTap: () => context.go('/terms')),
      ],
    );
  }
  

  
  Widget _buildLanguageToggle(
    BuildContext context,
    WidgetRef ref,
    bool isArabic,
    AppLocalizations l10n,
  ) {
    return _IconButton(
      icon: Iconsax.translate,
      tooltip: isArabic ? l10n.english : l10n.arabic,
      onTap: () => ref.read(localeProvider.notifier).toggleLocale(),
    );
  }
  
  Widget _buildLoginButton(BuildContext context, AppLocalizations l10n) {
    return OutlinedButton(
      onPressed: () => context.go('/login'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(l10n.login),
    );
  }
  
  Widget _buildSignupButton(BuildContext context, AppLocalizations l10n) {
    return ElevatedButton(
      onPressed: () => context.go('/signup'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(l10n.signup),
    );
  }
  
  Widget _buildMobileMenu(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    bool isArabic,
  ) {
    return _IconButton(
      icon: Iconsax.menu_1,
      tooltip: 'Menu',
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) => _MobileMenuSheet(l10n: l10n),
        );
      },
    );
  }
}

/// Navigation link widget
class _NavLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  
  const _NavLink({required this.text, required this.onTap});
  
  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: _isHovered 
                  ? AppColors.primary 
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              fontWeight: _isHovered ? FontWeight.w600 : FontWeight.normal,
            ),
            child: Text(widget.text),
          ),
        ),
      ),
    );
  }
}

/// Icon button widget
class _IconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  
  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  
  @override
  State<_IconButton> createState() => _IconButtonState();
}

class _IconButtonState extends State<_IconButton> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isHovered 
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.icon,
              size: 22,
              color: _isHovered 
                  ? AppColors.primary 
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mobile menu bottom sheet
class _MobileMenuSheet extends StatelessWidget {
  final AppLocalizations l10n;
  
  const _MobileMenuSheet({required this.l10n});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          _MobileMenuItem(text: l10n.home, onTap: () {
            Navigator.pop(context);
            context.go('/');
          }),
          _MobileMenuItem(text: l10n.aboutUs, onTap: () {
            Navigator.pop(context);
            context.go('/about');
          }),
          _MobileMenuItem(text: l10n.privacyPolicy, onTap: () {
            Navigator.pop(context);
            context.go('/privacy');
          }),
          _MobileMenuItem(text: l10n.termsOfUse, onTap: () {
            Navigator.pop(context);
            context.go('/terms');
          }),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/login');
                  },
                  child: Text(l10n.login),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/signup');
                  },
                  child: Text(l10n.signup),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _MobileMenuItem extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  
  const _MobileMenuItem({required this.text, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      trailing: const Icon(Iconsax.arrow_right_3, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
