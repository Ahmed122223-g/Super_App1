import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jiwar_web/core/providers/auth_provider.dart';
import 'package:jiwar_web/pages/dashboard/dashboard_layout.dart';
import 'package:jiwar_web/pages/dashboard/teacher/tabs/teacher_reservations_tab.dart';
import 'package:jiwar_web/pages/dashboard/teacher/tabs/teacher_profile_tab.dart';
import 'package:jiwar_web/pages/dashboard/tabs/provider_ratings_tab.dart';
import 'package:jiwar_web/l10n/app_localizations.dart';

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    final titles = [
      l10n.reservations,
      l10n.profile,
      l10n.reviews,
    ];

    return DashboardLayout(
      title: titles[_selectedIndex],
      sidebarItems: [
        SidebarItem(
          title: l10n.reservations,
          icon: Icons.calendar_today,
          isSelected: _selectedIndex == 0,
          onTap: () => setState(() => _selectedIndex = 0),
        ),
        SidebarItem(
          title: l10n.profile,
          icon: Icons.person,
          isSelected: _selectedIndex == 1,
          onTap: () => setState(() => _selectedIndex = 1),
        ),
        SidebarItem(
          title: l10n.reviews,
          icon: Icons.star,
          isSelected: _selectedIndex == 2,
          onTap: () => setState(() => _selectedIndex = 2),
        ),
      ],
      onLogout: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.logout),
            content: Text(l10n.confirmLogout),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: Text(l10n.logout)
              ),
            ],
          ),
        );
        
        if (confirm == true) {
          // Use Secure Logout via Riverpod
          await ref.read(authProvider.notifier).logout();
        }
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    // ignore: unused_local_variable
    final l10n = AppLocalizations.of(context)!;
    switch (_selectedIndex) {
      case 0:
        return const TeacherReservationsTab();
      case 1:
        return const TeacherProfileTab();
      case 2:
        return const ProviderRatingsTab(providerType: 'teacher'); 
      default:
        return const SizedBox.shrink();
    }
  }
}
