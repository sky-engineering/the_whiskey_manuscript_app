import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:the_whiskey_manuscript_app/src/dashboard/dashboard_shell.dart';

const _testTabs = <DashboardTabConfig>[
  DashboardTabConfig(
    label: 'Social',
    icon: Icons.groups,
    view: Center(child: Text('Social view')),
  ),
  DashboardTabConfig(
    label: 'Content',
    icon: Icons.menu_book,
    view: Center(child: Text('Content view')),
  ),
  DashboardTabConfig(
    label: 'Messages',
    icon: Icons.chat,
    view: Center(child: Text('Messages view')),
  ),
  DashboardTabConfig(
    label: 'Events',
    icon: Icons.event,
    view: Center(child: Text('Events view')),
  ),
  DashboardTabConfig(
    label: 'Profile',
    icon: Icons.person,
    view: Center(child: Text('Profile view')),
  ),
];

void main() {
  testWidgets('Dashboard navigation switches between custom tabs',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardShell(configs: _testTabs),
      ),
    );

    expect(find.text('Social view'), findsOneWidget);
    expect(find.text('Profile view'), findsNothing);

    await tester.tap(find.byIcon(Icons.person).last);
    await tester.pumpAndSettle();

    expect(find.text('Profile view'), findsOneWidget);
  });
}
