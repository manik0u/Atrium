import 'package:core_models/core_models.dart';
import 'package:core_router/core_router.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../sonarr_providers.dart';
import 'settings/connect_settings_screen.dart';
import 'settings/download_clients_screen.dart';
import 'settings/general_settings_screen.dart';
import 'settings/indexers_settings_screen.dart';
import 'settings/media_management_settings_screen.dart';
import 'settings/metadata_settings_screen.dart';
import 'settings/parse_title_dialog.dart';
import 'settings/profiles_settings_screen.dart';
import 'settings/quality_definitions_screen.dart';
import 'settings/tags_settings_screen.dart';
import 'settings/ui_settings_screen.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({
    required this.instance,
    super.key,
  });

  final Instance instance;

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Instance instance = widget.instance;
    ref.listen<int>(sonarrHomeScrollToTopProvider((widget.instance, 3)),
        (previous, next) {
      if (next > 0 && _scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Text(S.t('sonarrSettings')),
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(Insets.md),
        children: [
          _buildCategoryHeader(context, S.t('mediaHandling')),
          _buildSettingsCard(
            context: context,
            title: S.t('mediaManagement'),
            subtitle:
                S.t('renameEpisodesConfigureEmptyFoldersCopyLinksPermissionDetails'),
            icon: Icons.folder_open_outlined,
            screen: MediaManagementSettingsScreen(instance: instance),
          ),
          _buildSettingsCard(
            context: context,
            title: S.t('profiles'),
            subtitle:
                S.t('manageQualityProfilesDelayProfilesReleaseProfilesAndCustomFormats'),
            icon: Icons.high_quality_outlined,
            screen: ProfilesSettingsScreen(instance: instance),
          ),
          _buildSettingsCard(
            context: context,
            title: S.t('qualityDefinitions'),
            subtitle:
                S.t('configureMinimumMaximumAndPreferredSizeLimitsPerQualityType'),
            icon: Icons.aspect_ratio_outlined,
            screen: QualityDefinitionsScreen(instance: instance),
          ),
          const SizedBox(height: Insets.md),
          _buildCategoryHeader(context, S.t('networkIntegration')),
          _buildSettingsCard(
            context: context,
            title: S.t('indexersTrackers'),
            subtitle:
                'RSS feeds, automatic search, indexers list, and import lists configurations.',
            icon: Icons.rss_feed_outlined,
            screen: IndexersSettingsScreen(instance: instance),
          ),
          _buildSettingsCard(
            context: context,
            title: S.t('downloadClients'),
            subtitle:
                S.t('clientsListConnectionsDownloadTrackingAndPathOverrideMappings'),
            icon: Icons.download_for_offline_outlined,
            screen: DownloadClientsScreen(instance: instance),
          ),
          _buildSettingsCard(
            context: context,
            title: S.t('connect'),
            subtitle:
                'Discord, Telegram, Email, Plex notifications and trigger events.',
            icon: Icons.connect_without_contact,
            screen: ConnectSettingsScreen(instance: instance),
          ),
          _buildSettingsCard(
            context: context,
            title: S.t('metadataConsumers'),
            subtitle:
                'Configure metadata files creation for Kodi, Plex, Emby, and WDTV.',
            icon: Icons.settings_applications_outlined,
            screen: MetadataSettingsScreen(instance: instance),
          ),
          const SizedBox(height: Insets.md),
          _buildCategoryHeader(context, S.t('applicationSystem')),
          _buildSettingsCard(
            context: context,
            title: S.t('general'),
            subtitle:
                'Set server listening port, SSL certifications, API Keys, and logs.',
            icon: Icons.dns_outlined,
            screen: GeneralSettingsScreen(instance: instance),
          ),
          _buildSettingsCard(
            context: context,
            title: S.t('uiSettings'),
            subtitle:
                S.t('dateFormattingFirstDayOfWeekSelectionAndColorOptions'),
            icon: Icons.palette_outlined,
            screen: UiSettingsScreen(instance: instance),
          ),
          _buildSettingsCard(
            context: context,
            title: S.t('tags'),
            subtitle:
                S.t('manageLabelIdentifiersForCategoriesSeriesAndProfiles'),
            icon: Icons.label_outline,
            screen: TagsSettingsScreen(instance: instance),
          ),
          _buildSettingsCard(
            context: context,
            title: S.t('connectionSettings'),
            subtitle:
                S.t('editConnectionURLAPIKeyAndLabelForThisSonarrInstanceInAtrium'),
            icon: Icons.key_outlined,
            onTap: () {
              context.pushNamed(
                AtriumRoutes.editInstanceName,
                pathParameters: <String, String>{
                  'instanceId': instance.id,
                },
              );
            },
          ),
          const SizedBox(height: Insets.md),
          _buildCategoryHeader(context, S.t('diagnosticsTroubleshooting')),
          _buildSettingsCard(
            context: context,
            title: S.t('parseTitle'),
            subtitle:
                S.t('extractMetadataAndCheckMatchingSeriesDatabaseResultsForAnyReleaseName'),
            icon: Icons.troubleshoot_outlined,
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (context) =>
                    SonarrParseTitleDialog(instance: instance),
              ).ignore();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: Insets.xs, bottom: Insets.sm),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? screen,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: Insets.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        borderRadius: Radii.card,
      ),
      child: InkWell(
        borderRadius: Radii.card,
        onTap: onTap ??
            () {
              if (screen != null) {
                pushScreen<void>(context, screen);
              }
            },
        child: Padding(
          padding: const EdgeInsets.all(Insets.md),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  icon,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Insets.sm),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
