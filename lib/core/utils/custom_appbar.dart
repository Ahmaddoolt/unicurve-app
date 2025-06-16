import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool centerTitle;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.centerTitle = false,
    this.leading,
    this.actions,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title:
          titleWidget ??
          (title != null
              ? Text(title!, style: TextStyle(color: AppColors.darkTextPrimary))
              : null),
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
      backgroundColor: backgroundColor ?? AppColors.darkBackground,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
