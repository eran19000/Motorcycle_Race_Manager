import 'package:flutter/foundation.dart';

class OrganizerDayGroup {
  OrganizerDayGroup({
    required this.id,
    required this.name,
    this.paidForCurrentDay = false,
  });

  final String id;
  final String name;
  final bool paidForCurrentDay;

  OrganizerDayGroup copyWith({
    String? id,
    String? name,
    bool? paidForCurrentDay,
  }) {
    return OrganizerDayGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      paidForCurrentDay: paidForCurrentDay ?? this.paidForCurrentDay,
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
      paidForCurrentDay: true,
    ),
  ];

  List<OrganizerDayGroup> get groups => List.unmodifiable(_groups);

  List<OrganizerDayGroup> get paidGroups =>
      _groups.where((g) => g.paidForCurrentDay).toList(growable: false);

  void addGroup(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    _groups.add(
      OrganizerDayGroup(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: clean,
      ),
    );
    notifyListeners();
  }

  void setPaid(String id, bool paid) {
    final index = _groups.indexWhere((g) => g.id == id);
    if (index == -1) return;
    _groups[index] = _groups[index].copyWith(paidForCurrentDay: paid);
    notifyListeners();
  }
}
