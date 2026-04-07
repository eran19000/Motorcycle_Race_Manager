import 'package:flutter/material.dart';

import '../services/group_management_service.dart';
import '../services/telemetry_service.dart';
import 'admin_screen.dart';
import 'ai_premium_screen.dart';
import 'live_dashboard_screen.dart';
import 'onboarding_screen.dart';
import 'post_session_screen.dart';

enum AppPortal { rider, manager, superAdmin }
enum AppLanguage { hebrew, english, arabic }

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final TelemetryService _telemetryService = TelemetryService();
  final GroupManagementService _groupService = GroupManagementService.instance;
  int _tabIndex = 0;
  AppPortal? _portal;
  AppLanguage _language = AppLanguage.hebrew;
  String? _managerGroupName;
  final TextEditingController _ownerPinController = TextEditingController();
  String _entryError = '';

  @override
  void dispose() {
    _ownerPinController.dispose();
    _telemetryService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String tr(String he, String en, String ar) {
      switch (_language) {
        case AppLanguage.hebrew:
          return he;
        case AppLanguage.english:
          return en;
        case AppLanguage.arabic:
          return ar;
      }
    }

    if (_portal == null) {
      return Scaffold(
        body: SafeArea(
          child: _EntrySelector(
            language: _language,
            onLanguageChanged: (value) => setState(() => _language = value),
            onEnterRider: () {
              setState(() {
                _portal = AppPortal.rider;
                _entryError = '';
              });
            },
            onEnterManager: (groupName) {
              setState(() {
                _portal = AppPortal.manager;
                _managerGroupName = groupName;
                _entryError = '';
              });
            },
            onEnterOwner: (pin) {
              if (pin == '7777') {
                setState(() {
                  _portal = AppPortal.superAdmin;
                  _entryError = '';
                });
                return;
              }
              setState(() => _entryError = tr('קוד מנהל-על שגוי', 'Invalid super-admin PIN', 'رمز المدير العام غير صحيح'));
            },
            ownerPinController: _ownerPinController,
            paidGroups: _groupService.paidGroups.map((g) => g.name).toList(),
            error: _entryError,
            tr: tr,
          ),
        ),
      );
    }

    final pages = _portal == AppPortal.rider
        ? [
            OnboardingScreen(telemetryService: _telemetryService),
            LiveDashboardScreen(telemetryService: _telemetryService),
            const PostSessionScreen(),
            const AiPremiumScreen(),
          ]
        : _portal == AppPortal.manager
            ? [
                AdminScreen(telemetryService: _telemetryService),
                const PostSessionScreen(),
              ]
            : [
                const _SuperAdminScreen(),
                AdminScreen(telemetryService: _telemetryService),
              ];
    final destinations = _portal == AppPortal.rider
        ? [
            NavigationDestination(icon: const Icon(Icons.person_add), label: tr('רישום', 'Onboard', 'التسجيل')),
            NavigationDestination(icon: const Icon(Icons.timer), label: tr('לייב', 'Live', 'مباشر')),
            NavigationDestination(icon: const Icon(Icons.history), label: tr('היסטוריה', 'History', 'السجل')),
            NavigationDestination(icon: const Icon(Icons.auto_awesome), label: tr('AI', 'AI', 'ذكاء اصطناعي')),
          ]
        : _portal == AppPortal.manager
            ? [
                NavigationDestination(icon: const Icon(Icons.shield), label: tr('ניהול', 'Manage', 'إدارة')),
                NavigationDestination(icon: const Icon(Icons.history), label: tr('היסטוריה', 'History', 'السجل')),
              ]
            : [
                NavigationDestination(icon: const Icon(Icons.workspace_premium), label: tr('בעלים', 'Owner', 'المالك')),
                NavigationDestination(icon: const Icon(Icons.shield), label: tr('מנהלים', 'Managers', 'المنظمون')),
              ];

    if (_tabIndex >= pages.length) {
      _tabIndex = 0;
    }

    final roleLabel = _portal == AppPortal.rider
        ? tr('רוכב', 'Rider', 'متسابق')
        : _portal == AppPortal.manager
            ? tr('מארגן: ${_managerGroupName ?? ''}', 'Organizer: ${_managerGroupName ?? ''}', 'منظم: ${_managerGroupName ?? ''}')
            : tr('מנהל על', 'Super Admin', 'مدير عام');

    return Scaffold(
      appBar: AppBar(
        title: Text(roleLabel),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _portal = null;
                _tabIndex = 0;
                _entryError = '';
              });
            },
            icon: const Icon(Icons.logout),
            tooltip: tr('יציאה', 'Logout', 'تسجيل الخروج'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: DropdownButtonFormField<AppLanguage>(
                value: _language,
                decoration: InputDecoration(
                  labelText: tr('שפה', 'Language', 'اللغة'),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(value: AppLanguage.hebrew, child: Text(tr('עברית', 'Hebrew', 'العبرية'))),
                  DropdownMenuItem(value: AppLanguage.english, child: const Text('English')),
                  DropdownMenuItem(value: AppLanguage.arabic, child: Text(tr('ערבית', 'Arabic', 'العربية'))),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _language = value);
                },
              ),
            ),
            Expanded(child: pages[_tabIndex]),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: destinations,
      ),
    );
  }
}

