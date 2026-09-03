import 'package:flutter/material.dart';
import 'package:snow_growth/core/constants/app_colors.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/utils/data_exporter.dart';
import 'package:snow_growth/core/utils/local_storage.dart';
import 'package:snow_growth/core/widgets/app_card.dart';
import 'package:snow_growth/core/widgets/app_input.dart';
import 'package:snow_growth/core/widgets/tool_menu.dart';
import 'package:snow_growth/core/widgets/top_aligned_body.dart';
import 'package:snow_growth/features/tools/logic/unit_converter_data.dart';

class UnitConverterPage extends StatefulWidget {
  const UnitConverterPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<UnitConverterPage> createState() => _UnitConverterPageState();
}

class _UnitConverterPageState extends State<UnitConverterPage> {
  static const _catKey = 'unit_cat';
  static const _fromKey = 'unit_from';
  static const _toKey = 'unit_to';
  static const _v1Key = 'unit_v1';
  static const _v2Key = 'unit_v2';
  static const _lastEditKey = 'unit_last_edit';

  UnitCategory _category = UnitCategory.length;
  String _fromUnit = 'Meter';
  String _toUnit = 'Foot';
  String _val1 = '100';
  String _val2 = '328.08399';
  int _lastEdited = 1;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final catIndex = await LocalStorage.getInt(_catKey);
    final from = await LocalStorage.getString(_fromKey);
    final to = await LocalStorage.getString(_toKey);
    final v1 = await LocalStorage.getString(_v1Key);
    final v2 = await LocalStorage.getString(_v2Key);
    final lastEdit = await LocalStorage.getInt(_lastEditKey);

