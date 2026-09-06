enum YeastType { fresh, dry }

class Ingredients {
  int farina = 0;
  int acqua = 0;
  int lievito = 0;
  int sale = 0;
  int olio = 0;

  Ingredients.zero();
  Ingredients(this.farina, this.acqua, this.lievito, this.sale, this.olio);

  Ingredients operator +(Ingredients other) {
    return Ingredients(
      farina + other.farina,
      acqua + other.acqua,
      lievito + other.lievito,
      sale + other.sale,
      olio + other.olio,
    );
  }
}

abstract class CounterValue {
  void increment();
  void decrement();
  void restore();
  @override
  String toString();
}

class IntPercIngredient implements CounterValue {
  int _value;
  final int _defaultValue;
  final int _changeValue;

  IntPercIngredient(int value, int changeValue)
      : _value = value,
        _defaultValue = value,
        _changeValue = changeValue;

  int value() {
    return _value;
  }

  void setValue(int val) {
    _value = val;
  }

  @override
  void increment() {
    _value += _changeValue;
  }

  @override
  void decrement() {
    if (_value > 0) {
      if (_value <= _changeValue) {
        _value = 0;
      } else {
        _value -= _changeValue;
      }
    }
  }

  @override
  void restore() {
    _value = _defaultValue;
  }

  @override
  String toString() {
    return _value.toString();
  }
}

class DoublePercIngredient implements CounterValue {
  double _value;
  final double _defaultValue;
  final double _changeValue;

  DoublePercIngredient(double value, double changeValue)
      : _value = value,
        _defaultValue = value,
        _changeValue = changeValue;

  double value() {
    return _value;
  }

  void setValue(double val) {
    _value = val;
  }

  @override
  void increment() {
    _value += _changeValue;
  }

  @override
  void decrement() {
    if (_value > 0) {
      if (_value <= _changeValue) {
        _value = 0;
      } else {
        _value -= _changeValue;
      }
    }
  }

  @override
  void restore() {
    _value = _defaultValue;
  }

  @override
  String toString() {
    return _value.toStringAsFixed(2);
  }
}

class PercIngredients {
  IntPercIngredient water = IntPercIngredient(75, 5);
  DoublePercIngredient oil = DoublePercIngredient(6.00, 0.05);
  DoublePercIngredient salt = DoublePercIngredient(2.40, 0.05);
  DoublePercIngredient yeast = DoublePercIngredient(1.10, 0.05);
}
