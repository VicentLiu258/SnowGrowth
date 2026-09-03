import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snow_growth/core/constants/app_colors.dart';

class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.prefix,
    this.keyboardType = TextInputType.text,
  });

  final String? label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? prefix;
  final TextInputType keyboardType;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant AppInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(
        offset: widget.value.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          keyboardType: widget.keyboardType,
          inputFormatters:
              widget.keyboardType == TextInputType.number ||
                      widget.keyboardType ==
                          const TextInputType.numberWithOptions(decimal: true)
                  ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
                  : null,
          decoration: InputDecoration(
            prefixText: widget.prefix,
            prefixStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.gray500,
            ),
          ),
        ),
      ],
    );
  }
}
