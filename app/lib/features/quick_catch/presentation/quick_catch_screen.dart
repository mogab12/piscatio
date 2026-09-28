import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/l10n.dart';
import '../../../core/media/photo_source.dart';
import '../../../core/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/action_slab.dart';
import '../../../data/media/photo_importer.dart';
import '../../../domain/models/catch.dart';
import '../../../domain/services/catch_time.dart';
import '../../common/catch_details_form.dart';
import '../../common/species_label.dart';
import '../../common/species_picker.dart';

enum _Step { photo, species, confirm }

/// Photo → species → save. The main button stays in the same place on
/// every step, so the thumb never moves: "+ Catch", "Take photo", "Save".
/// Everything optional lives in the collapsed "More details" area.
class QuickCatchScreen extends ConsumerStatefulWidget {
  const QuickCatchScreen({super.key, required this.tripId, this.photoPath});

  final String tripId;

  /// A photo recovered after Android killed the app during the capture:
  /// the flow resumes at the species step.
  final String? photoPath;

  @override
  ConsumerState<QuickCatchScreen> createState() => _QuickCatchScreenState();
}

class _QuickCatchScreenState extends ConsumerState<QuickCatchScreen> {
  var _step = _Step.photo;

  /// Original file picked (shown immediately while it is processed).
  String? _pickedPath;
  Future<ImportedPhoto?>? _import;
  SpeciesChoice? _species;
  var _details = const CatchDetails();
  var _detailsValid = true;
  var _saving = false;
  var _saved = false;

  /// Leaving without saving: drop the imported copy of the photo.
  void _cancel() {
    final pending = _import;
    if (!_saved && pending != null) {
      final importer = ref.read(photoImporterProvider);
      unawaited(
        pending.then((p) async {
          if (p != null) await importer.discard(p.stored);
        }),
      );
    }
    context.pop();
  }

  @override
  void initState() {
    super.initState();
    final recovered = widget.photoPath;
    if (recovered != null) _usePhoto(recovered);
  }

  Future<void> _pick(PhotoOrigin origin) async {
    final path = await ref.read(photoSourceProvider).pick(origin);
    if (path == null || !mounted) return;
    _usePhoto(path);
  }

  void _usePhoto(String path) {
    final importer = ref.read(photoImporterProvider);
    setState(() {
      _pickedPath = path;
      _import = importer
          .import(path)
          .then<ImportedPhoto?>((p) => p, onError: (Object _) => null);
      _step = _Step.species;
    });
  }

  void _skipPhoto() => setState(() => _step = _Step.species);

  void _pickSpecies(SpeciesChoice choice) => setState(() {
    _species = choice;
    _step = _Step.confirm;
  });

  Future<void> _save() async {
    if (_saving || !_detailsValid) return;
    setState(() => _saving = true);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final imported = await _import;
    if (_import != null && imported == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.photoImportFailed)));
    }
    final catches = ref.read(catchRepositoryProvider);
    final speciesId = _species?.speciesId;
    final trip = await ref.read(tripRepositoryProvider).getTrip(widget.tripId);
    final now = ref.read(clockProvider).now();
    final saved = await catches.addCatch(
      tripId: widget.tripId,
      speciesId: speciesId,
      photo: imported?.stored,
      caughtAt: trip == null
          ? now
          : defaultCatchTime(
              trip: trip,
              now: now,
              photoTakenAt: imported?.stored.takenAt,
            ),
    );
    if (_details != const CatchDetails()) {
      await catches.updateDetails(
        saved.id,
        _details.copyWith(speciesId: speciesId),
      );
    }
    _saved = true;
    if (mounted) context.pop(saved.id);
  }

  void _back() {
    switch (_step) {
      case _Step.photo:
        _cancel();
      case _Step.species:
        setState(() => _step = _Step.photo);
      case _Step.confirm:
        setState(() => _step = _Step.species);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: l10n.actionCancel,
            icon: const Icon(Icons.close_rounded, size: 28),
            onPressed: _cancel,
          ),
          title: Text(l10n.quickCatchTitle),
        ),
        body: switch (_step) {
          _Step.photo => _PhotoStep(
            onCamera: () => _pick(PhotoOrigin.camera),
            onGallery: () => _pick(PhotoOrigin.gallery),
            onSkip: _skipPhoto,
          ),
          _Step.species => SpeciesPicker(
            onPicked: _pickSpecies,
            header: _SpeciesHeader(photoPath: _pickedPath),
          ),
          _Step.confirm => _ConfirmStep(
            photoPath: _pickedPath,
            species: _species!,
            details: _details,
            onChangeSpecies: () => setState(() => _step = _Step.species),
            onDetails: (d, valid) => setState(() {
              _details = d;
              _detailsValid = valid;
            }),
          ),
        },
        bottomNavigationBar: switch (_step) {
          _Step.photo => _BottomSlab(
            child: ActionSlab(
              label: l10n.quickCatchTakePhoto,
              icon: Icons.photo_camera_rounded,
              onPressed: () => _pick(PhotoOrigin.camera),
            ),
          ),
          _Step.species => null,
          _Step.confirm => _BottomSlab(
            child: ActionSlab(
              label: l10n.quickCatchSave,
              onPressed: _saving || !_detailsValid ? null : _save,
            ),
          ),
        },
      ),
    );
  }
}

