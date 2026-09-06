import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'baking_pan.dart';
import 'ingredients.dart';
import 'consts.dart';
import 'data/baking_pan_repository.dart';
import 'data/preferences_repository.dart';
import 'data/preset_repository.dart';
import 'models/preset.dart';
import 'screens/preset_list_screen.dart';

class HintScrollView extends StatefulWidget {
  final Widget child;

  const HintScrollView({super.key, required this.child});

  @override
  State<HintScrollView> createState() => _HintScrollViewState();
}

class _HintScrollViewState extends State<HintScrollView> {
  final ScrollController _controller = ScrollController();
  bool _hinted = false;
  bool _showLeftFade = false;
  bool _showRightFade = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateFade);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFade();
      _tryHint();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_updateFade);
    _controller.dispose();
    super.dispose();
  }

  void _updateFade() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    final left = pos.pixels > 0;
    final right = pos.pixels < pos.maxScrollExtent;
    if (left != _showLeftFade || right != _showRightFade) {
      setState(() {
        _showLeftFade = left;
        _showRightFade = right;
      });
    }
  }

  void _tryHint() {
    if (_hinted) return;
    if (!_controller.hasClients) return;
    if (_controller.position.maxScrollExtent <= 0) return;
    _hinted = true;

    final target = _controller.position.maxScrollExtent.clamp(0.0, 40.0);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _controller.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ).then((_) {
        if (!mounted) return;
        _controller.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child = SingleChildScrollView(
      controller: _controller,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: widget.child,
    );

    if (_showLeftFade || _showRightFade) {
      child = ShaderMask(
        shaderCallback: (bounds) {
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              if (_showLeftFade) Colors.transparent else Colors.white,
              Colors.white,
              Colors.white,
              if (_showRightFade) Colors.transparent else Colors.white,
            ],
            stops: const [0.0, 0.05, 0.95, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: child,
      );
    }

    return child;
  }
}

class Home extends StatefulWidget {
  final PresetRepository presetRepository;
  final BakingPanRepository bakingPanRepository;
  final PreferencesRepository preferencesRepository;
  final ValueChanged<Locale> onLocaleChanged;

  const Home({
    super.key,
    required this.presetRepository,
    required this.bakingPanRepository,
    required this.preferencesRepository,
    required this.onLocaleChanged,
  });

  @override
  HomeState createState() => HomeState();
}

Widget buildIngredient(String name, int amount, IconData icon) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Row(
      children: [
        Icon(icon, color: primaryColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 16, color: secondaryTextColor),
          ),
        ),
        Text(
          '${amount.toString()} gr',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
          ),
        ),
      ],
    ),
  );
}

class HomeState extends State<Home> {
  List<BakingPan> bakingPans = [];

  PercIngredients percIngredients = PercIngredients();
  YeastType yeastType = YeastType.fresh;
  DoublePercIngredient impastoRatio = DoublePercIngredient(0.46, 0.01);

  Ingredients ingredients = Ingredients.zero();

  @override
  void initState() {
    super.initState();
    _loadBakingPans();
  }

  Future<void> _loadBakingPans() async {
    final saved = await widget.bakingPanRepository.getAll();
    setState(() {
      bakingPans = saved.isEmpty ? defaultBakingPans() : saved;
    });
  }

  Future<void> _saveBakingPans() async {
    await widget.bakingPanRepository.saveAll(bakingPans);
  }

  void applyPreset(Preset preset) {
    updateIngredients(() {
      percIngredients.water.setValue(preset.waterPerc);
      percIngredients.oil.setValue(preset.oilPerc);
      percIngredients.salt.setValue(preset.saltPerc);
      percIngredients.yeast.setValue(preset.yeastPerc);
      yeastType = preset.yeastType == 'dry' ? YeastType.dry : YeastType.fresh;
      impastoRatio.setValue(preset.impastoRatio);
    });
  }

  static const _supportedLocales = ['it', 'en', 'es', 'fr', 'de', 'pt', 'ja', 'tr'];

  void _toggleLocale() {
    final current = Localizations.localeOf(context).languageCode;
    final currentIndex = _supportedLocales.indexOf(current);
    final nextIndex = (currentIndex + 1) % _supportedLocales.length;
    final next = Locale(_supportedLocales[nextIndex]);
    widget.onLocaleChanged(next);
    widget.preferencesRepository.setLocale(next.languageCode);
  }

  void _openPresets() async {
    final preset = await Navigator.push<Preset>(
      context,
      MaterialPageRoute(
        builder: (_) => PresetListScreen(
          repository: widget.presetRepository,
          currentWaterPerc: percIngredients.water.value(),
          currentOilPerc: percIngredients.oil.value(),
          currentSaltPerc: percIngredients.salt.value(),
          currentYeastPerc: percIngredients.yeast.value(),
          currentYeastType: yeastType == YeastType.dry ? 'dry' : 'fresh',
          currentImpastoRatio: impastoRatio.value(),
        ),
      ),
    );
    if (preset != null) {
      applyPreset(preset);
    }
  }

