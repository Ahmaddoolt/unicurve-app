// lib/core/utils/custom_appbar.dart

import 'package:flutter/material.dart';
import 'package:unicurve/core/utils/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool centerTitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool useGradient;
  final Gradient? gradient;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.centerTitle = true,
    this.leading,
    this.actions,
    this.useGradient = true,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine the default gradient based on the theme if no specific gradient is provided
    final defaultGradient = theme.brightness == Brightness.light
        ? AppColors.primaryGradient // Use vibrant gradient for light mode
        : AppColors.darkPrimaryGradient; // Use dark gradient for dark mode

    final effectiveGradient =
        useGradient ? (gradient ?? defaultGradient) : null;
    final hasGradient = effectiveGradient != null;

    // Text and icon colors are always white on any gradient for max contrast.
    final effectiveTitleTextStyle = theme.appBarTheme.titleTextStyle?.copyWith(
        color: hasGradient ? Colors.white : theme.textTheme.bodyLarge?.color);

    final effectiveIconTheme = theme.appBarTheme.iconTheme?.copyWith(
        color: hasGradient ? Colors.white : theme.textTheme.bodyLarge?.color);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
      iconTheme: effectiveIconTheme,
      titleTextStyle: effectiveTitleTextStyle,
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: effectiveTitleTextStyle,
                )
              : null),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: effectiveGradient,
          color: hasGradient ? null : theme.scaffoldBackgroundColor,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
