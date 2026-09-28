import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/formatters_provider.dart';
import '../../../core/formatting/l10n.dart';
import '../../../core/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/action_slab.dart';
import '../../../core/widgets/section_label.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/tackle.dart';
import '../../common/tackle_dialog.dart';

enum TackleKind { bait, gear }

/// A row of either list, independent of the model type.
class _Item<T> {
  const _Item(this.id, this.name, this.type, {required this.archived});

  final String id;
  final String name;
  final T type;
  final bool archived;
}

/// Baits or gear: add, edit, archive, restore. Archived items leave the
/// pickers but stay on the catches that used them.
class TackleScreen extends ConsumerWidget {
  const TackleScreen({super.key, required this.kind});

  final TackleKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      kind == TackleKind.bait ? const _BaitList() : const _GearList();
}

class _BaitList extends ConsumerWidget {
  const _BaitList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final repo = ref.read(tackleRepositoryProvider);
    final items = [
      for (final b in ref.watch(allBaitsProvider).value ?? const <Bait>[])
        _Item<BaitType>(b.id, b.name, b.type, archived: b.archived),
    ];
    return _TackleList<BaitType>(
      title: l10n.tackleBaits,
      empty: l10n.tackleEmptyBaits,
      addLabel: l10n.tackleNewBait,
      editTitle: l10n.tackleEditBait,
      types: BaitType.values,
      initialType: BaitType.artificial,
      typeLabel: f.baitType,
      items: items,
      onAdd: (e) => repo.addBait(e.name, e.type),
      onUpdate: (id, e) => repo.updateBait(id, e.name, e.type),
      onArchive: (id, archived) => repo.setBaitArchived(id, archived: archived),
    );
  }
}

class _GearList extends ConsumerWidget {
  const _GearList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final repo = ref.read(tackleRepositoryProvider);
    final items = [
      for (final g in ref.watch(allGearProvider).value ?? const <Gear>[])
        _Item<GearType>(g.id, g.name, g.type, archived: g.archived),
    ];
    return _TackleList<GearType>(
      title: l10n.tackleGear,
      empty: l10n.tackleEmptyGear,
      addLabel: l10n.tackleNewGear,
      editTitle: l10n.tackleEditGear,
      types: GearType.values,
      initialType: GearType.combo,
      typeLabel: f.gearType,
      items: items,
      onAdd: (e) => repo.addGear(e.name, e.type),
      onUpdate: (id, e) => repo.updateGear(id, e.name, e.type),
      onArchive: (id, archived) => repo.setGearArchived(id, archived: archived),
    );
  }
}

class _TackleList<T> extends StatelessWidget {
  const _TackleList({
    required this.title,
    required this.empty,
    required this.addLabel,
    required this.editTitle,
    required this.types,
    required this.initialType,
    required this.typeLabel,
    required this.items,
    required this.onAdd,
    required this.onUpdate,
    required this.onArchive,
  });

  final String title;
  final String empty;
  final String addLabel;
  final String editTitle;
  final List<T> types;
  final T initialType;
  final String Function(T) typeLabel;
  final List<_Item<T>> items;
  final Future<Object?> Function(TackleEdit<T>) onAdd;
  final Future<void> Function(String id, TackleEdit<T>) onUpdate;
  final Future<void> Function(String id, bool archived) onArchive;

  Future<void> _add(BuildContext context) async {
    final created = await showDialog<TackleEdit<T>>(
      context: context,
      builder: (context) => TackleDialog<T>(
        title: addLabel,
        types: types,
        typeLabel: typeLabel,
        initialType: initialType,
      ),
    );
    if (created != null && !created.archive) await onAdd(created);
  }

  Future<void> _edit(BuildContext context, _Item<T> item) async {
    final edit = await showDialog<TackleEdit<T>>(
      context: context,
      builder: (context) => TackleDialog<T>(
        title: editTitle,
        types: types,
        typeLabel: typeLabel,
        initialType: item.type,
        initialName: item.name,
        archiveLabel: context.l10n.tackleArchive,
      ),
    );
    if (edit == null) return;
    if (edit.archive) {
      await onArchive(item.id, true);
    } else {
      await onUpdate(item.id, edit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final muted = text.bodyLarge!.copyWith(color: context.palette.muted);
    final active = items.where((i) => !i.archived).toList();
    final archived = items.where((i) => i.archived).toList();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (active.isEmpty)
            Padding(
              padding: const EdgeInsets.all(PiscatioSizes.gutter),
              child: Text(empty, style: muted),
            ),
          for (final i in active)
            ListTile(
              minTileHeight: PiscatioSizes.minTouch,
              title: Text(i.name),
              subtitle: Text(typeLabel(i.type)),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _edit(context, i),
            ),
          if (archived.isNotEmpty) ...[
            SectionLabel(l10n.tackleArchived),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PiscatioSizes.gutter,
                0,
                PiscatioSizes.gutter,
                8,
              ),
              child: Text(l10n.tackleArchivedNote, style: muted),
            ),
            for (final i in archived)
              ListTile(
                minTileHeight: PiscatioSizes.minTouch,
                title: Text(i.name),
                subtitle: Text(typeLabel(i.type)),
                trailing: TextButton(
                  onPressed: () => onArchive(i.id, false),
                  child: Text(l10n.tackleRestore),
                ),
              ),
          ],
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
          label: addLabel,
          icon: Icons.add_rounded,
          onPressed: () => _add(context),
        ),
      ),
    );
  }
}
