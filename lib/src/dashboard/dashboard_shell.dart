import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({
    super.key,
    required this.configs,
  });

  final List<DashboardTabConfig> configs;

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;

  List<DashboardTabConfig> get _pageConfigs => widget.configs;
  bool get _hasTabs => _pageConfigs.isNotEmpty;

  int _clampIndex(int value) {
    if (!_hasTabs) {
      return 0;
    }
    final maxIndex = _pageConfigs.length - 1;
    return value.clamp(0, maxIndex).toInt();
  }

  void _onItemTapped(int newIndex) {
    if (!_hasTabs) return;
    final nextIndex = _clampIndex(newIndex);
    if (nextIndex == _selectedIndex) return;
    setState(() => _selectedIndex = nextIndex);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasTabs) {
      return const Scaffold(
        body: Center(child: Text('No dashboard tabs configured.')),
      );
    }

    final safeIndex = _clampIndex(_selectedIndex);
    final currentPage = _pageConfigs[safeIndex];
    final mediaQuery = MediaQuery.of(context);
    final navBarTheme = NavigationBarTheme.of(context);
    final navHeight = navBarTheme.height ?? 80.0;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          color: AppColors.neutralLight,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: mediaQuery.padding.top + 4,
            bottom: 4,
          ),
          alignment: Alignment.centerLeft,
          child: SvgPicture.asset(
            'assets/images/logo/TWM_Mark_Primary.svg',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
        ),
      ),
      body: currentPage.view,
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          final navWidth =
              constraints.maxWidth.isFinite && constraints.maxWidth > 0
                  ? constraints.maxWidth
                  : mediaQuery.size.width;
          final tabCount = _pageConfigs.length;
          const indicatorWidth = 32.0;
          final slotWidth = tabCount == 0 ? navWidth : navWidth / tabCount;
          final targetLeft = tabCount == 0
              ? (navWidth - indicatorWidth) / 2
              : (slotWidth * safeIndex) + (slotWidth - indicatorWidth) / 2;
          final safeLeft = navWidth > 0
              ? math.max(
                  0.0,
                  math.min(targetLeft, navWidth - indicatorWidth),
                )
              : 0.0;

          final navBar = NavigationBar(
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            indicatorColor: Colors.transparent,
            selectedIndex: safeIndex,
            onDestinationSelected: _onItemTapped,
            destinations: [
              for (var i = 0; i < tabCount; i++)
                NavigationDestination(
                  icon: _DashboardNavIcon(
                    iconData: _pageConfigs[i].icon,
                  ),
                  selectedIcon: _DashboardNavIcon(
                    iconData: _pageConfigs[i].icon,
                  ),
                  label: _pageConfigs[i].label,
                ),
            ],
          );

          return SizedBox(
            height: navHeight,
            child: Stack(
              children: [
                Positioned.fill(child: navBar),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  left: safeLeft,
                  bottom: 36,
                  width: indicatorWidth,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.leather,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardNavIcon extends StatelessWidget {
  const _DashboardNavIcon({
    required this.iconData,
  });

  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onSurface;
    return Icon(iconData, color: iconColor);
  }
}

class DashboardTabConfig {
  const DashboardTabConfig({
    required this.label,
    required this.icon,
    required this.view,
  });

  final String label;
  final IconData icon;
  final Widget view;
}
