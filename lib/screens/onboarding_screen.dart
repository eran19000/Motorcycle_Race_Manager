import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/racing_tracks.dart';
import '../models/app_user.dart';
import '../models/racing_track.dart';
import '../services/group_management_service.dart';
import '../services/telemetry_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.telemetryService});

  final TelemetryService telemetryService;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _bikeController = TextEditingController();
  final _lapController = TextEditingController(text: '105.000');
  final GroupManagementService _groupService = GroupManagementService.instance;
  String? _selectedManagementGroupId;
  bool _anonymous = false;
  String _result = '';
  String _gpsStatus = 'GPS not checked yet';
  bool? _gpsReady;
  RacingTrack _selectedTrack = racingTracks.first;
  bool _noSaveDetails = false;
  bool _externalGpsPreferred = false;
  final Set<String> _pricingOptions = {};

  @override
  void initState() {
    super.initState();
    _selectedTrack = widget.telemetryService.selectedTrack;
    _selectedManagementGroupId = _groupService.paidGroups.isNotEmpty
        ? _groupService.paidGroups.first.id
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _bikeController.dispose();
    _lapController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final lapSeconds = double.parse(_lapController.text.trim());
    final selectedGroupName = _groupService.groups
        .where((g) => g.id == _selectedManagementGroupId)
        .map((g) => g.name)
        .toList();
    final user = AppUser(
      userName: _nameController.text.trim(),
      emailOrPhone: _contactController.text.trim(),
      bikeModel: _bikeController.text.trim(),
      managementDayGroup: selectedGroupName.isNotEmpty
          ? selectedGroupName.first
          : 'No paid management group selected',
      anonymousInLeaderboard: _anonymous,
      typicalLapSeconds: lapSeconds,
      initialSpeedGroup: inferSpeedGroup(lapSeconds),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_rider_organizer_group', user.managementDayGroup);
    await prefs.setString('active_rider_track_id', _selectedTrack.id);
    if (!mounted) return;
    setState(() {
      _result =
          'Rider ${user.userName} assigned to ${user.initialSpeedGroup} group'
          '${user.anonymousInLeaderboard ? ' (anonymous in global boards)' : ''}'
          ' | Track: ${_selectedTrack.name}';
    });
  }

  Future<void> _checkGpsStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _gpsStatus = 'GPS service is OFF';
        _gpsReady = false;
      });
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _gpsStatus = 'Permission denied forever';
        _gpsReady = false;
      });
      return;
    }
    if (permission == LocationPermission.denied) {
      setState(() {
        _gpsStatus = 'Permission denied';
        _gpsReady = false;
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    );
    setState(() {
      _gpsStatus =
          'GPS OK | Acc: ${position.accuracy.toStringAsFixed(1)}m | '
          'Lat: ${position.latitude.toStringAsFixed(5)} | '
          'Lng: ${position.longitude.toStringAsFixed(5)}';
      _gpsReady = true;
    });
  }

  Future<void> _pickTrackFromSearch() async {
    final selected = await showModalBottomSheet<RacingTrack>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        var query = '';
        var filtered = racingTracks;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Search race track',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          query = value.trim().toLowerCase();
                          filtered = racingTracks.where((track) {
                            final haystack =
                                '${track.name} ${track.city} ${track.countryCode}'
                                    .toLowerCase();
                            return haystack.contains(query);
                          }).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 380,
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final track = filtered[index];
                          return ListTile(
                            title: Text(track.name),
                            subtitle: Text(
                              '${track.countryCode} | ${track.city} | ${track.lengthKm}km',
                            ),
                            trailing: _selectedTrack.id == track.id
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : null,
                            onTap: () => Navigator.of(context).pop(track),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected == null) return;
    setState(() => _selectedTrack = selected);
    widget.telemetryService.selectTrack(selected);
  }

  @override
  Widget build(BuildContext context) {
    final whiteFieldTheme = Theme.of(context).copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black, width: 1.5),
        ),
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF050505), Color(0xFF141414)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Theme(
          data: whiteFieldTheme,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(
              'User Onboarding',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'User Name'),
              validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
            ),
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Email or Phone',
                helperText: 'אפשר הרשמה דרך מייל או טלפון',
                helperMaxLines: 2,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
            ),
            TextFormField(
              controller: _bikeController,
              decoration: const InputDecoration(labelText: 'Bike Model'),
              validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
            ),
            AnimatedBuilder(
              animation: _groupService,
              builder: (context, _) {
                final paidGroups = _groupService.paidGroups;
                if (_selectedManagementGroupId == null && paidGroups.isNotEmpty) {
                  _selectedManagementGroupId = paidGroups.first.id;
                }
                if (_selectedManagementGroupId != null &&
                    paidGroups.every((g) => g.id != _selectedManagementGroupId)) {
                  _selectedManagementGroupId =
                      paidGroups.isNotEmpty ? paidGroups.first.id : null;
                }
                return DropdownButtonFormField<String>(
                  key: ValueKey(_selectedManagementGroupId),
                  initialValue: _selectedManagementGroupId,
                  decoration: const InputDecoration(
                    labelText: 'Track-Day Management Group (paid only)',
                  ),
                  items: paidGroups
                      .map(
                        (group) => DropdownMenuItem<String>(
                          value: group.id,
                          child: Text(group.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedManagementGroupId = value),
                  validator: (_) =>
                      paidGroups.isEmpty ? 'No paid management group available' : null,
                );
              },
            ),
            Text(
              'Race Track (IL + World circuits)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            ListTile(
              tileColor: const Color(0xFF101010),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFF22D3EE), width: 1.0),
              ),
              title: Text(
                _selectedTrack.name,
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
              ),
              subtitle: Text(
                '${_selectedTrack.countryCode} | ${_selectedTrack.city} | ${_selectedTrack.lengthKm}km',
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: const Icon(Icons.search),
              onTap: _pickTrackFromSearch,
            ),
            TextFormField(
              controller: _lapController,
              decoration: const InputDecoration(labelText: 'Typical Lap Time (seconds)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                final parsed = double.tryParse(value ?? '');
                if (parsed == null || parsed <= 0) return 'Enter valid time';
                return null;
              },
            ),
            SwitchListTile(
              title: const Text('Stay anonymous in global leaderboards'),
              value: _anonymous,
              onChanged: (value) => setState(() => _anonymous = value),
            ),
            SwitchListTile(
              title: const Text('Do not save personal details'),
              subtitle: const Text('Privacy-first session mode'),
              value: _noSaveDetails,
              onChanged: (value) => setState(() => _noSaveDetails = value),
            ),
            SwitchListTile(
              title: const Text('Prefer external GPS (Bluetooth)'),
              value: _externalGpsPreferred,
              onChanged: (value) {
                setState(() => _externalGpsPreferred = value);
                widget.telemetryService.toggleExternalGps(value);
              },
            ),
            const SizedBox(height: 8),
            Text('Pricing options', style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: 8,
              children: [
                'Live Leaderboard Access',
                'Track Map Access',
                'AI Video Analysis',
                'Advanced Telemetry Graphs',
              ].map((option) {
                final selected = _pricingOptions.contains(option);
                return FilterChip(
                  label: Text(option),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _pricingOptions.add(option);
                      } else {
                        _pricingOptions.remove(option);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            FilledButton(onPressed: _submit, child: const Text('Register Rider')),
            const SizedBox(height: 14),
            Text(_result, style: const TextStyle(color: Colors.greenAccent)),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            Text('GPS Readiness Check', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _checkGpsStatus,
              child: const Text('Check GPS Status'),
            ),
            const SizedBox(height: 6),
            Chip(
              label: Text(
                _gpsReady == null
                    ? '⏳ Status: Pending'
                    : _gpsReady!
                        ? '✅ Status: Track-Ready'
                        : '⚠️ Status: GPS Issue',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              backgroundColor: _gpsReady == null
                  ? Colors.grey.shade300
                  : _gpsReady!
                      ? Colors.green.shade300
                      : Colors.red.shade300,
              side: const BorderSide(color: Colors.black, width: 1.2),
            ),
            const SizedBox(height: 6),
            Text(
              _gpsStatus,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
