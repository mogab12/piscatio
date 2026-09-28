import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting/formatters.dart';
import '../../core/formatting/formatters_provider.dart';
import '../../core/formatting/l10n.dart';
import '../../core/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/choice_sheet.dart';
import '../../domain/models/catch.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/tackle.dart';
import '../../domain/services/units.dart';
import 'tackle_dialog.dart';

/// Optional catch fields: weight, length, released/kept, bait, gear, depth
/// and notes. Typed in the user's units, reported in SI.
class CatchDetailsForm extends ConsumerStatefulWidget {
  const CatchDetailsForm({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final CatchDetails initial;

  /// Called on every edit with the SI values and whether all typed numbers
  /// are valid.
  final void Function(CatchDetails details, bool valid) onChanged;

  @override
  ConsumerState<CatchDetailsForm> createState() => _CatchDetailsFormState();
}

class _CatchDetailsFormState extends ConsumerState<CatchDetailsForm> {
  final _weight = TextEditingController();
  final _ounces = TextEditingController();
  final _length = TextEditingController();
  final _depth = TextEditingController();
  final _notes = TextEditingController();
  bool? _released;
  String? _baitId;
  String? _gearId;
  UnitSystem? _filledWith;

  @override
  void initState() {
    super.initState();
    _released = widget.initial.released;
    _baitId = widget.initial.baitId;
    _gearId = widget.initial.gearId;
    _notes.text = widget.initial.notes ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final units = ref.read(unitSystemProvider);
    if (_filledWith != units) {
      _fillNumbers(Formatters(context.l10n, units));
      _filledWith = units;
    }
  }

  void _fillNumbers(Formatters f) {
    final d = widget.initial;
    String fmt(Quantity q) => f.quantityValue(q);
    _weight.clear();
    _ounces.clear();
    if (d.weightGrams != null) {
      final parts = weightParts(d.weightGrams!, f.units);
      if (f.units == UnitSystem.imperial) {
        for (final q in parts) {
          (q.unit == DisplayUnit.pound ? _weight : _ounces).text = fmt(q);
        }
      } else {
        // Always kilograms in the form, even below 1 kg.
        _weight.text = f.number(d.weightGrams! / 1000, maxFractionDigits: 3);
      }
    }
    _length.text = d.lengthMillimeters == null
        ? ''
        : fmt(lengthQuantity(d.lengthMillimeters!, f.units));
    _depth.text = d.depthMillimeters == null
        ? ''
        : fmt(depthQuantity(d.depthMillimeters!, f.units));
  }

  @override
  void dispose() {
    for (final c in [_weight, _ounces, _length, _depth, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Parses a field: null when empty, NaN when invalid.
  static double? _parse(TextEditingController c) {
    if (c.text.trim().isEmpty) return null;
    return parseDecimal(c.text) ?? double.nan;
  }

  void _emit() {
    final units = ref.read(unitSystemProvider);
    final weight = _parse(_weight);
    final ounces = units == UnitSystem.imperial ? _parse(_ounces) : null;
    final length = _parse(_length);
    final depth = _parse(_depth);
    final values = [weight, ounces, length, depth];
    final valid = !values.any((v) => v != null && v.isNaN);

    int? positive(int? v) => v == null || v <= 0 ? null : v;
    int? grams;
    if (valid && (weight != null || ounces != null)) {
      grams = units == UnitSystem.imperial
          ? Units.gramsFromPounds(weight ?? 0, ounces ?? 0)
          : Units.gramsFromKilograms(weight!);
    }
    final details = widget.initial.copyWith(
      weightGrams: positive(grams),
      lengthMillimeters: !valid || length == null
          ? null
          : positive(
              units == UnitSystem.imperial
                  ? Units.millimetersFromInches(length)
                  : Units.millimetersFromCentimeters(length),
            ),
      depthMillimeters: !valid || depth == null
          ? null
          : positive(
              units == UnitSystem.imperial
                  ? Units.millimetersFromFeet(depth)
                  : Units.millimetersFromMeters(depth),
            ),
      released: _released,
      baitId: _baitId,
      gearId: _gearId,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    widget.onChanged(details, valid);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    final imperial = f.units == UnitSystem.imperial;
    final baits = ref.watch(baitsProvider).value ?? const <Bait>[];
    final gear = ref.watch(gearProvider).value ?? const <Gear>[];
    final bait = baits.where((b) => b.id == _baitId).firstOrNull;
    final gearItem = gear.where((g) => g.id == _gearId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Room for the first field's floating label.
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _NumberField(
                controller: _weight,
                label: l10n.catchWeight,
                unit: f.unitSymbol(
                  imperial ? DisplayUnit.pound : DisplayUnit.kilogram,
                ),
                onChanged: _emit,
              ),
            ),
            if (imperial) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(
                  controller: _ounces,
                  label: l10n.catchWeightOunces,
                  unit: f.unitSymbol(DisplayUnit.ounce),
                  onChanged: _emit,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _NumberField(
                controller: _length,
                label: l10n.catchLength,
                unit: f.unitSymbol(
                  imperial ? DisplayUnit.inch : DisplayUnit.centimeter,
                ),
                onChanged: _emit,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberField(
                controller: _depth,
                label: l10n.catchDepth,
                unit: f.unitSymbol(
                  imperial ? DisplayUnit.foot : DisplayUnit.meter,
                ),
                onChanged: _emit,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          l10n.catchReleasedQuestion,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: [
            for (final (value, label) in [
              (true, l10n.catchReleasedYes),
              (false, l10n.catchReleasedNo),
            ])
              ChoiceChip(
                label: Text(label),
                selected: _released == value,
                onSelected: (on) {
                  setState(() => _released = on ? value : null);
                  _emit();
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        _PickerRow(
          icon: Icons.bug_report_outlined,
          label: l10n.catchBait,
          value: bait?.name,
          placeholder: l10n.catchChooseBait,
          onTap: () async {
            final picked = await _pickBait(context, baits);
            if (picked == null) return;
            setState(() => _baitId = picked.isEmpty ? null : picked);
            _emit();
          },
        ),
        _PickerRow(
          icon: Icons.handyman_outlined,
          label: l10n.catchGear,
          value: gearItem?.name,
          placeholder: l10n.catchChooseGear,
          onTap: () async {
            final picked = await _pickGear(context, gear);
            if (picked == null) return;
            setState(() => _gearId = picked.isEmpty ? null : picked);
            _emit();
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          onChanged: (_) => _emit(),
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.catchNotes),
        ),
      ],
    );
  }

  /// Returns a bait id, '' for "none", or null if dismissed.
  Future<String?> _pickBait(BuildContext context, List<Bait> baits) async {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    const newItem = '__new__';
    final picked = await showChoiceSheet<String>(
      context: context,
      title: l10n.catchBait,
      selected: _baitId ?? '',
      choices: [
        Choice('', l10n.catchNone),
        for (final b in baits)
          Choice(b.id, b.name, description: f.baitType(b.type)),
        Choice(newItem, l10n.tackleNewBait),
      ],
    );
    if (picked != newItem || !context.mounted) return picked;
    final created = await showDialog<TackleEdit<BaitType>>(
      context: context,
      builder: (context) => TackleDialog<BaitType>(
        title: l10n.tackleNewBait,
        types: BaitType.values,
        typeLabel: f.baitType,
        initialType: BaitType.artificial,
      ),
    );
    if (created == null) return null;
    final bait = await ref
        .read(tackleRepositoryProvider)
        .addBait(created.name, created.type);
    return bait.id;
  }

  Future<String?> _pickGear(BuildContext context, List<Gear> gear) async {
    final l10n = context.l10n;
    final f = context.formatters(ref);
    const newItem = '__new__';
    final picked = await showChoiceSheet<String>(
      context: context,
      title: l10n.catchGear,
      selected: _gearId ?? '',
      choices: [
        Choice('', l10n.catchNone),
        for (final g in gear)
          Choice(g.id, g.name, description: f.gearType(g.type)),
        Choice(newItem, l10n.tackleNewGear),
      ],
    );
    if (picked != newItem || !context.mounted) return picked;
    final created = await showDialog<TackleEdit<GearType>>(
      context: context,
      builder: (context) => TackleDialog<GearType>(
        title: l10n.tackleNewGear,
        types: GearType.values,
        typeLabel: f.gearType,
        initialType: GearType.combo,
      ),
    );
    if (created == null) return null;
    final item = await ref
        .read(tackleRepositoryProvider)
        .addGear(created.name, created.type);
    return item.id;
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String unit;
  final VoidCallback onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      style: Theme.of(context).textTheme.titleLarge!.copyWith(
        fontFamily: PiscatioFonts.expanded,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w800,
      ),
      onChanged: (value) {
        final invalid = value.trim().isNotEmpty && parseDecimal(value) == null;
        setState(
          () => _error = invalid ? context.l10n.errorInvalidNumber : null,
        );
        widget.onChanged();
      },
      decoration: InputDecoration(
        labelText: widget.label,
        suffixText: widget.unit,
        errorText: _error,
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value ?? placeholder),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
