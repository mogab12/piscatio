import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatting/formatters_provider.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/media/photo_source.dart';
import '../../../core/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/action_slab.dart';
import '../../../core/widgets/choice_sheet.dart';
import '../../../core/widgets/photo_thumb.dart';
import '../../../data/media/photo_importer.dart';
import '../../../domain/models/catch.dart';
import '../../common/catch_details_form.dart';
import '../../common/confirm_delete.dart';
import '../../common/species_label.dart';
import '../../common/species_picker.dart';

/// View and edit one catch: photo, species, time and every optional field.
class CatchDetailScreen extends ConsumerWidget {
  const CatchDetailScreen({super.key, required this.catchId});

  final String catchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(catchProvider(catchId));
    return item.when(
      loading: () => const Scaffold(),
      error: (_, _) =>
          Scaffold(body: Center(child: Text(context.l10n.errorGeneric))),
      data: (item) => item == null
          ? Scaffold(
              appBar: AppBar(),
              body: Center(child: Text(context.l10n.catchNotFound)),
            )
          : _CatchEditor(key: ValueKey(item.id), item: item),
    );
  }
}

class _CatchEditor extends ConsumerStatefulWidget {
  const _CatchEditor({super.key, required this.item});

  final Catch item;

  @override
  ConsumerState<_CatchEditor> createState() => _CatchEditorState();
}

class _CatchEditorState extends ConsumerState<_CatchEditor> {
  late CatchDetails _details = CatchDetails(
    speciesId: widget.item.speciesId,
    caughtAt: widget.item.caughtAt,
    weightGrams: widget.item.weightGrams,
    lengthMillimeters: widget.item.lengthMillimeters,
    released: widget.item.released,
    baitId: widget.item.baitId,
    gearId: widget.item.gearId,
    depthMillimeters: widget.item.depthMillimeters,
    notes: widget.item.notes,
  );
  late final CatchDetails _original = _details;
  var _valid = true;
  var _busy = false;

  bool get _dirty => _details != _original;

  Future<void> _changeSpecies() async {
    final choice = await showModalBottomSheet<SpeciesChoice>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.94,
        child: SpeciesPicker(onPicked: (c) => Navigator.of(context).pop(c)),
      ),
    );
    if (choice == null) return;
    setState(() => _details = _details.copyWith(speciesId: choice.speciesId));
  }

  Future<void> _changeTime() async {
    final local = (_details.caughtAt ?? widget.item.caughtAt).toLocal();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(local),
    );
    if (picked == null) return;
    final updated = DateTime(
      local.year,
      local.month,
      local.day,
      picked.hour,
      picked.minute,
    ).toUtc();
    setState(() => _details = _details.copyWith(caughtAt: updated));
  }

  Future<void> _addPhoto() async {
    final l10n = context.l10n;
    final origin = await showChoiceSheet<PhotoOrigin>(
      context: context,
      title: l10n.catchPhoto,
      selected: PhotoOrigin.camera,
      choices: [
        Choice(PhotoOrigin.camera, l10n.quickCatchTakePhoto),
        Choice(PhotoOrigin.gallery, l10n.quickCatchGallery),
      ],
    );
    if (origin == null) return;
    final path = await ref.read(photoSourceProvider).pick(origin);
    if (path == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final imported = await ref.read(photoImporterProvider).import(path);
      final repo = ref.read(catchRepositoryProvider);
      for (final old in widget.item.photos) {
        await repo.removePhoto(old.id);
      }
      await repo.addPhoto(widget.item.id, imported.stored);
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.photoImportFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removePhoto() async {
    final repo = ref.read(catchRepositoryProvider);
    for (final p in widget.item.photos) {
      await repo.removePhoto(p.id);
    }
  }

  Future<void> _save() async {
    if (!_valid || _busy) return;
    setState(() => _busy = true);
    await ref
        .read(catchRepositoryProvider)
        .updateDetails(widget.item.id, _details);
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final ok = await confirmDelete(
      context,
      title: l10n.deleteCatchTitle,
      body: l10n.deleteCatchBody,
    );
    if (!ok || !mounted) return;
    final repo = ref.read(catchRepositoryProvider);
    context.pop();
    await repo.deleteCatch(widget.item.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final text = Theme.of(context).textTheme;
    final id = _details.speciesId;
    final name = ref.watch(speciesNameProvider(id)) ?? l10n.speciesUnknown;
    final scientific = scientificNameOf(
      id == null ? null : ref.watch(speciesByIdProvider)[id],
    );
    final photo = widget.item.coverPhoto;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: l10n.deleteCatchTitle,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          PiscatioSizes.gutter,
          0,
          PiscatioSizes.gutter,
          24,
        ),
        children: [
          if (photo != null) ...[
            LayoutBuilder(
              builder: (context, constraints) => PhotoThumb(
                relativePath: photo.relativePath,
                size: constraints.maxWidth,
                radius: PiscatioRadii.slab,
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _busy ? null : _addPhoto,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l10n.catchReplacePhoto),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _removePhoto,
                  icon: const Icon(Icons.hide_image_outlined),
                  label: Text(l10n.catchRemovePhoto),
                ),
              ],
            ),
          ] else
            OutlinedButton.icon(
              onPressed: _busy ? null : _addPhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(l10n.catchAddPhoto),
            ),
          const SizedBox(height: 16),
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
                onPressed: _changeSpecies,
                child: Text(l10n.quickCatchChangeSpecies),
              ),
            ],
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_rounded),
            title: Text(l10n.catchTime),
            subtitle: Text(f.time(_details.caughtAt ?? widget.item.caughtAt)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _changeTime,
          ),
          const SizedBox(height: 8),
          CatchDetailsForm(
            initial: _details,
            onChanged: (d, valid) => setState(() {
              // The form does not own species and time; keep ours.
              _details = d.copyWith(
                speciesId: _details.speciesId,
                caughtAt: _details.caughtAt,
              );
              _valid = valid;
            }),
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
          onPressed: _dirty && _valid && !_busy ? _save : null,
        ),
      ),
    );
  }
}
