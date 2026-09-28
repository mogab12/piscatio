import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatting/l10n.dart';
import '../../core/providers.dart';
import '../../core/theme/tokens.dart';
import '../../domain/models/species.dart';
import '../../domain/services/species_search.dart';
import '../settings/application/preferences.dart';
import 'species_label.dart';

/// Result of picking: a species id, or "don't know" (null id).
class SpeciesChoice {
  const SpeciesChoice(this.speciesId);

  const SpeciesChoice.unknown() : speciesId = null;

  final String? speciesId;
}

/// Search box plus list. Empty query: the species you catch most first,
/// then everything by name. Any name, synonym or scientific name matches,
/// accents and case ignored.
class SpeciesPicker extends ConsumerStatefulWidget {
  const SpeciesPicker({super.key, required this.onPicked, this.header});

  final ValueChanged<SpeciesChoice> onPicked;

  /// Shown above the search field, scrolling with the list.
  final Widget? header;

  @override
  ConsumerState<SpeciesPicker> createState() => _SpeciesPickerState();
}

class _SpeciesPickerState extends ConsumerState<SpeciesPicker> {
  final _query = TextEditingController();
  var _adding = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _addCustom(String name) async {
    if (_adding) return;
    setState(() => _adding = true);
    try {
      final species = await ref
          .read(speciesRepositoryProvider)
          .addCustomSpecies(name, lang: ref.read(effectiveLanguageProvider));
      widget.onPicked(SpeciesChoice(species.id));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final lang = ref.watch(effectiveLanguageProvider);
    final usage = ref.watch(speciesUsageProvider).value ?? const {};
    final search = ref.watch(speciesSearchProvider);
    final query = _query.text.trim();
    // With a query, usage breaks ties. Without one, favorites get their own
    // tiles and the full list below stays alphabetical.
    final results = search.search(
      query,
      lang: lang,
      usage: query.isEmpty ? const {} : usage,
    );
    final favorites = query.isEmpty
        ? search
              .search('', lang: lang, usage: usage)
              .where((m) => usage.containsKey(m.species.id))
              .take(6)
              .toList()
        : const <SpeciesMatch>[];

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        if (widget.header != null) SliverToBoxAdapter(child: widget.header),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              PiscatioSizes.gutter,
              8,
              PiscatioSizes.gutter,
              8,
            ),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              style: text.bodyLarge,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: l10n.speciesSearchHint,
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l10n.speciesSearchClear,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(_query.clear),
                      ),
              ),
            ),
          ),
        ),
        if (query.isEmpty) ...[
          SliverToBoxAdapter(
            child: _UnknownRow(
              onTap: () => widget.onPicked(const SpeciesChoice.unknown()),
            ),
          ),
          if (favorites.isNotEmpty) ...[
            SliverToBoxAdapter(child: _Heading(l10n.speciesMostUsed)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: PiscatioSizes.gutter,
              ),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 76,
                ),
                itemCount: favorites.length,
                itemBuilder: (context, i) => _FavoriteTile(
                  species: favorites[i].species,
                  lang: lang,
                  onTap: () =>
                      widget.onPicked(SpeciesChoice(favorites[i].species.id)),
                ),
              ),
            ),
          ],
          SliverToBoxAdapter(child: _Heading(l10n.speciesAll)),
        ],
        if (query.isNotEmpty && results.isEmpty)
          SliverToBoxAdapter(
            child: _NoResults(
              query: query,
              busy: _adding,
              onAdd: () => _addCustom(query),
            ),
          ),
        SliverList.builder(
          itemCount: results.length,
          itemBuilder: (context, i) => _SpeciesRow(
            match: results[i],
            lang: lang,
            showMatched: query.isNotEmpty,
            onTap: () => widget.onPicked(SpeciesChoice(results[i].species.id)),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      PiscatioSizes.gutter,
      20,
      PiscatioSizes.gutter,
      10,
    ),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall!
            .copyWith(color: context.palette.muted),
      ),
    ),
  );
}

class _UnknownRow extends StatelessWidget {
  const _UnknownRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 60,
      leading: Icon(Icons.help_outline_rounded, color: context.palette.muted),
      title: Text(context.l10n.speciesUnknownAction),
      onTap: onTap,
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.species,
    required this.lang,
    required this.onTap,
  });

  final Species species;
  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final scientific = scientificNameOf(species);
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(PiscatioRadii.field),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                species.displayName(lang),
                style: text.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (scientific != null)
                Text(
                  scientific,
                  style: text.bodySmall!.copyWith(fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeciesRow extends StatelessWidget {
  const _SpeciesRow({
    required this.match,
    required this.lang,
    required this.showMatched,
    required this.onTap,
  });

  final SpeciesMatch match;
  final String lang;
  final bool showMatched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final species = match.species;
    final name = species.displayName(lang);
    final scientific = scientificNameOf(species);
    final matched = match.matchedName;
    final showAlias =
        showMatched && matched != name && matched != species.scientificName;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: PiscatioSizes.minTouch),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PiscatioSizes.gutter,
            vertical: 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: text.titleMedium),
              if (showAlias)
                Text(
                  l10n.speciesAlsoKnownAs(matched),
                  style: text.bodyMedium!.copyWith(
                    color: context.palette.muted,
                  ),
                ),
              if (scientific != null)
                Text(
                  scientific,
                  style: text.bodyMedium!.copyWith(
                    fontStyle: FontStyle.italic,
                    color: context.palette.muted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({
    required this.query,
    required this.busy,
    required this.onAdd,
  });

  final String query;
  final bool busy;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PiscatioSizes.gutter,
        12,
        PiscatioSizes.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.speciesNoResults,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.speciesAddCustom(query)),
          ),
        ],
      ),
    );
  }
}
