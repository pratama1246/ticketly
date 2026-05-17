import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────
// TicketlyBottomNavBar — Bottom navigation 3 tab
// Height: 64px, sticky, shadow atas ringan
// Tab: Beranda, Tiket Saya, Akun
// Aktif: biru #072AC8 | Inaktif: abu #9CA3AF
// Tidak ada background pill, badge besar, animasi berlebihan
// ─────────────────────────────────────────────

class TicketlyBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const TicketlyBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: AppShadows.bottomNavShadow,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                index: 0,
                currentIndex: currentIndex,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Beranda',
                onTap: onTap,
              ),
              _NavItem(
                index: 1,
                currentIndex: currentIndex,
                icon: Icons.confirmation_number_outlined,
                activeIcon: Icons.confirmation_number,
                label: 'Tiket Saya',
                onTap: onTap,
              ),
              _NavItem(
                index: 2,
                currentIndex: currentIndex,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Akun',
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    final color = isActive ? AppColors.bluePrimary : AppColors.textHint;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.captionStyle.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