class _SuperAdminScreen extends StatelessWidget {
  const _SuperAdminScreen();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Super Admin Portal', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('Manage organizer subscriptions, track-day quotas, and platform permissions.'),
          SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.payments),
              title: Text('Organizer billing and plan control'),
              subtitle: Text('Enable/disable track-day creation by subscription tier'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.verified_user),
              title: Text('Creator-only access'),
              subtitle: Text('Reserved entry point for platform owner permissions'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntrySelector extends StatelessWidget {
  const _EntrySelector({
    required this.language,
    required this.onLanguageChanged,
    required this.onEnterRider,
    required this.onEnterManager,
    required this.onEnterOwner,
    required this.ownerPinController,
    required this.paidGroups,
    required this.error,
    required this.tr,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final VoidCallback onEnterRider;
  final ValueChanged<String> onEnterManager;
  final ValueChanged<String> onEnterOwner;
  final TextEditingController ownerPinController;
  final List<String> paidGroups;
  final String error;
  final String Function(String, String, String) tr;

  @override
  Widget build(BuildContext context) {
    String? selectedPaidGroup = paidGroups.isNotEmpty ? paidGroups.first : null;
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              tr('כניסה למערכת', 'System Entry', 'الدخول إلى النظام'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<AppLanguage>(
              value: language,
              decoration: InputDecoration(
                labelText: tr('שפה', 'Language', 'اللغة'),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: AppLanguage.hebrew, child: Text(tr('עברית', 'Hebrew', 'العبرية'))),
                const DropdownMenuItem(value: AppLanguage.english, child: Text('English')),
                DropdownMenuItem(value: AppLanguage.arabic, child: Text(tr('ערבית', 'Arabic', 'العربية'))),
              ],
              onChanged: (value) {
                if (value != null) onLanguageChanged(value);
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.sports_motorsports),
                title: Text(tr('כניסת רוכב', 'Rider Entry', 'دخول متسابق')),
                subtitle: Text(tr('רישום + לאפ טיימר + היסטוריה', 'Onboarding + lap timer + history', 'تسجيل + مؤقت لفات + سجل')),
                trailing: FilledButton(onPressed: onEnterRider, child: Text(tr('כניסה', 'Enter', 'دخول'))),
              ),
            ),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.shield),
                    title: Text(tr('כניסת מארגן יום מסלול', 'Organizer Entry', 'دخول منظم اليوم')),
                    subtitle: Text(
                      tr(
                        'רק קבוצות ששילמו ליום זה',
                        'Only paid organizer groups for this day',
                        'فقط المجموعات التي دفعت لهذا اليوم',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedPaidGroup,
                            decoration: InputDecoration(
                              labelText: tr('קבוצת מארגן', 'Organizer Group', 'مجموعة المنظم'),
                              border: const OutlineInputBorder(),
                            ),
                            items: paidGroups
                                .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                                .toList(),
                            onChanged: (value) => setLocalState(() => selectedPaidGroup = value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: selectedPaidGroup == null
                              ? null
                              : () => onEnterManager(selectedPaidGroup!),
                          child: Text(tr('כניסה', 'Enter', 'دخول')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: ownerPinController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: tr('קוד מנהל-על', 'Super Admin PIN', 'رمز المدير العام'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => onEnterOwner(ownerPinController.text.trim()),
                      child: Text(tr('כניסה', 'Enter', 'دخول')),
                    ),
                  ],
                ),
              ),
            ),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
              ),
          ],
        );
      },
    );
  }
}
