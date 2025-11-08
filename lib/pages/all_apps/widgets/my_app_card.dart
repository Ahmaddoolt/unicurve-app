// lib/pages/all_apps/widgets/my_app_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:unicurve/core/utils/colors.dart';
import 'package:unicurve/core/utils/glass_card.dart';
import 'package:unicurve/core/utils/scale_config.dart';
import 'package:unicurve/domain/models/app_hub_model.dart';
import 'package:url_launcher/url_launcher.dart';

class MyAppCard extends StatelessWidget {
  final AppHubModel app;
  const MyAppCard({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaleConfig = context.scaleConfig;

    final hasPlayStoreUrl = app.playStoreUrl != null && app.playStoreUrl!.isNotEmpty;
    final hasAppStoreUrl = app.appStoreUrl != null && app.appStoreUrl!.isNotEmpty;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- NEW: Tappable area for details dialog ---
          Expanded(
            child: InkWell(
              onTap: () => _showAppDetailsDialog(context, app),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                bottomLeft: Radius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  children: [
                    // Left side: App Logo
                    _buildLogo(context, theme, scaleConfig),
                    const SizedBox(width: 16),
                    // Center: App Info (Name, Type, Rating)
                    _buildInfo(theme, scaleConfig),
                  ],
                ),
              ),
            ),
          ),
          // --- NEW: Visual separator and dedicated area for store icons ---
          if (hasPlayStoreUrl || hasAppStoreUrl) ...[
            SizedBox(
              height: scaleConfig.scale(50),
              child: VerticalDivider(
                color: theme.dividerColor,
                width: 1,
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasPlayStoreUrl)
                    _StoreIcon(
                      icon: FontAwesomeIcons.googlePlay,
                      color: const Color(0xFF99C579),
                      url: app.playStoreUrl!,
                      tooltip: 'View on Google Play',
                    ),
                  if (hasAppStoreUrl)
                    _StoreIcon(
                      icon: FontAwesomeIcons.appStoreIos,
                      color: const Color(0xFF5FC9F8),
                      url: app.appStoreUrl!,
                      tooltip: 'View on App Store',
                    ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  // Helper widget for the App Logo
  Widget _buildLogo(BuildContext context, ThemeData theme, ScaleConfig scaleConfig) {
    final String? logoUrl = app.logoPath;

    return Container(
      width: scaleConfig.scale(60),
      height: scaleConfig.scale(60),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: (logoUrl != null && logoUrl.isNotEmpty)
          ? Image.network(
              logoUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              },
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.broken_image_outlined, color: theme.colorScheme.error);
              },
            )
          : Icon(Icons.apps_outage_rounded, color: theme.colorScheme.onSurface.withOpacity(0.5), size: 30),
    );
  }

  // Helper widget for the App Info text
  Widget _buildInfo(ThemeData theme, ScaleConfig scaleConfig) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            app.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: scaleConfig.scaleText(15),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            app.type ?? 'Uncategorized',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontSize: scaleConfig.scaleText(12),
            ),
          ),
          if (app.rating != null && app.rating! > 0) ...[
            const SizedBox(height: 6),
            RatingBarIndicator(
              rating: app.rating!,
              itemBuilder: (context, index) => const Icon(Icons.star_rounded, color: Color(0xFFFFC107)),
              itemCount: 5,
              itemSize: scaleConfig.scale(18.0),
            ),
          ],
        ],
      ),
    );
  }

  // The elegant details dialog (no changes from previous version)
  void _showAppDetailsDialog(BuildContext context, AppHubModel app) {
    final theme = Theme.of(context);
    final scaleConfig = context.scaleConfig;
    final String? logoUrl = app.logoPath;
    final hasPlayStoreUrl = app.playStoreUrl != null && app.playStoreUrl!.isNotEmpty;
    final hasAppStoreUrl = app.appStoreUrl != null && app.appStoreUrl!.isNotEmpty;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.all(scaleConfig.scale(24)),
          child: GlassCard(
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: EdgeInsets.all(scaleConfig.scale(24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: scaleConfig.scale(80),
                    height: scaleConfig.scale(80),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (logoUrl != null && logoUrl.isNotEmpty)
                        ? Image.network(logoUrl, fit: BoxFit.cover)
                        : Icon(Icons.apps_outage_rounded, color: theme.colorScheme.onSurface.withOpacity(0.5), size: 40),
                  ),
                  SizedBox(height: scaleConfig.scale(16)),
                  Text(
                    app.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: scaleConfig.scale(4)),
                  if (app.type != null)
                    Text(
                      app.type!,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    ),
                  SizedBox(height: scaleConfig.scale(16)),
                  if (app.description != null && app.description!.isNotEmpty)
                    Text(
                      app.description!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  SizedBox(height: scaleConfig.scale(24)),
                  if (hasPlayStoreUrl || hasAppStoreUrl)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasPlayStoreUrl)
                          _StoreIcon(
                            icon: FontAwesomeIcons.googlePlay,
                            color: const Color(0xFF99C579),
                            url: app.playStoreUrl!,
                            tooltip: 'View on Google Play',
                          ),
                        if (hasAppStoreUrl)
                          _StoreIcon(
                            icon: FontAwesomeIcons.appStoreIos,
                            color: const Color(0xFF5FC9F8),
                            url: app.appStoreUrl!,
                            tooltip: 'View on App Store',
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Helper widget for the store icons (no changes needed)
class _StoreIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String url;
  final String tooltip;

  const _StoreIcon({
    required this.icon,
    required this.color,
    required this.url,
    required this.tooltip,
  });

  Future<void> _launchUrl() async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: FaIcon(icon, color: color, size: 24),
        onPressed: _launchUrl,
        splashRadius: 24,
      ),
    );
  }
}