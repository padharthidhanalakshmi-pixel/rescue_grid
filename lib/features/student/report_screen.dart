import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/campus_location.dart';
import '../../models/enums.dart';
import '../../services/incident_service.dart';
import '../../services/location_service.dart';
import '../../services/photo_service.dart';
import '../../widgets/common.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.onSubmitted});
  final void Function(String incidentId) onSubmitted;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _location = LocationService();
  final _photos = PhotoService();
  final _desc = TextEditingController();

  IncidentCategory? _category;
  GeoReading? _gps;
  String? _gpsError;
  bool _locating = false;
  String? _campusLocationId;
  String? _photoPath;
  int _people = 1;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Request location automatically when the report screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureGps());
  }

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }

  Future<void> _captureGps() async {
    setState(() {
      _locating = true;
      _gpsError = null;
    });
    final r = await _location.current();
    if (!mounted) return;
    setState(() {
      _locating = false;
      _gps = r.reading;
      _gpsError = r.error;
    });
  }

  Future<void> _pickPhoto(bool camera) async {
    final r = await _photos.pick(camera: camera);
    if (!mounted) return;
    if (r.path != null) {
      setState(() => _photoPath = r.path);
    } else if (r.error != null) {
      showMsg(context, r.error!);
    }
  }

  void _submit() {
    final store = context.read<RescueStore>();
    if (_category == null) {
      showMsg(context, 'Select an emergency category.', color: RgColors.redDeep);
      return;
    }
    final loc = _campusLocationId == null ? null : store.locationById(_campusLocationId!);
    if (loc == null) {
      showMsg(context, 'Select where on campus this is happening.', color: RgColors.redDeep);
      return;
    }
    setState(() => _submitting = true);
    final inc = store.reportIncident(
      reporter: store.currentUser!,
      category: _category!,
      description: _desc.text,
      peopleAffected: _people,
      location: loc,
      gps: _gps,
      photoPath: _photoPath,
    );
    setState(() {
      _submitting = false;
      _category = null;
      _photoPath = null;
      _desc.clear();
      _people = 1;
    });
    widget.onSubmitted(inc.id);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RescueStore>();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
      const Text('LBRCE EMERGENCY REPORT',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: RgColors.red)),
      const SizedBox(height: 4),
      const Text('Only the category and campus location are required. Every second counts.',
          style: TextStyle(color: RgColors.muted, fontSize: 12.5)),
      const SectionTitle('1 · Emergency category'),
      GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.82,
        children: [
          for (final c in IncidentCategory.values)
            Panel(
              padding: const EdgeInsets.all(6),
              color: _category == c ? RgColors.red.withValues(alpha: 0.22) : RgColors.panel,
              border: _category == c ? RgColors.red : null,
              onTap: () => setState(() => _category = c),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(c.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 6),
                Text(c.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, height: 1.1)),
              ]),
            ),
        ],
      ),
      const SectionTitle('2 · Location'),
      Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('📍 Current Location', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (_locating)
            const Row(children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Text('Acquiring GPS…'),
            ])
          else if (_gps != null) ...[
            Text('Latitude:  ${_gps!.latitude.toStringAsFixed(6)}', style: AppTheme.mono),
            Text('Longitude: ${_gps!.longitude.toStringAsFixed(6)}', style: AppTheme.mono),
            Text('Accuracy:  ±${_gps!.accuracy.round()} m', style: AppTheme.mono.copyWith(color: RgColors.muted)),
          ] else ...[
            Text(_gpsError ?? 'Location unavailable.', style: const TextStyle(color: RgColors.amber)),
            const Text('You can continue using DEMO MODE — pick the campus location below.',
                style: TextStyle(color: RgColors.muted, fontSize: 12.5)),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _locating ? null : _captureGps,
            icon: const Icon(Icons.my_location),
            label: const Text('USE CURRENT LOCATION'),
          ),
          const SizedBox(height: 12),
          const Text('Where on campus?', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final l in store.locations)
              ChoiceChip(
                label: Text(l.name),
                selected: _campusLocationId == l.id,
                onSelected: (_) => setState(() => _campusLocationId = l.id),
              ),
          ]),
        ]),
      ),
      const SectionTitle('3 · Photo (optional)'),
      Panel(
        child: Column(children: [
          if (_photoPath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(File(_photoPath!), height: 170, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 10),
          ],
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickPhoto(true),
                icon: const Icon(Icons.photo_camera),
                label: const Text('TAKE PHOTO'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickPhoto(false),
                icon: const Icon(Icons.photo_library),
                label: const Text('GALLERY'),
              ),
            ),
          ]),
        ]),
      ),
      const SectionTitle('4 · Description (optional)'),
      TextField(
        controller: _desc,
        maxLines: 3,
        maxLength: 500,
        decoration: const InputDecoration(hintText: 'e.g. Student feeling unconscious near CSE Department'),
      ),
      const SectionTitle('5 · People affected'),
      SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 1, label: Text('1')),
          ButtonSegment(value: 2, label: Text('2')),
          ButtonSegment(value: 3, label: Text('3')),
          ButtonSegment(value: 4, label: Text('4')),
          ButtonSegment(value: 5, label: Text('5+')),
        ],
        selected: {_people},
        showSelectedIcon: false,
        onSelectionChanged: (s) => setState(() => _people = s.first),
      ),
      const SizedBox(height: 24),
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: RgColors.red,
          minimumSize: const Size.fromHeight(62),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: _submitting ? null : _submit,
        child: const Text('🚨  REPORT EMERGENCY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      ),
    ]);
  }
}
