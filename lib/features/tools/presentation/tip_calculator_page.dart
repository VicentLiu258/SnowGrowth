import 'package:flutter/material.dart';
import 'package:snow_growth/core/constants/app_colors.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/utils/data_exporter.dart';
import 'package:snow_growth/core/utils/local_storage.dart';
import 'package:snow_growth/core/widgets/app_button.dart';
import 'package:snow_growth/core/widgets/app_card.dart';
import 'package:snow_growth/core/widgets/app_input.dart';
import 'package:snow_growth/core/widgets/tool_menu.dart';

class TipCalculatorPage extends StatefulWidget {
  const TipCalculatorPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<TipCalculatorPage> createState() => _TipCalculatorPageState();
}

class _TipCalculatorPageState extends State<TipCalculatorPage> {
  static const _billKey = 'tip_bill';
  static const _pctKey = 'tip_pct';
  static const _splitKey = 'tip_split';

  String _bill = '85.00';
  double _tipPct = 15;
  int _split = 4;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final bill = await LocalStorage.getString(_billKey);
    final pct = await LocalStorage.getDouble(_pctKey);
    final split = await LocalStorage.getInt(_splitKey);

    if (!mounted) return;
    setState(() {
      _bill = bill ?? '85.00';
      _tipPct = pct ?? 15;
      _split = split ?? 4;
      _loaded = true;
    });
  }

  double get _billAmount => (double.tryParse(_bill) ?? 0).clamp(0, double.infinity);
  int get _validSplit => _split < 1 ? 1 : _split;
  double get _tipAmount => _billAmount * (_tipPct / 100);
  double get _total => _billAmount + _tipAmount;
  double get _perPerson => _total / _validSplit;

  Future<void> _saveBill(String value) async {
    setState(() => _bill = value);
    await LocalStorage.setString(_billKey, value);
  }

  Future<void> _savePct(double value) async {
    setState(() => _tipPct = value);
    await LocalStorage.setDouble(_pctKey, value);
  }

  Future<void> _saveSplit(int value) async {
    setState(() => _split = value);
    await LocalStorage.setInt(_splitKey, value);
  }

  Future<void> _clear() async {
    await LocalStorage.removeAll([_billKey, _pctKey, _splitKey]);
    setState(() {
      _bill = '85.00';
      _tipPct = 15;
      _split = 4;
    });
  }

  Future<void> _export() async {
    await DataExporter.exportJson(
      {
        'tool': AppStrings.tipCalculator,
        'billAmount': _billAmount,
        'tipPercentage': _tipPct,
        'splitBetween': _validSplit,
        'totalTip': _tipAmount,
        'totalBill': _total,
        'perPerson': _perPerson,
      },
      'tip_calculator_data.json',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          AppTopBar(
            title: AppStrings.tipCalculator,
            onBack: widget.onBack,
            showMenu: true,
            onClear: _clear,
            onExport: _export,
          ),
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppInput(
                  label: AppStrings.billAmount,
                  value: _bill,
                  onChanged: _saveBill,
                  prefix: '\$ ',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      AppStrings.tipPercent,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray500,
                      ),
                    ),
                    Text(
                      '${_tipPct.round()}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _tipPct,
                  min: 0,
                  max: 30,
                  divisions: 30,
                  onChanged: _savePct,
                ),
                const SizedBox(height: 16),
                const Text(
                  AppStrings.splitBetween,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    AppButton(
                      variant: AppButtonVariant.secondary,
                      label: '',
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: () =>
                          _saveSplit(_validSplit > 1 ? _validSplit - 1 : 1),
                      padding: const EdgeInsets.all(12),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$_validSplit',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    AppButton(
                      variant: AppButtonVariant.secondary,
                      label: '',
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () => _saveSplit(_validSplit + 1),
                      padding: const EdgeInsets.all(12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _ResultRow(
                  label: AppStrings.tip,
                  value: '\$${_tipAmount.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 12),
                _ResultRow(
                  label: AppStrings.total,
                  value: '\$${_total.toStringAsFixed(2)}',
                ),
                const Divider(height: 32),
                _ResultRow(
                  label: AppStrings.perPerson,
                  value: '\$${_perPerson.toStringAsFixed(2)}',
                  highlight: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: highlight ? 18 : 16,
            fontWeight: FontWeight.w500,
            color: highlight ? AppColors.gray500 : AppColors.gray600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 28 : 18,
            fontWeight: FontWeight.bold,
            color: highlight ? AppColors.emerald600 : AppColors.gray900,
          ),
        ),
      ],
    );
  }
}
