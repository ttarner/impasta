import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'ingredients.dart';

enum PanShape { rectangular, circular }

class BakingPan {
  final PanShape shape;
  final double dim1; // width (rect) or diameter (circle)
  final double dim2; // height (rect), unused for circle
  IntPercIngredient counter = IntPercIngredient(0, 1);

  BakingPan({
    required this.shape,
    required this.dim1,
    this.dim2 = 0,
  });

  double get area {
    switch (shape) {
      case PanShape.rectangular:
        return dim1 * dim2;
      case PanShape.circular:
        final r = dim1 / 2;
        return math.pi * r * r;
    }
  }

  int getDough(double ratio) {
    return (area * ratio).round();
  }

  String getDescription() {
    switch (shape) {
      case PanShape.rectangular:
        return '${dim1.round()} x ${dim2.round()} cm';
      case PanShape.circular:
        return 'd ${dim1.round()} cm';
    }
  }

  IconData getIconData() {
    switch (shape) {
      case PanShape.rectangular:
        return Icons.rectangle_rounded;
      case PanShape.circular:
        return Icons.circle;
    }
  }

  Map<String, dynamic> toMap() => {
        'shape': shape.name,
        'dim1': dim1,
        'dim2': dim2,
      };

  factory BakingPan.fromMap(Map<String, dynamic> map) => BakingPan(
        shape: PanShape.values.byName(map['shape'] as String),
        dim1: (map['dim1'] as num).toDouble(),
        dim2: (map['dim2'] as num?)?.toDouble() ?? 0,
      );

  Ingredients calculateIngredients(
      PercIngredients percIngredients, double impastoRatio,
      {YeastType yeastType = YeastType.fresh}) {
    int dough = getDough(impastoRatio) * counter.value();
    int flour = (dough / (1 + (percIngredients.water.value() / 100))).round();
    int water = dough - flour;
    double yeastPerc = percIngredients.yeast.value();
    int yeast = ((flour / 100) * yeastPerc).round();
    if (yeastType == YeastType.dry) {
      yeast = (yeast / 3).round();
    }
    int salt = ((flour / 100) * percIngredients.salt.value()).round();
    int oil = ((flour / 100) * percIngredients.oil.value()).round();
    return Ingredients(flour, water, yeast, salt, oil);
  }
}

List<BakingPan> defaultBakingPans() {
  return [
    BakingPan(shape: PanShape.rectangular, dim1: 40, dim2: 30),
    BakingPan(shape: PanShape.circular, dim1: 28),
    BakingPan(shape: PanShape.circular, dim1: 20),
  ];
}
