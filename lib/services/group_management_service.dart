import 'package:flutter/foundation.dart';

import '../data/racing_tracks.dart';

class OrganizerDayGroup {
  OrganizerDayGroup({
    required this.id,
    required this.name,
    required this.password,
    this.paidForCurrentDay = false,
    required this.assignedTrackId,
    required this.assignedDateIso,
  });

  final String id;
  final String name;
  final String password;
  final bool paidForCurrentDay;
  final String assignedTrackId;
  final String assignedDateIso;

  OrganizerDayGroup copyWith({
    String? id,
    String? name,
    String? password,
    bool? paidForCurrentDay,
    String? assignedTrackId,
    String? assignedDateIso,
  }) {
    return OrganizerDayGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      password: password ?? this.password,
      paidForCurrentDay: paidForCurrentDay ?? this.paidForCurrentDay,
      assignedTrackId: assignedTrackId ?? this.assignedTrackId,
      assignedDateIso: assignedDateIso ?? this.assignedDateIso,
    );
  }
}

class GroupManagementService extends ChangeNotifier {
  GroupManagementService._();
  static final GroupManagementService instance = GroupManagementService._();

  final List<OrganizerDayGroup> _groups = [
    OrganizerDayGroup(
      id: 'g1',
      name: 'Default Track Organizer',
      password: '1111',
      paidForCurrentDay: true,
      assignedTrackId: 'motor_city_beersheba',
      assignedDateIso: _todayIso(),
    ),
  ];

  List<OrganizerDayGroup> get groups => List.unmodifiable(_groups);

  List<OrganizerDayGroup> get paidGroups =>
      _groups
          .where((g) => g.paidForCurrentDay && g.assignedDateIso == _todayIso())
          .toList(growable: false);

  /// Returns the organizer group with this display name, or null if none.
  OrganizerDayGroup? organizerByName(String name) {
    for (final g in _groups) {
      if (g.name == name) return g;
    }
    return null;
  }

  void addGroup({
    required String name,
    required String password,
    required String trackId,
    required String dateIso,
  }) {
    final clean = name.trim();
    if (clean.isEmpty || password.trim().isEmpty) return;
    _groups.add(
      OrganizerDayGroup(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: clean,
        password: password.trim(),
        assignedTrackId: trackId,
        assignedDateIso: dateIso,
      ),
    );
    notifyListeners();
  }

  void removeGroup(String id) {
    _groups.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  void setPaid(String id, bool paid) {
    final index = _groups.indexWhere((g) => g.id == id);
    if (index == -1) return;
    _groups[index] = _groups[index].copyWith(paidForCurrentDay: paid);
    notifyListeners();
  }

  void updateAssignment({
    required String id,
    required String trackId,
    required String dateIso,
  }) {
    final index = _groups.indexWhere((g) => g.id == id);
    if (index == -1) return;
    _groups[index] = _groups[index].copyWith(
      assignedTrackId: trackId,
      assignedDateIso: dateIso,
    );
    notifyListeners();
  }

  bool canOrganizerEnter({
    required String groupName,
    required String password,
  }) {
    final group = _groups.cast<OrganizerDayGroup?>().firstWhere(
          (g) => g?.name == groupName,
          orElse: () => null,
        );
    if (group == null) return false;
    final paid = group.paidForCurrentDay;
    final dateValid = group.assignedDateIso == _todayIso();
    final passwordValid = group.password == password.trim();
    return paid && dateValid && passwordValid;
  }

  static String _todayIso() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String trackNameFor(String trackId) {
    return racingTracks.firstWhere(
      (t) => t.id == trackId,
      orElse: () => racingTracks.first,
    ).name;
  }
}