  void updateIngredients(void Function() action) {
    setState(() {
      action();
      ingredients = Ingredients.zero();
      for (var bakingPan in bakingPans) {
        ingredients += bakingPan.calculateIngredients(
            percIngredients, impastoRatio.value(),
            yeastType: yeastType);
      }
    });
  }

  void _addBakingPan() {
    final l10n = AppLocalizations.of(context)!;
    final widthController = TextEditingController();
    final heightController = TextEditingController();
    PanShape selectedShape = PanShape.rectangular;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardDark,
          title: Text(l10n.newPan,
              style: const TextStyle(color: primaryColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<PanShape>(
                segments: [
                  ButtonSegment(
                    value: PanShape.rectangular,
                    icon: const Icon(Icons.rectangle_rounded),
                    label: Text(l10n.rectangular),
                  ),
                  ButtonSegment(
                    value: PanShape.circular,
                    icon: const Icon(Icons.circle),
                    label: Text(l10n.circular),
                  ),
                ],
                selected: {selectedShape},
                onSelectionChanged: (selection) {
                  setDialogState(() {
                    selectedShape = selection.first;
                  });
                },
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return secondaryColor;
                    }
                    return secondaryTextColor;
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return primaryColor;
                    }
                    return Colors.transparent;
                  }),
                  side: WidgetStateProperty.all(
                    const BorderSide(color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (selectedShape == PanShape.rectangular) ...[
                TextField(
                  controller: widthController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText: l10n.widthCm,
                    labelStyle: const TextStyle(color: secondaryTextColor),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: secondaryTextColor),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText: l10n.heightCm,
                    labelStyle: const TextStyle(color: secondaryTextColor),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: secondaryTextColor),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                ),
              ] else
                TextField(
                  controller: widthController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: primaryTextColor),
                  decoration: InputDecoration(
                    labelText: l10n.diameterCm,
                    labelStyle: const TextStyle(color: secondaryTextColor),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: secondaryTextColor),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: primaryColor),
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel,
                  style: const TextStyle(color: secondaryTextColor)),
            ),
            TextButton(
              onPressed: () {
                final dim1 = double.tryParse(widthController.text);
                final dim2 = double.tryParse(heightController.text);
                if (dim1 == null || dim1 <= 0) return;
                if (selectedShape == PanShape.rectangular &&
                    (dim2 == null || dim2 <= 0)) return;

                Navigator.pop(context);
                updateIngredients(() {
                  bakingPans.add(BakingPan(
                    shape: selectedShape,
                    dim1: dim1,
                    dim2: dim2 ?? 0,
                  ));
                });
                _saveBakingPans();
              },
              child: Text(l10n.add,
                  style: const TextStyle(color: primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  void _removeBakingPan(int index) async {
    final l10n = AppLocalizations.of(context)!;
    final pan = bakingPans[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardDark,
        title: Text(l10n.removePan,
            style: const TextStyle(color: primaryColor)),
        content: Text(
          l10n.removePanConfirm(pan.getDescription()),
          style: const TextStyle(color: primaryTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: secondaryTextColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.remove,
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      updateIngredients(() {
        bakingPans.removeAt(index);
      });
      _saveBakingPans();
    }
  }

  Widget _buildStepper(CounterValue counter) {
    return Container(
      decoration: BoxDecoration(
        color: mutedOrange,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  updateIngredients(() => counter.decrement());
                },
                child: const Center(
                  child: Icon(Icons.remove, color: primaryColor, size: 22),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  updateIngredients(() => counter.increment());
                },
                child: const Center(
                  child: Icon(Icons.add, color: primaryColor, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildValueChangerWidget(
    CounterValue counter,
    String label,
    String value,
    Axis direction,
  ) {
    return Flex(
      direction: direction,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty)
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: secondaryTextColor,
            ),
          ),
        Tooltip(
          message: AppLocalizations.of(context)!.longPressToRestore,
          child: GestureDetector(
            onLongPress: () {
              HapticFeedback.mediumImpact();
              updateIngredients(() => counter.restore());
            },
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10, height: 6),
        _buildStepper(counter),
      ],
    );
  }

  Widget buildBakingPanWidget(BakingPan bakingPan, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onLongPress: () => _removeBakingPan(index),
        child: Column(
          children: [
            Icon(
              bakingPan.getIconData(),
              color: primaryColor,
              size: 44,
            ),
            Text(
              bakingPan.getDescription(),
              style: const TextStyle(
                fontSize: 15,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${bakingPan.getDough(impastoRatio.value())} gr',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 4),
            buildValueChangerWidget(
              bakingPan.counter,
              '',
              "x ${bakingPan.counter.toString()}",
              Axis.vertical,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildImpastoRatioWidget() {
    return buildValueChangerWidget(
      impastoRatio,
      '',
      "÷ ${AppLocalizations.of(context)!.doughBall} ${impastoRatio.toString()}",
      Axis.horizontal,
    );
  }

  void _resetBakingPans() {
    updateIngredients(() {
      bakingPans = defaultBakingPans();
    });
    _saveBakingPans();
  }

  List<Widget> buildBakingPansWidgets() {
    List<Widget> widgets = <Widget>[];
    for (var i = 0; i < bakingPans.length; i++) {
      widgets.add(buildBakingPanWidget(bakingPans[i], i));
    }
    widgets.add(
      Column(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: secondaryTextColor, size: 36),
            tooltip: AppLocalizations.of(context)!.addPan,
            onPressed: _addBakingPan,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt,
                color: secondaryTextColor, size: 28),
            tooltip: AppLocalizations.of(context)!.resetPans,
            onPressed: _resetBakingPans,
          ),
        ],
      ),
    );
    return widgets;
  }

  Widget _buildPercColumn({
    required String label,
    required CounterValue counter,
    required String valueText,
    Widget? subLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          SizedBox(
            height: 46,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: secondaryTextColor,
                  ),
                ),
                if (subLabel != null) subLabel,
              ],
            ),
          ),
          Tooltip(
            message: AppLocalizations.of(context)!.longPressToRestore,
            child: GestureDetector(
              onLongPress: () {
                HapticFeedback.mediumImpact();
                updateIngredients(() => counter.restore());
              },
              child: Text(
                valueText,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _buildStepper(counter),
        ],
      ),
    );
  }

  List<Widget> buildPercIngredientsWidget() {
    final l10n = AppLocalizations.of(context)!;
    final isFresh = yeastType == YeastType.fresh;
    return [
      _buildPercColumn(
        label: l10n.water,
        counter: percIngredients.water,
        valueText: '${percIngredients.water.toString()} %',
      ),
      _buildPercColumn(
        label: l10n.yeast,
        counter: percIngredients.yeast,
        valueText: '${percIngredients.yeast.toString()} %',
        subLabel: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            updateIngredients(() {
              yeastType = isFresh ? YeastType.dry : YeastType.fresh;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isFresh ? l10n.yeastFresh : l10n.yeastDry,
                style: const TextStyle(
                  fontSize: 14,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.swap_horiz, color: primaryColor, size: 16),
            ],
          ),
        ),
      ),
      _buildPercColumn(
        label: l10n.salt,
        counter: percIngredients.salt,
        valueText: '${percIngredients.salt.toString()} %',
      ),
      _buildPercColumn(
        label: l10n.oil,
        counter: percIngredients.oil,
        valueText: '${percIngredients.oil.toString()} %',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          toolbarHeight: 70,
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image(
                image: AssetImage('assets/images/pizza.png'),
                fit: BoxFit.cover,
                height: 40.0,
              ),
              SizedBox(width: 20),
              Text(
                'Impasta',
                style: TextStyle(
                    color: primaryColor,
                    fontSize: 50.0,
                    fontFamily: primaryFontFamily),
              ),
            ],
          ),
          backgroundColor: secondaryColor,
          scrolledUnderElevation: 0,
          leading: GestureDetector(
            onTap: _toggleLocale,
            child: Center(
              child: Text(
                Localizations.localeOf(context).languageCode.toUpperCase(),
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.bookmark_outline, color: primaryColor, size: 28),
              tooltip: AppLocalizations.of(context)!.savedPresets,
              onPressed: _openPresets,
            ),
          ],
        ),
        body: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Card(
                color: cardColor,
                surfaceTintColor: cardSurfaceTintColor,
                shadowColor: cardShadowColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      child: buildImpastoRatioWidget(),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) => Container(
                        padding: const EdgeInsets.all(14),
                        child: HintScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth - 20,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: buildBakingPansWidgets(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(5.0),
              ),
              LayoutBuilder(
                builder: (context, constraints) => Card(
                  color: cardColor,
                  surfaceTintColor: cardSurfaceTintColor,
                  shadowColor: cardShadowColor,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    child: HintScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth - 20,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: buildPercIngredientsWidget(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Card(
                    color: cardColor,
                    surfaceTintColor: cardSurfaceTintColor,
                    shadowColor: cardShadowColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RepaintBoundary(
                      child: ListView(
                        physics: const ClampingScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                            child: Text(
                              AppLocalizations.of(context)!.ingredients,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: secondaryTextColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          buildIngredient(
                            AppLocalizations.of(context)!.flour,
                            ingredients.farina,
                            Icons.whatshot,
                          ),
                          buildIngredient(
                            AppLocalizations.of(context)!.water,
                            ingredients.acqua,
                            Icons.water_drop,
                          ),
                          buildIngredient(
                            yeastType == YeastType.fresh
                                ? AppLocalizations.of(context)!.yeastFullFresh
                                : AppLocalizations.of(context)!.yeastFullDry,
                            ingredients.lievito,
                            Icons.trending_up,
                          ),
                          buildIngredient(
                            AppLocalizations.of(context)!.salt,
                            ingredients.sale,
                            Icons.grain,
                          ),
                          buildIngredient(
                            AppLocalizations.of(context)!.oil,
                            ingredients.olio,
                            Icons.oil_barrel,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        backgroundColor: secondaryColor,
    );
  }
}
