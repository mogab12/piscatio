import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/formatters_provider.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/action_slab.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/geo_point.dart';
import '../../../domain/models/trip.dart';
import '../../common/place_search_sheet.dart';
import '../../trip/application/trip_controller.dart';

class EditTripScreen extends ConsumerWidget {
  const EditTripScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(tripProvider(tripId)).value;
    if (trip == null) return const Scaffold();
    return _EditTripForm(key: ValueKey(trip.id), trip: trip);
  }
}

class _EditTripForm extends ConsumerStatefulWidget {
  const _EditTripForm({super.key, required this.trip});

  final Trip trip;

  @override
  ConsumerState<_EditTripForm> createState() => _EditTripFormState();
}

class _EditTripFormState extends ConsumerState<_EditTripForm> {
  late DateTime _start = widget.trip.startedAt.toLocal();
  late DateTime? _end = widget.trip.endedAt?.toLocal();
  late PrivacyLevel _privacy = widget.trip.privacyLevel;
  late final _place = TextEditingController(text: widget.trip.locationName);
  late final _region = TextEditingController(text: widget.trip.locationRegion);
  late final _notes = TextEditingController(text: widget.trip.notes);
  late GeoPoint? _location = widget.trip.location;
  var _saving = false;

  @override
  void dispose() {
    _place.dispose();
    _region.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _valid => _end == null || _end!.isAfter(_start);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(1990),
      lastDate: ref.read(clockProvider).now().toLocal(),
    );
    if (picked == null) return;
    final shift = DateTime(
      picked.year,
      picked.month,
      picked.day,
    ).difference(DateTime(_start.year, _start.month, _start.day));
    setState(() {
      _start = _start.add(shift);
      _end = _end?.add(shift);
    });
  }

  Future<void> _pickTime({required bool end}) async {
    final base = end ? _end! : _start;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (picked == null) return;
    setState(() {
      if (end) {
        var candidate = DateTime(
          _start.year,
          _start.month,
          _start.day,
          picked.hour,
          picked.minute,
        );
        // Ending earlier on the clock means the trip crossed midnight.
        if (!candidate.isAfter(_start)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        _end = candidate;
      } else {
        _start = DateTime(
          _start.year,
          _start.month,
          _start.day,
          picked.hour,
          picked.minute,
        );
      }
    });
  }

  Future<void> _searchPlace() async {
    final found = await showPlaceSearch(context);
    if (found == null || !mounted) return;
    setState(() {
      _location = found.point;
      _place.text = found.name;
      _region.text = found.region ?? '';
    });
  }

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    String? clean(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    await ref
        .read(tripControllerProvider)
        .updateTrip(
          widget.trip.copyWith(
            startedAt: _start.toUtc(),
            endedAt: _end?.toUtc(),
            location: _location,
            locationName: clean(_place),
            locationRegion: clean(_region),
            privacyLevel: _privacy,
            notes: clean(_notes),
          ),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.editTripTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          PiscatioSizes.gutter,
          8,
          PiscatioSizes.gutter,
          24,
        ),
        children: [
          _PickerTile(
            icon: Icons.event_outlined,
            label: l10n.editTripDate,
            value: f.weekdayDate(_start.toUtc()),
            onTap: _pickDate,
          ),
          _PickerTile(
            icon: Icons.schedule_rounded,
            label: l10n.editTripStart,
            value: f.time(_start.toUtc()),
            onTap: () => _pickTime(end: false),
          ),
          if (_end != null)
            _PickerTile(
              icon: Icons.flag_outlined,
              label: l10n.editTripEnd,
              value: f.time(_end!.toUtc()),
              onTap: () => _pickTime(end: true),
            ),
          if (!_valid)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.editTripEndBeforeStart,
                style: text.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _place,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.editTripPlace,
              helperText: l10n.editTripPlaceHelp,
              helperMaxLines: 2,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _searchPlace,
              icon: const Icon(Icons.search_rounded),
              label: Text(l10n.placeSearchAction),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _region,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.editTripRegion,
              helperText: l10n.editTripRegionHelp,
              helperMaxLines: 2,
            ),
          ),
          const SizedBox(height: 8),
          _PickerTile(
            icon: Icons.lock_outline_rounded,
            label: l10n.editTripPrivacy,
            value: f.privacyLevel(_privacy),
            onTap: () async {
              final picked = await showChoiceSheet<PrivacyLevel>(
                context: context,
                title: l10n.editTripPrivacy,
                selected: _privacy,
                choices: [
                  for (final p in PrivacyLevel.values)
                    Choice(
                      p,
                      f.privacyLevel(p),
                      description: f.privacyDescription(p),
                    ),
                ],
              );
              if (picked != null) setState(() => _privacy = picked);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notes,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.catchNotes),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          PiscatioSizes.gutter,
          8,
          PiscatioSizes.gutter,
          16,
        ),
        child: ActionSlab(
          label: l10n.actionSave,
          onPressed: _valid && !_saving ? _save : null,
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(label),
    subtitle: Text(value),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}
