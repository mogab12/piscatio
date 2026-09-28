import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/formatters_provider.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/media/photo_source.dart';
import '../../../core/providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/action_slab.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../core/widgets/photo_thumb.dart';
import '../../../core/widgets/section_label.dart';
import '../../../data/media/photo_importer.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/geo_point.dart';
import '../../../domain/services/past_trip.dart';
import '../../common/place_search_sheet.dart';
import '../application/trip_controller.dart';

/// A trip that already happened. Photos (optional) become catches, and
/// their capture time and place fill in the trip's.
class PastTripScreen extends ConsumerStatefulWidget {
  const PastTripScreen({super.key});

  @override
  ConsumerState<PastTripScreen> createState() => _PastTripScreenState();
}

class _PastTripScreenState extends ConsumerState<PastTripScreen> {
  late DateTime _start;
  late DateTime _end;
  PrivacyLevel? _privacy;
  GeoPoint? _location;
  final _place = TextEditingController();
  final _region = TextEditingController();
  final _photos = <ImportedPhoto>[];
  var _timesTouched = false;
  var _suggested = false;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    // Yesterday morning: the most common case for logging afterwards.
    final today = ref.read(clockProvider).now().toLocal();
    final day = DateTime(today.year, today.month, today.day - 1);
    _start = day.add(const Duration(hours: 6));
    _end = day.add(const Duration(hours: 10));
  }

  @override
  void dispose() {
    _place.dispose();
    _region.dispose();
    super.dispose();
  }

  DateTime get _now => ref.read(clockProvider).now().toLocal();

  bool get _valid => _end.isAfter(_start) && !_end.isAfter(_now);

  Future<void> _addPhoto() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final origin = await showChoiceSheet<PhotoOrigin>(
      context: context,
      title: l10n.pastTripAddPhoto,
      selected: PhotoOrigin.gallery,
      choices: [
        Choice(PhotoOrigin.gallery, l10n.quickCatchGallery),
        Choice(PhotoOrigin.camera, l10n.quickCatchTakePhoto),
      ],
    );
    if (origin == null) return;
    final path = await ref.read(photoSourceProvider).pick(origin);
    if (path == null || !mounted) return;
    try {
      final imported = await ref.read(photoImporterProvider).import(path);
      if (!mounted) return;
      setState(() {
        _photos.add(imported);
        _applySuggestion();
      });
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.pastTripPhotoFailed)));
    }
  }

  /// Fills date, times and place from the photos unless the person set
  /// them already.
  void _applySuggestion() {
    final s = suggestFromPhotos([
      for (final p in _photos)
        (takenAt: p.stored.takenAt, location: p.exifLocation),
    ], now: ref.read(clockProvider).now());
    if (s == null) return;
    if (!_timesTouched) {
      _start = s.start.toLocal();
      _end = s.end.toLocal();
      _suggested = true;
    }
    if (_location == null && s.location != null) {
      _location = s.location;
      _suggested = true;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(1990),
      lastDate: _now,
    );
    if (picked == null) return;
    final shift = DateTime(
      picked.year,
      picked.month,
      picked.day,
    ).difference(DateTime(_start.year, _start.month, _start.day));
    setState(() {
      _timesTouched = true;
      _start = _start.add(shift);
      _end = _end.add(shift);
    });
  }

  Future<void> _pickTime({required bool end}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(end ? _end : _start),
    );
    if (picked == null) return;
    setState(() {
      _timesTouched = true;
      final candidate = DateTime(
        _start.year,
        _start.month,
        _start.day,
        picked.hour,
        picked.minute,
      );
      if (end) {
        // Ending earlier on the clock means the trip crossed midnight.
        _end = candidate.isAfter(_start)
            ? candidate
            : candidate.add(const Duration(days: 1));
      } else {
        final length = _end.difference(_start);
        _start = candidate;
        _end = candidate.add(length);
      }
    });
  }

  Future<void> _searchPlace() async {
    final found = await showPlaceSearch(context);
    if (found == null || !mounted) return;
    setState(() {
      _location = found.point;
      _place.text = found.name;
      if (found.region != null) _region.text = found.region!;
    });
  }

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    String? clean(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final settings = await ref.read(settingsRepositoryProvider).read();
    final trip = await ref
        .read(tripControllerProvider)
        .createPastTrip(
          startedAt: _start.toUtc(),
          endedAt: _end.toUtc(),
          privacy: _privacy ?? settings.defaultPrivacy,
          location: _location,
          locationName: clean(_place),
          locationRegion: clean(_region),
          photos: _photos,
        );
    if (mounted) context.pushReplacement(AppRoutes.trip(trip.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium!.copyWith(color: context.palette.muted);
    final privacy =
        _privacy ??
        ref.watch(settingsProvider).value?.defaultPrivacy ??
        PrivacyLevel.private;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pastTripTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SectionLabel(l10n.pastTripPhotos),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PiscatioSizes.gutter,
            ),
            child: Text(l10n.pastTripPhotosHint, style: muted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 88,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: PiscatioSizes.gutter,
              ),
              children: [
                for (final p in _photos)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: PhotoThumb(
                      relativePath: p.stored.relativePath,
                      size: 88,
                    ),
                  ),
                _AddPhotoTile(label: l10n.pastTripAddPhoto, onTap: _addPhoto),
              ],
            ),
          ),
          if (_suggested)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PiscatioSizes.gutter,
                12,
                PiscatioSizes.gutter,
                0,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 20,
                    color: context.palette.muted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.pastTripSuggested, style: muted)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          _Tile(
            icon: Icons.event_outlined,
            label: l10n.editTripDate,
            value: f.weekdayDate(_start.toUtc()),
            onTap: _pickDate,
          ),
          _Tile(
            icon: Icons.schedule_rounded,
            label: l10n.editTripStart,
            value: f.time(_start.toUtc()),
            onTap: () => _pickTime(end: false),
          ),
          _Tile(
            icon: Icons.flag_outlined,
            label: l10n.editTripEnd,
            value: f.time(_end.toUtc()),
            onTap: () => _pickTime(end: true),
          ),
          if (!_end.isAfter(_start))
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: PiscatioSizes.gutter,
              ),
              child: Text(
                l10n.editTripEndBeforeStart,
                style: text.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PiscatioSizes.gutter,
              16,
              PiscatioSizes.gutter,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                OutlinedButton.icon(
                  onPressed: _searchPlace,
                  icon: const Icon(Icons.search_rounded),
                  label: Text(l10n.placeSearchAction),
                ),
                if (_location != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 20,
                        color: context.palette.muted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(l10n.placeSearchPointSaved, style: muted),
                      ),
                    ],
                  ),
                ],
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
              ],
            ),
          ),
          const SizedBox(height: 8),
          _Tile(
            icon: Icons.lock_outline_rounded,
            label: l10n.editTripPrivacy,
            value: f.privacyLevel(privacy),
            onTap: () async {
              final picked = await showChoiceSheet<PrivacyLevel>(
                context: context,
                title: l10n.editTripPrivacy,
                selected: privacy,
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
          label: l10n.pastTripSave,
          onPressed: _valid && !_saving ? _save : null,
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PiscatioRadii.thumb),
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: scheme.surfaceContainer,
            borderRadius: BorderRadius.circular(PiscatioRadii.thumb),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_a_photo_outlined),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
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
    contentPadding: const EdgeInsets.symmetric(
      horizontal: PiscatioSizes.gutter,
    ),
    minTileHeight: PiscatioSizes.minTouch,
    leading: Icon(icon),
    title: Text(label),
    subtitle: Text(value),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}