class _BottomSlab extends StatelessWidget {
  const _BottomSlab({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.fromLTRB(
      PiscatioSizes.gutter,
      8,
      PiscatioSizes.gutter,
      16,
    ),
    child: child,
  );
}

class _PhotoStep extends StatelessWidget {
  const _PhotoStep({
    required this.onCamera,
    required this.onGallery,
    required this.onSkip,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    // The camera area takes whatever height is left, so the gallery and
    // no-photo buttons are always visible without scrolling.
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              PiscatioSizes.gutter,
              8,
              PiscatioSizes.gutter,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.quickCatchPhotoTitle, style: text.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  l10n.quickCatchPhotoHint,
                  style: text.bodyLarge!.copyWith(color: context.palette.muted),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 120),
                    child: Semantics(
                      button: true,
                      label: l10n.quickCatchTakePhoto,
                      excludeSemantics: true,
                      child: Material(
                        color: scheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(PiscatioRadii.slab),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: onCamera,
                          child: Center(
                            child: Icon(
                              Icons.photo_camera_outlined,
                              size: 72,
                              color: context.palette.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onGallery,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(l10n.quickCatchGallery),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onSkip,
                        icon: const Icon(Icons.no_photography_outlined),
                        label: Text(l10n.quickCatchNoPhoto),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SpeciesHeader extends StatelessWidget {
  const _SpeciesHeader({required this.photoPath});

  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PiscatioSizes.gutter,
        4,
        PiscatioSizes.gutter,
        8,
      ),
      child: Row(
        children: [
          if (photoPath != null) ...[
            _LocalPhoto(path: photoPath!, size: 72),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Text(
              context.l10n.quickCatchSpeciesTitle,
              style: text.headlineMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmStep extends ConsumerWidget {
  const _ConfirmStep({
    required this.photoPath,
    required this.species,
    required this.details,
    required this.onChangeSpecies,
    required this.onDetails,
  });

  final String? photoPath;
  final SpeciesChoice species;
  final CatchDetails details;
  final VoidCallback onChangeSpecies;
  final void Function(CatchDetails, bool) onDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final id = species.speciesId;
    final name = ref.watch(speciesNameProvider(id)) ?? l10n.speciesUnknown;
    final scientific = scientificNameOf(
      id == null ? null : ref.watch(speciesByIdProvider)[id],
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PiscatioSizes.gutter,
        4,
        PiscatioSizes.gutter,
        24,
      ),
      children: [
        if (photoPath != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(PiscatioRadii.slab),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.file(
                File(photoPath!),
                fit: BoxFit.cover,
                cacheWidth: 1200,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: text.headlineMedium),
                  if (scientific != null)
                    Text(
                      scientific,
                      style: text.bodyLarge!.copyWith(
                        fontStyle: FontStyle.italic,
                        color: context.palette.muted,
                      ),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: onChangeSpecies,
              child: Text(l10n.quickCatchChangeSpecies),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            leading: const Icon(Icons.straighten_rounded),
            title: Text(l10n.quickCatchMoreDetails, style: text.titleMedium),
            subtitle: Text(
              l10n.quickCatchMoreDetailsHint,
              style: text.bodyMedium!.copyWith(color: context.palette.muted),
            ),
            children: [
              CatchDetailsForm(initial: details, onChanged: onDetails),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocalPhoto extends StatelessWidget {
  const _LocalPhoto({required this.path, required this.size});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(PiscatioRadii.thumb),
      child: SizedBox.square(
        dimension: size,
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          cacheWidth: (size * 3).round(),
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
