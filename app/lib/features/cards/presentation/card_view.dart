import 'package:flutter/widgets.dart';

import '../application/card_data.dart';
import 'card_canvas.dart';
import 'styles/board_card.dart';
import 'styles/chart_card.dart';
import 'styles/tag_card.dart';

/// A catch card at its canvas size.
class CatchCardView extends StatelessWidget {
  const CatchCardView({
    super.key,
    required this.data,
    required this.style,
    required this.format,
  });

  final CatchCardData data;
  final CardStyle style;
  final CardFormat format;

  @override
  Widget build(BuildContext context) => CardCanvas(
    format: format,
    child: switch (style) {
      CardStyle.board => BoardCatchCard(data: data, format: format),
      CardStyle.chart => ChartCatchCard(data: data, format: format),
      CardStyle.tag => TagCatchCard(data: data, format: format),
    },
  );
}

/// A trip card at its canvas size.
class TripCardView extends StatelessWidget {
  const TripCardView({
    super.key,
    required this.data,
    required this.style,
    required this.format,
  });

  final TripCardData data;
  final CardStyle style;
  final CardFormat format;

  @override
  Widget build(BuildContext context) => CardCanvas(
    format: format,
    child: switch (style) {
      CardStyle.board => BoardTripCard(data: data, format: format),
      CardStyle.chart => ChartTripCard(data: data, format: format),
      CardStyle.tag => TagTripCard(data: data, format: format),
    },
  );
}