    if (!mounted) return;
    setState(() {
      if (catIndex != null &&
          catIndex >= 0 &&
          catIndex < UnitCategory.values.length) {
        _category = UnitCategory.values[catIndex];
      }
      _fromUnit = from ?? UnitConverterData.units[_category]!.first;
      _toUnit = to ??
          (UnitConverterData.units[_category]!.length > 1
              ? UnitConverterData.units[_category]![1]
              : UnitConverterData.units[_category]!.first);
      _val1 = v1 ?? '100';
      _val2 = v2 ?? '328.08399';
      _lastEdited = lastEdit ?? 1;
      _loaded = true;
    });
  }

  Future<void> _persist() async {
    await LocalStorage.setInt(_catKey, _category.index);
    await LocalStorage.setString(_fromKey, _fromUnit);
    await LocalStorage.setString(_toKey, _toUnit);
    await LocalStorage.setString(_v1Key, _val1);
    await LocalStorage.setString(_v2Key, _val2);
    await LocalStorage.setInt(_lastEditKey, _lastEdited);
  }

  void _updateFrom(String value) {
    setState(() {
      _val1 = value;
      _lastEdited = 1;
      final parsed = double.tryParse(value);
      if (parsed == null) {
        _val2 = '';
      } else {
        final converted = UnitConverterData.convert(
          parsed,
          _fromUnit,
          _toUnit,
          _category,
        );
        _val2 = _formatValue(converted);
      }
    });
    _persist();
  }

  void _updateTo(String value) {
    setState(() {
      _val2 = value;
      _lastEdited = 2;
      final parsed = double.tryParse(value);
      if (parsed == null) {
        _val1 = '';
      } else {
        final converted = UnitConverterData.convert(
          parsed,
          _toUnit,
          _fromUnit,
          _category,
        );
        _val1 = _formatValue(converted);
      }
    });
    _persist();
  }

  String _formatValue(double value) {
    return value.toStringAsFixed(6).replaceAll(RegExp(r'\.?0+$'), '');
  }

  void _changeCategory(UnitCategory category) {
    final units = UnitConverterData.units[category]!;
    final newFrom = units.first;
    final newTo = units.length > 1 ? units[1] : units.first;

    setState(() {
      _category = category;
      _fromUnit = newFrom;
      _toUnit = newTo;
      if (_lastEdited == 1) {
        final parsed = double.tryParse(_val1);
        if (parsed != null) {
          _val2 = _formatValue(
            UnitConverterData.convert(parsed, newFrom, newTo, category),
          );
        }
      } else {
        final parsed = double.tryParse(_val2);
        if (parsed != null) {
          _val1 = _formatValue(
            UnitConverterData.convert(parsed, newTo, newFrom, category),
          );
        }
      }
    });
    _persist();
  }

  void _changeFromUnit(String unit) {
    setState(() {
      _fromUnit = unit;
      if (_lastEdited == 1) {
        final parsed = double.tryParse(_val1);
        if (parsed != null) {
          _val2 = _formatValue(
            UnitConverterData.convert(parsed, unit, _toUnit, _category),
          );
        }
      } else {
        final parsed = double.tryParse(_val2);
        if (parsed != null) {
          _val1 = _formatValue(
            UnitConverterData.convert(parsed, _toUnit, unit, _category),
          );
        }
      }
    });
    _persist();
  }

  void _changeToUnit(String unit) {
    setState(() {
      _toUnit = unit;
      if (_lastEdited == 1) {
        final parsed = double.tryParse(_val1);
        if (parsed != null) {
          _val2 = _formatValue(
            UnitConverterData.convert(parsed, _fromUnit, unit, _category),
          );
        }
      } else {
        final parsed = double.tryParse(_val2);
        if (parsed != null) {
          _val1 = _formatValue(
            UnitConverterData.convert(parsed, unit, _fromUnit, _category),
          );
        }
      }
    });
    _persist();
  }

  Future<void> _clear() async {
    await LocalStorage.removeAll([
      _catKey,
      _fromKey,
      _toKey,
      _v1Key,
      _v2Key,
      _lastEditKey,
    ]);
    setState(() {
      _category = UnitCategory.length;
      _fromUnit = 'Meter';
      _toUnit = 'Foot';
      _val1 = '100';
      _val2 = '328.08399';
      _lastEdited = 1;
    });
  }

  Future<void> _export() async {
    await DataExporter.exportJson(
      {
        'tool': AppStrings.unitConverter,
        'category': _category.name,
        'fromUnit': _fromUnit,
        'toUnit': _toUnit,
        'value1': _val1,
        'value2': _val2,
      },
      'unit_converter_data.json',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const TopAlignedLoading();
    }

    final units = UnitConverterData.units[_category]!;

    return TopAlignedBody(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTopBar(
            title: AppStrings.unitConverter,
            onBack: widget.onBack,
            showMenu: true,
            onClear: _clear,
            onExport: _export,
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: UnitCategory.values.map((category) {
                final selected = _category == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 16),
                  child: FilterChip(
                    label: Text(UnitConverterData.categoryLabel(category)),
                    selected: selected,
                    onSelected: (_) => _changeCategory(category),
                    selectedColor: AppColors.gray900,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.gray600,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.gray200),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _UnitField(
                  label: AppStrings.from,
                  value: _val1,
                  unit: _fromUnit,
                  units: units,
                  onValueChanged: _updateFrom,
                  onUnitChanged: _changeFromUnit,
                ),
                const SizedBox(height: 24),
                _UnitField(
                  label: AppStrings.to,
                  value: _val2,
                  unit: _toUnit,
                  units: units,
                  onValueChanged: _updateTo,
                  onUnitChanged: _changeToUnit,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(32),
            child: Text(
              '${_val1.isEmpty ? '0' : _val1} $_fromUnit = ${_val2.isEmpty ? '0' : _val2} $_toUnit',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitField extends StatelessWidget {
  const _UnitField({
    required this.label,
    required this.value,
    required this.unit,
    required this.units,
    required this.onValueChanged,
    required this.onUnitChanged,
  });

  final String label;
  final String value;
  final String unit;
  final List<String> units;
  final ValueChanged<String> onValueChanged;
  final ValueChanged<String> onUnitChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppInput(
          label: label,
          value: value,
          onChanged: onValueChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: unit,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: units
              .map(
                (u) => DropdownMenuItem(value: u, child: Text(u)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onUnitChanged(value);
          },
        ),
      ],
    );
  }
}
