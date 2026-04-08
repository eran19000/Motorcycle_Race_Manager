import 'package:flutter/material.dart';

import '../data/racing_tracks.dart';
import '../models/racing_track.dart';
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
  String? _managerAssignedTrackName;
  String? _managerAssignedDateIso;
  final TextEditingController _ownerPinController = TextEditingController();
  final TextEditingController _organizerPasswordController =
      TextEditingController();
  String _entryError = '';

  @override
  void dispose() {
    _ownerPinController.dispose();
    _organizerPasswordController.dispose();
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
              final canEnter = _groupService.canOrganizerEnter(
                groupName: groupName,
                password: _organizerPasswordController.text,
              );
              if (!canEnter) {
                setState(() {
                  _entryError = tr(
                    'כניסת מארגן נכשלה: צריך סיסמה + תשלום + תאריך של היום.',
                    'Organizer login failed: password + payment + today assignment required.',
                    'فشل دخول المنظم: يتطلب كلمة مرور + دفع + تعيين تاريخ اليوم.',
                  );
                });
                return;
              }
              final group = _groupService.organizerByName(groupName);
              final track = racingTracks.firstWhere(
                (t) => t.id == (group?.assignedTrackId ?? ''),
                orElse: () => racingTracks.first,
              );
              _telemetryService.selectTrack(track);
              setState(() {
                _portal = AppPortal.manager;
                _managerGroupName = groupName;
                _managerAssignedTrackName =
                    group != null ? _groupService.trackNameFor(group.assignedTrackId) : null;
                _managerAssignedDateIso = group?.assignedDateIso;
                _tabIndex = 0;
                _entryError = '';
              });
            },
            onEnterOwner: (pin) {
              if (pin == '777') {
                setState(() {
                  _portal = AppPortal.superAdmin;
                  _tabIndex = 0;
                  _entryError = '';
                });
                return;
              }
              setState(() => _entryError = tr('קוד אדמין שגוי', 'Invalid admin PIN', 'رمز المدير غير صحيح'));
            },
            ownerPinController: _ownerPinController,
            paidGroups: _groupService.paidGroups.map((g) => g.name).toList(),
            organizerPasswordController: _organizerPasswordController,
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
                AdminScreen(
                  telemetryService: _telemetryService,
                ),
                PostSessionScreen(
                  organizerGroupFilter: _managerGroupName,
                ),
              ]
            : [
                const _SuperAdminScreen(),
                AdminScreen(
                  telemetryService: _telemetryService,
                ),
                const PostSessionScreen(),
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
                NavigationDestination(icon: const Icon(Icons.shield), label: tr('יום המסלול', 'Track day', 'يوم الحلبة')),
                NavigationDestination(icon: const Icon(Icons.history), label: tr('היסטוריה', 'History', 'السجل')),
              ]
            : [
                NavigationDestination(icon: const Icon(Icons.workspace_premium), label: tr('מארגנים', 'Organizers', 'المنظمون')),
                NavigationDestination(icon: const Icon(Icons.shield), label: tr('רוכבים', 'Riders', 'المتسابقون')),
                NavigationDestination(icon: const Icon(Icons.history), label: tr('היסטוריה', 'History', 'السجل')),
              ];

    if (_tabIndex >= pages.length) {
      _tabIndex = 0;
    }

    final Widget appBarTitle;
    switch (_portal!) {
      case AppPortal.rider:
        appBarTitle = Text(tr('רוכב', 'Rider', 'متسابق'));
        break;
      case AppPortal.manager:
        appBarTitle = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr('מארגן: ${_managerGroupName ?? ''}', 'Organizer: ${_managerGroupName ?? ''}', 'منظم: ${_managerGroupName ?? ''}'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            if (_managerAssignedTrackName != null && _managerAssignedDateIso != null)
              Text(
                tr(
                  'מסלול: $_managerAssignedTrackName · יום: $_managerAssignedDateIso',
                  'Track: $_managerAssignedTrackName · Day: $_managerAssignedDateIso',
                  'المسار: $_managerAssignedTrackName · اليوم: $_managerAssignedDateIso',
                ),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.15),
              ),
          ],
        );
        break;
      case AppPortal.superAdmin:
        appBarTitle = Text(
          switch (_tabIndex) {
            0 => tr(
                'אדמין – מארגנים, מסלול ויום',
                'Admin – organizers, track & day',
                'مدير – المنظمون والمسار واليوم',
              ),
            1 => tr(
                'אדמין – רוכבים, מפה וזמנים',
                'Admin – riders, map & times',
                'مدير – المتسابقون والخريطة والأزمنة',
              ),
            _ => tr(
                'אדמין – היסטוריה של כולם',
                'Admin - full session history',
                'مدير – سجل الجميع',
              ),
          },
        );
        break;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        title: appBarTitle,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _portal = null;
                _tabIndex = 0;
                _entryError = '';
                _managerGroupName = null;
                _managerAssignedTrackName = null;
                _managerAssignedDateIso = null;
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
        backgroundColor: const Color(0xFFD32F2F),
        indicatorColor: const Color(0xFFFFEB3B),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
            );
          }
          return const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
          );
        }),
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: destinations
            .map(
              (d) => NavigationDestination(
                icon: IconTheme(
                  data: const IconThemeData(color: Colors.white70),
                  child: d.icon,
                ),
                selectedIcon: d.selectedIcon == null
                    ? IconTheme(
                        data: const IconThemeData(color: Colors.black),
                        child: d.icon,
                      )
                    : IconTheme(
                        data: const IconThemeData(color: Colors.black),
                        child: d.selectedIcon!,
                      ),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SuperAdminScreen extends StatelessWidget {
  const _SuperAdminScreen();

  @override
  Widget build(BuildContext context) {
    return const _OrganizerAdminPanel();
  }
}

class _OrganizerAdminPanel extends StatefulWidget {
  const _OrganizerAdminPanel();

  @override
  State<_OrganizerAdminPanel> createState() => _OrganizerAdminPanelState();
}

class _OrganizerAdminPanelState extends State<_OrganizerAdminPanel> {
  final GroupManagementService _groupService = GroupManagementService.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  RacingTrack _track = racingTracks.first;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _groupService,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Super Admin Portal (Organizers Only)',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Only super admin can add/remove organizers, set paid status, and assign track + date.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration:
                  const InputDecoration(labelText: 'New organizer group name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Organizer password'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<RacingTrack>(
              value: _track,
              decoration: const InputDecoration(labelText: 'Assigned paid track'),
              items: racingTracks
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (value) => setState(() => _track = value ?? _track),
            ),
            const SizedBox(height: 8),
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.black),
              ),
              title: const Text('Assigned paid date'),
              subtitle: Text(
                '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(const Duration(days: 2)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDate: _date,
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                _groupService.addGroup(
                  name: _nameController.text,
                  password: _passwordController.text,
                  trackId: _track.id,
                  dateIso:
                      '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                );
                _nameController.clear();
                _passwordController.clear();
              },
              child: const Text('Add organizer'),
            ),
            const SizedBox(height: 10),
            ..._groupService.groups.map(
              (group) => Card(
                child: ListTile(
                  title: Text(group.name),
                  subtitle: Text(
                    'Track: ${_groupService.trackNameFor(group.assignedTrackId)} | '
                    'Date: ${group.assignedDateIso} | '
                    '${group.paidForCurrentDay ? 'Paid' : 'Not paid'}',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      Switch(
                        value: group.paidForCurrentDay,
                        onChanged: (value) =>
                            _groupService.setPaid(group.id, value),
                      ),
                      IconButton(
                        onPressed: () => _groupService.removeGroup(group.id),
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
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
    required this.organizerPasswordController,
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
  final TextEditingController organizerPasswordController;
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
                        'לאחר כניסה: ישר ליום ולמסלול שלך בלבד — קבוצות, מפה וזמנים.',
                        'After login: straight to your paid track day — groups, map, and lap data.',
                        'بعد الدخول: مباشرة إلى يومك ومسارك — المجموعات والخريطة والأزمنة.',
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
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: organizerPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: tr('סיסמה', 'Password', 'كلمة المرور'),
                            ),
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
                          labelText: tr('קוד אדמין (777)', 'Admin PIN (777)', 'رمز المدير (777)'),
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
