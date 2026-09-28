import 'package:flutter/material.dart';

/// Shared GlobalKeys for the guided-tour spotlight.
abstract final class OnboardingTargets {
  static final startMyDay = GlobalKey(debugLabel: 'onboarding_start_my_day');
  static final serenity = GlobalKey(debugLabel: 'onboarding_serenity');
  static final weekOverview = GlobalKey(debugLabel: 'onboarding_week');
  static final customizeFab = GlobalKey(debugLabel: 'onboarding_customize');
  static final mobileNav = GlobalKey(debugLabel: 'onboarding_mobile_nav');
  static final sidebarNav = GlobalKey(debugLabel: 'onboarding_sidebar_nav');
  static final settingsNav = GlobalKey(debugLabel: 'onboarding_settings_nav');
  static final notifications = GlobalKey(debugLabel: 'onboarding_notifications');
  static final themeToggle = GlobalKey(debugLabel: 'onboarding_theme_toggle');
  static final appearanceSection = GlobalKey(debugLabel: 'onboarding_appearance');
  static final gouvernanceTile = GlobalKey(debugLabel: 'onboarding_gouvernance_tile');
  static final accessHeader = GlobalKey(debugLabel: 'onboarding_access_header');
  static final structureChips = GlobalKey(debugLabel: 'onboarding_structure_chips');
  static final accessTabs = GlobalKey(debugLabel: 'onboarding_access_tabs');
  static final orgChart = GlobalKey(debugLabel: 'onboarding_org_chart');
  static final membersPanel = GlobalKey(debugLabel: 'onboarding_members_panel');

  static bool isWideLayout(BuildContext context) => MediaQuery.sizeOf(context).width >= 900;

  /// Main navigation target: mobile bottom bar or desktop sidebar.
  static GlobalKey navigationFor(BuildContext context) =>
      isWideLayout(context) ? sidebarNav : mobileNav;
}
