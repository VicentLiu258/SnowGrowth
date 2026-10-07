import 'package:flutter/material.dart';
import 'package:snow_growth/core/constants/app_colors.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/utils/data_exporter.dart';
import 'package:snow_growth/core/utils/local_storage.dart';
import 'package:snow_growth/core/widgets/app_card.dart';
import 'package:snow_growth/core/widgets/app_input.dart';
import 'package:snow_growth/core/widgets/tool_menu.dart';
import 'package:snow_growth/core/widgets/top_aligned_body.dart';

class PercentageCalculatorPage extends StatefulWidget {
  const PercentageCalculatorPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<PercentageCalculatorPage> createState() =>
      _PercentageCalculatorPageState();
}

class _PercentageCalculatorPageState extends State<PercentageCalculatorPage> {
  static const _modeKey = 'pct_mode';
  static const _xKey = 'pct_x';
  static const _yKey = 'pct_y';

  int _mode = 0;
  String _x = '25';
  String _y = '200';
  bool _loaded = false;

  final _modes = const [AppStrings.mode1, AppStrings.mode2, AppStrings.mode3];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final mode = await LocalStorage.getInt(_modeKey);
    final x = await LocalStorage.getString(_xKey);
    final y = await LocalStorage.getString(_yKey);
    if (!mounted) return;
    setState(() {
      _mode = mode ?? 0;
      _x = x ?? '25';
      _y = y ?? '200';
      _loaded = true;
    });
  }

  Future<void> _saveMode(int mode) async {
    _mode = mode;
    await LocalStorage.setInt(_modeKey, mode);
    setState(() {});
  }

  Future<void> _saveX(String value) async {
    _x = value;
    await LocalStorage.setString(_xKey, value);
    setState(() {});
  }

  Future<void> _saveY(String value) async {
    _y = value;
    await LocalStorage.setString(_yKey, value);
    setState(() {});
  }

  String _computeResult() {
    final vx = double.tryParse(_x);
    final vy = double.tryParse(_y);
    if (vx == null || vy == null) return '---';

    switch (_mode) {
      case 0:
        final result = (vx / 100) * vy;
        return '${_formatNum(vx)}% of ${_formatNum(vy)} = ${_formatNum(result)}';
      case 1:
        if (vy == 0) return 'Error (Div by 0)';
        final result = (vx / vy) * 100;
        return '${_formatNum(vx)} is ${_formatNum(result)}% of ${_formatNum(vy)}';
      case 2:
        if (vx == 0) return 'Error (Div by 0)';
        final result = ((vy - vx) / vx) * 100;
        final sign = result > 0 ? '+' : '';
        return 'Change: $sign${_formatNum(result)}%';
      default:
        return '---';
    }
  }

  String _formatNum(double value) {
    final text = value.toStringAsFixed(2);
    return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
  }

  Future<void> _clear() async {
    await LocalStorage.removeAll([_modeKey, _xKey, _yKey]);
    setState(() {
      _mode = 0;
      _x = '25';
      _y = '200';
    });
  }

  Future<void> _export() async {
    await DataExporter.exportJson({
      'tool': AppStrings.percentageCalculator,
      'mode': _mode,
      'valueX': _x,
      'valueY': _y,
      'result': _computeResult(),
    }, 'percentage_data.json');
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const TopAlignedLoading();
    }

    return TopAlignedBody(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTopBar(
            title: AppStrings.percentage,
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
                const Text(
                  AppStrings.mode,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray500,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_modes.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _saveMode(index),
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    _mode == index
                                        ? AppColors.emerald500
                                        : AppColors.gray300,
                                width: 2,
                              ),
                            ),
                            child:
                                _mode == index
                                    ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.emerald500,
                                        ),
                                      ),
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _modes[index],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                AppInput(
                  label: AppStrings.valueX,
                  value: _x,
                  onChanged: _saveX,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                AppInput(
                  label: AppStrings.valueY,
                  value: _y,
                  onChanged: _saveY,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Text(
                  AppStrings.result.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                    color: AppColors.gray400,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _computeResult(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
