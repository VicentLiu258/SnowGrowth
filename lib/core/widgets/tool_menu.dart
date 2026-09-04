import 'package:flutter/material.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/widgets/app_button.dart';

class ToolMenu extends StatelessWidget {
  const ToolMenu({super.key, required this.onClear, this.onExport});

  final VoidCallback onClear;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'clear') onClear();
        if (value == 'export' && onExport != null) onExport!();
      },
      itemBuilder:
          (context) => [
            PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.clearData,
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
    );
  }
}

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.onClear,
    this.onExport,
    this.showMenu = false,
  });

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onClear;
  final VoidCallback? onExport;
  final bool showMenu;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading:
          onBack != null
              ? AppButton(
                variant: AppButtonVariant.ghost,
                label: '',
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              )
              : null,
      title: Text(title),
      actions: [
        if (showMenu && onClear != null)
          ToolMenu(onClear: onClear!, onExport: onExport),
      ],
    );
  }
}
