import 'package:flutter/material.dart';

import '../data/racing_tracks.dart';
import '../models/racing_track.dart';
import '../services/group_management_service.dart';
import '../services/telemetry_service.dart';
import '../theme/race_input_theme.dart';
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
    final media = MediaQuery.of(context);
    final isLandscape = media.size.width > media.size.height;

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
            AiPremiumScreen(telemetryService: _telemetryService),
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
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF22D3EE),
              ),
            ),
            if (_managerAssignedTrackName != null && _managerAssignedDateIso != null)
              Text(
                tr(
                  'מסלול: $_managerAssignedTrackName · יום: $_managerAssignedDateIso',
                  'Track: $_managerAssignedTrackName · Day: $_managerAssignedDateIso',
                  'المسار: $_managerAssignedTrackName · اليوم: $_managerAssignedDateIso',
                ),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  height: 1.15,
                ),
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
        toolbarHeight: isLandscape ? 44 : kToolbarHeight,
        backgroundColor: const Color(0xFF000000),
        foregroundColor: const Color(0xFF22D3EE),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: appBarTitle,
        titleTextStyle: TextStyle(
          color: const Color(0xFF22D3EE),
          fontWeight: FontWeight.w900,
          fontSize: isLandscape ? 16 : 19,
          shadows: const [
            Shadow(color: Color(0xAA22D3EE), blurRadius: 12),
          ],
        ),
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
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: DropdownButtonFormField<AppLanguage>(
                key: ValueKey(_language),
                initialValue: _language,
                style: RaceInputTheme.dropdownStyle,
                dropdownColor: RaceInputTheme.fieldFill,
                decoration: RaceInputTheme.neonDecoration(tr('שפה', 'Language', 'اللغة')),
                items: [
                  DropdownMenuItem(
                    value: AppLanguage.hebrew,
                    child: Text(tr('עברית', 'Hebrew', 'العبرية'), style: RaceInputTheme.typingStyle),
                  ),
                  const DropdownMenuItem(
                    value: AppLanguage.english,
                    child: Text('English', style: RaceInputTheme.typingStyle),
                  ),
                  DropdownMenuItem(
                    value: AppLanguage.arabic,
                    child: Text(tr('ערבית', 'Arabic', 'العربية'), style: RaceInputTheme.typingStyle),
                  ),
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
        height: isLandscape ? 56 : 72,
        backgroundColor: const Color(0xFF000000),
        indicatorColor: const Color(0x3322D3EE),
        labelBehavior: isLandscape
            ? NavigationDestinationLabelBehavior.alwaysHide
            : NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Color(0xFF22D3EE),
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
                        data: const IconThemeData(color: Color(0xFF22D3EE)),
                        child: d.icon,
                      )
                    : IconTheme(
                        data: const IconThemeData(color: Color(0xFF22D3EE)),
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
              style: RaceInputTheme.typingStyle,
              decoration: const InputDecoration(hintText: 'New organizer group name'),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _passwordController,
              style: RaceInputTheme.typingStyle,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Organizer password'),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<RacingTrack>(
              key: ValueKey(_track),
              initialValue: _track,
              style: RaceInputTheme.dropdownStyle,
              dropdownColor: RaceInputTheme.fieldFill,
              decoration: const InputDecoration(hintText: 'Assigned paid track'),
              items: racingTracks
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.name, style: RaceInputTheme.typingStyle),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _track = value ?? _track),
            ),
            const SizedBox(height: 18),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final landscape = constraints.maxWidth > constraints.maxHeight;
        final neonBorder = Border.all(color: const Color(0xFF22D3EE), width: 1.2);

        Widget riderPanel = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(22),
            border: neonBorder,
            boxShadow: const [BoxShadow(color: Color(0x5522D3EE), blurRadius: 16)],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.sports_motorsports, color: Color(0xFF22D3EE), size: 52),
                const SizedBox(height: 12),
                _neonFieldHint(tr('הזן אימייל', 'Enter Email', 'ادخل البريد')),
                const SizedBox(height: 18),
                _neonFieldHint(tr('הזן סיסמה', 'Enter Password', 'ادخل كلمة المرور')),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE6EEF0),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: onEnterRider,
                  child: Text(tr('כניסה', 'LOG IN', 'دخول')),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('שכחת סיסמה?', 'Forgot Password?', 'نسيت كلمة المرور؟'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );

        Widget organizerPanel = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(22),
            border: neonBorder,
            boxShadow: const [BoxShadow(color: Color(0x5522D3EE), blurRadius: 16)],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.account_circle_rounded, color: Color(0xFF22D3EE), size: 64),
                const SizedBox(height: 8),
                Text(
                  tr('כניסת מארגן יום מסלול', 'Track-Day Organizer', 'دخول منظم يوم الحلبة'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
                ),
                const SizedBox(height: 8),
                _OrganizerLoginForm(
                  tr: tr,
                  paidGroups: paidGroups,
                  organizerPasswordController: organizerPasswordController,
                  onEnterManager: onEnterManager,
                ),
                const SizedBox(height: 10),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8AF7FF).withValues(alpha: 0.7),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => onEnterOwner(ownerPinController.text.trim()),
                  child: Text(tr('כניסת אדמין', 'Admin Login', 'دخول المدير')),
                ),
              ],
            ),
          ),
        );

        return Container(
          color: Colors.black,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (constraints.maxWidth < 520) ...[
                Text(
                  tr('כניסה למערכת', 'System Entry', 'الدخول للنظام'),
                  style: TextStyle(
                    fontSize: (constraints.maxWidth * 0.09).clamp(24.0, 40.0),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 170,
                    child: DropdownButtonFormField<AppLanguage>(
                      key: ValueKey(language),
                      initialValue: language,
                      dropdownColor: RaceInputTheme.fieldFill,
                      style: RaceInputTheme.dropdownStyle,
                      decoration: _neonDecoration(tr('שפה', 'Language', 'اللغة')),
                      items: [
                        DropdownMenuItem(
                          value: AppLanguage.hebrew,
                          child: Text(tr('עברית', 'Hebrew', 'العبرية'), style: RaceInputTheme.typingStyle),
                        ),
                        const DropdownMenuItem(
                          value: AppLanguage.english,
                          child: Text('English', style: RaceInputTheme.typingStyle),
                        ),
                        DropdownMenuItem(
                          value: AppLanguage.arabic,
                          child: Text(tr('ערבית', 'Arabic', 'العربية'), style: RaceInputTheme.typingStyle),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) onLanguageChanged(value);
                      },
                    ),
                  ),
                ),
              ] else
                Row(
                  children: [
                    Text(
                      tr('כניסה למערכת', 'System Entry', 'الدخول للنظام'),
                      style: TextStyle(
                        fontSize: (constraints.maxWidth * 0.09).clamp(24.0, 46.0),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 170,
                      child: DropdownButtonFormField<AppLanguage>(
                        key: ValueKey(language),
                        initialValue: language,
                        dropdownColor: RaceInputTheme.fieldFill,
                        style: RaceInputTheme.dropdownStyle,
                        decoration: _neonDecoration(tr('שפה', 'Language', 'اللغة')),
                        items: [
                          DropdownMenuItem(
                            value: AppLanguage.hebrew,
                            child: Text(tr('עברית', 'Hebrew', 'العبرية'), style: RaceInputTheme.typingStyle),
                          ),
                          const DropdownMenuItem(
                            value: AppLanguage.english,
                            child: Text('English', style: RaceInputTheme.typingStyle),
                          ),
                          DropdownMenuItem(
                            value: AppLanguage.arabic,
                            child: Text(tr('ערבית', 'Arabic', 'العربية'), style: RaceInputTheme.typingStyle),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) onLanguageChanged(value);
                        },
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              Expanded(
                child: landscape
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: riderPanel),
                          const SizedBox(width: 14),
                          Expanded(child: organizerPanel),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(child: riderPanel),
                          const SizedBox(height: 14),
                          Expanded(child: organizerPanel),
                        ],
                      ),
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    error,
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static InputDecoration _neonDecoration(String hint) => RaceInputTheme.neonDecoration(hint);

  Widget _neonFieldHint(String hint) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: RaceInputTheme.fieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RaceInputTheme.neon, width: 1.2),
        boxShadow: const [BoxShadow(color: Color(0x5522D3EE), blurRadius: 10)],
      ),
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        hint,
        maxLines: 4,
        softWrap: true,
        style: RaceInputTheme.hintStyle,
      ),
    );
  }
}

