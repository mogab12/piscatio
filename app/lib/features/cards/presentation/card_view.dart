import 'package:flutter/widgets.dart';

import '../application/card_data.dart';
import 'card_canvas.dart';
import 'styles/board_card.dart';
import 'styles/chart_card.dart';
import 'styles/tag_card.dart';

/// A catch card at its canvas size, as customized in the editor.
class CatchCardView extends StatelessWidget {
  const CatchCardView({
    super.key,
    required this.data,
    required this.style,
    required this.format,
    this.options = const CardOptions(),
  });

  final CatchCardData data;
  final CardStyle style;
  final CardFormat format;
  final CardOptions options;

  /// What the card actually shows.
  CatchCardData get shown => data.customized(options);

  @override
  Widget build(BuildContext context) {
    final d = shown;
    return CardCanvas(
      format: format,
      palette: options.palette,
      photoFilter: options.activeFilter,
      child: switch (style) {
        CardStyle.board => BoardCatchCard(data: d, format: format),
        CardStyle.chart => ChartCatchCard(data: d, format: format),
        CardStyle.tag => TagCatchCard(data: d, format: format),
      },
    );
  }
}

/// A trip card at its canvas size, as customized in the editor.
class TripCardView extends StatelessWidget {
  const TripCardView({
    super.key,
    required this.data,
    required this.style,
    required this.format,
    this.options = const CardOptions(),
  });

  final TripCardData data;
  final CardStyle style;
  final CardFormat format;
  final CardOptions options;

  TripCardData get shown => data.customized(options);

  @override
  Widget build(BuildContext context) {
    final d = shown;
    return CardCanvas(
      format: format,
      palette: options.palette,
      photoFilter: options.activeFilter,
      child: switch (style) {
        CardStyle.board => BoardTripCard(data: d, format: format),
        CardStyle.chart => ChartTripCard(data: d, format: format),
        CardStyle.tag => TagTripCard(data: d, format: format),
      },
    );
  }
}