class _OrganizerLoginForm extends StatefulWidget {
  const _OrganizerLoginForm({
    required this.tr,
    required this.paidGroups,
    required this.organizerPasswordController,
    required this.onEnterManager,
  });

  final String Function(String, String, String) tr;
  final List<String> paidGroups;
  final TextEditingController organizerPasswordController;
  final ValueChanged<String> onEnterManager;

  @override
  State<_OrganizerLoginForm> createState() => _OrganizerLoginFormState();
}

class _OrganizerLoginFormState extends State<_OrganizerLoginForm> {
  String? _selectedPaidGroup;

  @override
  void initState() {
    super.initState();
    if (widget.paidGroups.isNotEmpty) {
      _selectedPaidGroup = widget.paidGroups.first;
    }
  }

  @override
  void didUpdateWidget(covariant _OrganizerLoginForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedPaidGroup != null &&
        !widget.paidGroups.contains(_selectedPaidGroup)) {
      _selectedPaidGroup =
          widget.paidGroups.isNotEmpty ? widget.paidGroups.first : null;
    }
    if (_selectedPaidGroup == null && widget.paidGroups.isNotEmpty) {
      _selectedPaidGroup = widget.paidGroups.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final groupDropdown = DropdownButtonFormField<String>(
          key: ValueKey(_selectedPaidGroup),
          initialValue: _selectedPaidGroup,
          isExpanded: true,
          dropdownColor: RaceInputTheme.fieldFill,
          style: RaceInputTheme.dropdownStyle,
          decoration: _EntrySelector._neonDecoration(
            widget.tr('קבוצת מארגן', 'Organizer Group', 'مجموعة المنظم'),
          ),
          items: widget.paidGroups
              .map(
                (name) => DropdownMenuItem(
                  value: name,
                  child: Text(name, style: RaceInputTheme.typingStyle),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedPaidGroup = value),
        );
        final passwordField = TextField(
          controller: widget.organizerPasswordController,
          obscureText: true,
          style: RaceInputTheme.typingStyle,
          decoration: _EntrySelector._neonDecoration(
            widget.tr('סיסמה', 'Password', 'كلمة المرور'),
          ),
        );
        final enterButton = FilledButton(
          onPressed: _selectedPaidGroup == null
              ? null
              : () => widget.onEnterManager(_selectedPaidGroup!),
          child: Text(widget.tr('כניסה', 'LOG IN', 'دخول')),
        );
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              groupDropdown,
              const SizedBox(height: 20),
              passwordField,
              const SizedBox(height: 16),
              Align(alignment: AlignmentDirectional.centerEnd, child: enterButton),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: groupDropdown),
            const SizedBox(width: 12),
            SizedBox(width: 180, child: passwordField),
            const SizedBox(width: 12),
            enterButton,
          ],
        );
      },
    );
  }
}
